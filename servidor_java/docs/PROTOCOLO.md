# Protocolo de Comunicação TCP - Backend PetCare (Java)

Este documento especifica o protocolo oficial de comunicação via Socket TCP entre clientes (como o backend em Node.js/TypeScript) e o Servidor PetCare em Java puro.

---

## 1. Visão Geral e Restrições de Conexão

- **Transporte:** Socket TCP nativo (`ServerSocket` / `Socket`).
- **Porta padrão:** `5000`.
- **Codificação de caracteres:** `UTF-8`.
- **Delimitador de mensagem:** Quebra de linha (`\n`, ignorando `\r`). Cada mensagem trafega em uma **única linha**.
- **Ciclo de vida da conexão:** Uma requisição por conexão (estilo *request-response*). O cliente conecta, envia uma linha contendo a requisição JSON terminada em `\n`, o servidor processa, envia uma linha com a resposta JSON terminada em `\n` e fecha o socket imediatamente no bloco `finally`.
- **Timeout de leitura (`SO_TIMEOUT`):** `5000 ms` (5 segundos). Se o cliente não concluir o envio da linha dentro desse período, a conexão é encerrada e o servidor responde com erro `JSON_INVALIDO`.
- **Tamanho máximo de requisição:** `64 KB` (65.536 caracteres). Linhas que excederem esse limite disparam a exceção `LinhaMuitoGrandeException`, retornando erro `JSON_INVALIDO`.
- **Segurança e Logs:** Como as credenciais trafegam em texto puro no JSON pelo socket local, o log do `ClienteHandler` registra apenas o endereço do cliente e não imprime a linha recebida em `System.out`.
- **Ausência de Acesso a Banco:** O servidor Java não acessa banco de dados nem arquivos externos; a classe `MongoConexao` é uma estrutura preparatória/placeholder que retorna `null`.

---

## 2. Formato das Mensagens

### 2.1 Requisição

O cliente deve enviar um objeto JSON em linha única contendo:
- `comando` (string, obrigatório): Nome da operação. O servidor normaliza o comando aplicando `trim()` e convertendo para maiúsculas (`toUpperCase()`). Se ausente, nulo, vazio ou de tipo não-string, retorna `COMANDO_AUSENTE`.
- `dados` (objeto JSON, obrigatório): Objeto contendo os parâmetros específicos da operação. Se ausente, nulo ou não for um objeto JSON (`{...}`), retorna `DADOS_INVALIDOS`.

```json
{"comando":"NOME_DO_COMANDO","dados":{"campo1":"valor1","campo2":123}}
```

### 2.2 Resposta

O servidor responde com um objeto JSON em linha única contendo:
- `status` (string): `"OK"` para sucesso ou `"ERRO"` para falha.
- `mensagem` (string): Descrição legível do resultado.
- `codigo` (string, presente apenas quando `status == "ERRO"`): Código padronizado do erro.
- `dados` (objeto JSON, presente em operações com retorno de valores): Contém os dados retornados pelo serviço.

**Exemplo de Resposta de Sucesso:**
```json
{"status":"OK","mensagem":"Operação realizada com sucesso.","dados":{"resultado":"exemplo"}}
```

**Exemplo de Resposta de Erro:**
```json
{"status":"ERRO","codigo":"CODIGO_PADRONIZADO","mensagem":"Descrição detalhada do erro."}
```

---

## 3. Códigos de Erro Padronizados

Em qualquer resposta de falha (`"status": "ERRO"`), o campo `"codigo"` conterá exatamente um dos valores do enum `CodigoErro`:

| Código | Quando Ocorre |
|---|---|
| `JSON_INVALIDO` | Linha nula, vazia ou apenas espaços; sintaxe JSON malformatada (`JsonSyntaxException`); raiz da mensagem não é um objeto JSON; linha que excede o limite de 64 KB; ou tempo limite de leitura (5000 ms) esgotado. |
| `COMANDO_AUSENTE` | Campo `comando` ausente na requisição, com valor nulo, com tipo diferente de string ou string vazia após `trim()`. |
| `COMANDO_DESCONHECIDO` | Comando informado não registrado no roteador do servidor (ou comando descontinuado/removido). |
| `COMANDO_NAO_IMPLEMENTADO` | Comando previsto na arquitetura, registrado no roteador, mas sem serviço implementado. |
| `DADOS_INVALIDOS` | Campo `dados` ausente, nulo ou que não seja um objeto JSON; ou parâmetros internos de `dados` ausentes, inválidos ou fora dos limites esperados pelo serviço. |
| `ERRO_INTERNO` | Exceção inesperada capturada no servidor durante o atendimento. O stack trace é registrado no `stderr` e ocultado da resposta ao cliente. |

---

## 4. Tabela de Comandos

### 4.1 Comandos Implementados

#### 1. `GERAR_HASH_SENHA`
Gera hash criptográfico da senha utilizando PBKDF2 com HMAC-SHA256 e salt aleatório de 16 bytes gerado via `SecureRandom` (120.000 iterações).
- **Entrada (`dados`):**
  - `senha` (string, obrigatório): Senha a ser criptografada (não pode ser nula nem vazia).
- **Saída (`dados`):**
  - `hash` (string): Hash no formato `pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>`.
- **Erros:** `DADOS_INVALIDOS` se `senha` for ausente, nula, não-string ou vazia.
- **Exemplo de Requisição:**
  ```json
  {"comando":"GERAR_HASH_SENHA","dados":{"senha":"senha-falsa-de-teste"}}
  ```
- **Exemplo de Resposta:**
  ```json
  {"status":"OK","mensagem":"Hash gerado com sucesso.","dados":{"hash":"pbkdf2$120000$..."}}
  ```

#### 2. `VERIFICAR_SENHA`
Verifica a validade de uma senha em texto puro contra um hash PBKDF2 previamente gerado, com comparação em tempo constante (`MessageDigest.isEqual`).
- **Entrada (`dados`):**
  - `senha` (string, obrigatório): Senha em texto puro a ser verificada.
  - `hash` (string, obrigatório): Hash PBKDF2 completo no formato `pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>`.
- **Saída (`dados`):**
  - `valida` (booleano): `true` se a senha corresponder ao hash, `false` caso contrário.
- **Erros:** `DADOS_INVALIDOS` se `senha` ou `hash` forem ausentes, nulos, não-string ou se o formato do hash for inválido.
- **Exemplo de Requisição:**
  ```json
  {"comando":"VERIFICAR_SENHA","dados":{"senha":"senha-falsa-de-teste","hash":"pbkdf2$120000$..."}}
  ```
- **Exemplo de Resposta:**
  ```json
  {"status":"OK","mensagem":"Verificação de senha concluída.","dados":{"valida":true}}
  ```

#### 3. `CALCULAR_PROGRESSO_CAMPANHA`
Calcula as métricas de arrecadação financeira de uma campanha beneficente utilizando `BigDecimal`.
- **Entrada (`dados`):**
  - `valorArrecadado` (número, obrigatório): Valor total arrecadado (>= 0 e <= 1.000.000.000.000).
  - `metaValor` (número, obrigatório): Meta financeira da campanha (> 0 e <= 1.000.000.000.000).
- **Saída (`dados`):**
  - `porcentagem` (número decimal): `(valorArrecadado * 100) / metaValor` com 1 casa decimal e arredondamento `DOWN`.
  - `porcentagemExibicao` (número decimal): Porcentagem limitada ao teto de `100.0`.
  - `valorRestante` (número decimal): `metaValor - valorArrecadado` (mínimo 0.00, 2 casas decimais e arredondamento `UP`).
  - `statusProgresso` (string): `SEM_DOACOES` (se arrecadado == 0), `META_ATINGIDA` (se arrecadado >= meta), `QUASE_LA` (se arrecadado >= 80% da meta) ou `EM_ANDAMENTO`.
- **Erros:** `DADOS_INVALIDOS` se campos forem ausentes, nulos, não-números, `valorArrecadado < 0`, `metaValor <= 0` ou valores acima de 10^12.
- **Exemplo de Requisição:**
  ```json
  {"comando":"CALCULAR_PROGRESSO_CAMPANHA","dados":{"valorArrecadado":850.50,"metaValor":1000.00}}
  ```
- **Exemplo de Resposta:**
  ```json
  {"status":"OK","mensagem":"Progresso da campanha calculado com sucesso.","dados":{"porcentagem":85.0,"porcentagemExibicao":85.0,"valorRestante":149.50,"statusProgresso":"QUASE_LA"}}
  ```

---

### 4.2 Comandos Previstos (Não Implementados)

| Comando | Status | Resposta do Servidor |
|---|---|---|
| `VALIDAR_DOCUMENTO` | Previsto | Responde `COMANDO_NAO_IMPLEMENTADO`: `"Comando previsto, mas ainda não implementado: VALIDAR_DOCUMENTO"` |

---

### 4.3 Comandos Removidos

Estes comandos não são mais atendidos pelo servidor Java e respondem com `COMANDO_DESCONHECIDO`:

| Comando | Motivo da Remoção |
|---|---|
| `CADASTRAR` | O fluxo de cadastro de usuários e persistência é gerenciado pelo backend Node.js no MongoDB Atlas. |
| `LOGIN` | A autenticação, verificação de credenciais e geração de JWT são gerenciadas pelo backend Node.js. |
| `VERIFICAR_CONFLITO_HORARIO` | O controle de concorrência e conflitos de agenda é tratado diretamente no agendamento do backend via `reservasAgenda`. |
| `CALCULAR_STATUS_VACINA` | As regras de vacinação e acompanhamento de doses foram definidas fora do escopo do servidor Java. |

---

## 5. Exemplos de Comunicação de Erro

### 5.1 Exemplo de `COMANDO_DESCONHECIDO`
**Requisição:**
```json
{"comando":"CADASTRAR","dados":{"email":"teste@petcare.com"}}
```
**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"COMANDO_DESCONHECIDO","mensagem":"Comando desconhecido: CADASTRAR"}
```

### 5.2 Exemplo de `JSON_INVALIDO`
**Requisição (JSON truncado/malformatado):**
```json
{"comando":"GERAR_HASH_SENHA","dados":{"senha":
```
**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"JSON_INVALIDO","mensagem":"JSON malformatado: java.io.EOFException: End of input at line 1 column 47 path $.dados.senha"}
```
