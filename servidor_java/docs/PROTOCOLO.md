# Protocolo de Comunicação TCP - Backend PetCare (Java)

Este documento especifica o protocolo oficial de comunicação via Socket TCP entre clientes (como o Backend em Node.js/TypeScript) e o Servidor PetCare em Java puro.

O servidor Java é um serviço isolado de cálculo sem estado (*stateless*). Ele **não acessa banco de dados** (a classe `MongoConexao` é uma estrutura preparatória/placeholder que retorna `null`).

---

## 1. Visão Geral e Restrições de Conexão

- **Transporte:** Socket TCP nativo (`ServerSocket` / `Socket`).
- **Porta padrão:** `5000`.
- **Codificação de caracteres:** `UTF-8`.
- **Delimitador de mensagem:** Quebra de linha (`\n` ou `\r\n`). Cada mensagem trafega em uma **única linha**.
- **Ciclo de vida da conexão:** Uma requisição por conexão (estilo *request-response*). O cliente conecta, envia uma linha contendo a requisição JSON terminada em `\n`, o servidor processa, envia uma linha com a resposta JSON terminada em `\n` e encerra a conexão de socket imediatamente no bloco `finally`.
- **Timeout de leitura (`SO_TIMEOUT`):** `5000 ms` (5 segundos). Se o cliente conectar e não concluir o envio da linha dentro desse período, a conexão é encerrada com erro `JSON_INVALIDO`.
- **Tamanho máximo de requisição:** `64 KB` (65.536 caracteres / bytes). Linhas que excederem esse limite disparam `LinhaMuitoGrandeException`, sendo rejeitadas com erro `JSON_INVALIDO` e a conexão é encerrada.
- **Segurança e Logs:** Por trafegar senhas em texto puro no JSON pelo socket local da máquina nas operações de cálculo e verificação de hash, o log do `ClienteHandler` propositalmente não imprime a linha recebida (`linhaRecebida`). O log registra apenas o endereço do cliente e a resposta enviada:
  ```
  [ClienteHandler] Requisição recebida de <enderecoCliente>
  [ClienteHandler] Resposta enviada para <enderecoCliente>: <linhaResposta>
  [ClienteHandler] Conexão com <enderecoCliente> encerrada.
  ```

---

## 2. Formato das Mensagens

### 2.1 Requisição

O cliente deve enviar um objeto JSON em linha única contendo obrigatoriamente:
- `comando` (string, não-vazia): Nome da operação a ser executada. O servidor normaliza o comando aplicando `trim()` e comparando em letras maiúsculas (`toUpperCase()`).
- `dados` (objeto JSON): Objeto (`{...}`) contendo os parâmetros específicos da operação. Não pode ser nulo nem outro tipo JSON (array, número, string ou booleano).

```json
{"comando":"NOME_DO_COMANDO","dados":{"campo1":"valor1","campo2":123}}
```

### 2.2 Resposta

O servidor responde com um objeto JSON em linha única contendo obrigatoriamente:
- `status` (string): `"OK"` para sucesso ou `"ERRO"` para falha.
- `mensagem` (string): Descrição legível do resultado ou da causa do erro.
- `codigo` (string, presente apenas quando `status == "ERRO"`): Código padronizado do erro conforme o enum `CodigoErro`.
- `dados` (objeto JSON, presente nas respostas de sucesso dos serviços de cálculo): Objeto contendo os campos calculados pelo serviço solicitado.

**Exemplo de Resposta de Sucesso:**
```json
{"status":"OK","mensagem":"Operação realizada com sucesso.","dados":{"resultado":"valor"}}
```

**Exemplo de Resposta de Erro:**
```json
{"status":"ERRO","codigo":"CODIGO_PADRONIZADO","mensagem":"Descrição detalhada do motivo do erro."}
```

---

## 3. Tabela de Códigos de Erro Padronizados

Em qualquer resposta onde `"status": "ERRO"`, o campo `"codigo"` conterá exatamente um dos 6 valores do enum `CodigoErro`:

| Código | Descrição / Quando ocorre | Equivalente HTTP Típico |
|---|---|---|
| `JSON_INVALIDO` | Linha vazia ou nula; sintaxe JSON malformatada (`JsonSyntaxException`); raiz da mensagem não é um objeto JSON; linha que excede 64 KB (`LinhaMuitoGrandeException`); ou tempo limite de leitura (timeout de 5000 ms via `SocketTimeoutException`) esgotado. | `400 Bad Request` / `408 Request Timeout` / `413 Payload Too Large` |
| `COMANDO_AUSENTE` | Requisição em JSON válido, porém sem a propriedade `comando`, com valor nulo, com tipo não-string (ex.: número/booleano) ou contendo apenas espaços em branco após `trim()`. | `400 Bad Request` |
| `COMANDO_DESCONHECIDO` | O comando informado não está registrado no roteador do servidor (nem como implementado, nem como previsto), incluindo comandos removidos. | `404 Not Found` |
| `COMANDO_NAO_IMPLEMENTADO` | Código reservado para comandos previstos na arquitetura e registrados no roteador, mas cujo serviço isolado de cálculo ainda não foi implementado (atualmente todos os comandos registrados estão implementados). | `501 Not Implemented` |
| `DADOS_INVALIDOS` | Propriedade `dados` ausente na requisição, com valor nulo ou cujo tipo não seja um objeto JSON (`{...}`); ou validação interna de negócio/parâmetros falhou dentro do serviço invocado (ex.: tipos incorretos, valores fora dos limites, datas inválidas ou campos obrigatórios ausentes dentro de `dados`). | `422 Unprocessable Entity` |
| `ERRO_INTERNO` | Exceção inesperada capturada no servidor durante o processamento (`Exception` geral). O stack trace é registrado no `stderr` do servidor e nunca vazado ao cliente. | `500 Internal Server Error` |

---

## 4. Tabela de Comandos

### 4.1 Comandos Implementados (Ativos)

| Comando | Entrada (`dados`) | Saída (`dados`) | Descrição e Finalidade |
|---|---|---|---|
| `CALCULAR_STATUS_VACINA` | `dataUltimaAplicacao` (string, opcional, `yyyy-MM-dd`), `intervaloDias` (int, obrigatório se houver aplicação, 1 a 3650), `diasAlerta` (int, opcional, padrão 30, 0 a 3650), `dataReferencia` (string, opcional, `yyyy-MM-dd`, padrão hoje em America/Sao_Paulo). | `statusVacina` (string: `"EM_DIA"`, `"A_VENCER"`, `"ATRASADA"`, `"PENDENTE"`), `dataProximaDose` (string `yyyy-MM-dd`, ausente se `PENDENTE`), `diasRestantes` (long, ausente se `PENDENTE`). | Calcula a próxima data de aplicação e o status de imunização do pet com base na última dose e frequência em dias. |
| `GERAR_HASH_SENHA` | `senha` (string, obrigatória, não-vazia). | `hash` (string: formato `pbkdf2$120000$<saltBase64>$<hashBase64>`). | Gera hash criptográfico seguro PBKDF2WithHmacSHA256 com 120.000 iterações e salt aleatório de 16 bytes. |
| `VERIFICAR_SENHA` | `senha` (string, obrigatória), `hash` (string, obrigatória, formato PBKDF2). | `valida` (boolean: `true` se corresponder, `false` caso contrário). | Valida a senha contra o hash armazenado comparando em tempo constante (`MessageDigest.isEqual`). |
| `CALCULAR_PROGRESSO_CAMPANHA` | `valorArrecadado` (número, obrigatório, `>= 0` e `<= 10^12`), `metaValor` (número, obrigatório, `> 0` e `<= 10^12`). | `porcentagem` (BigDecimal, 1 casa decimal), `porcentagemExibicao` (BigDecimal, 1 casa decimal, máx 100.0), `valorRestante` (BigDecimal, 2 casas decimais, mín 0.00), `statusProgresso` (string: `"SEM_DOACOES"`, `"EM_ANDAMENTO"`, `"QUASE_LA"`, `"META_ATINGIDA"`). | Calcula percentual alcançado, valor restante para a meta e categoria de status de arrecadação de campanha beneficente. |

### 4.2 Comandos Removidos (Respondem `COMANDO_DESCONHECIDO`)

Estes comandos não existem no roteador do `ClienteHandler.java` e, se enviados, retornam o código de erro `COMANDO_DESCONHECIDO`:

| Comando | Status | Motivo da Remoção do Servidor Java |
|---|---|---|
| `CADASTRAR` | Removido | Cadastro e persistência de usuários ficam no Back (Node.js/TypeScript). |
| `LOGIN` | Removido | Autenticação e controle de sessão ficam no Back (Node.js/TypeScript). |
| `VERIFICAR_CONFLITO_HORARIO` | Removido | Conflito de horário é tratado no agendamento do Back por reservasAgenda. |
| `VALIDAR_DOCUMENTO` | Removido | Validação de CPF e CNPJ não será mais implementada no servidor Java (delegada ao Back/Front). |

---

## 5. Detalhamento e Exemplos dos Comandos Implementados

### 5.1 `CALCULAR_STATUS_VACINA`

- **Entrada (`dados`):**
  - `dataUltimaAplicacao` (string, opcional): Data da última dose no formato `yyyy-MM-dd`. Se ausente, nula ou vazia, o status retornado é `"PENDENTE"`. Não pode ser data futura em relação à `dataReferencia`.
  - `intervaloDias` (int, obrigatório se houver aplicação): Intervalo em dias até a próxima dose, entre `1` e `3650` (10 anos).
  - `diasAlerta` (int, opcional): Quantidade de dias antes do vencimento para alertar (`0` a `3650`, padrão `30`).
  - `dataReferencia` (string, opcional): Data base para cálculo no formato `yyyy-MM-dd` (padrão: data atual no fuso `America/Sao_Paulo`).
- **Regras:**
  - `proximaDose = dataUltimaAplicacao + intervaloDias`
  - `diasRestantes = proximaDose - dataReferencia`
  - Sem aplicação registrada -> `"PENDENTE"` (omite `dataProximaDose` e `diasRestantes`)
  - `diasRestantes < 0` -> `"ATRASADA"`
  - `0 <= diasRestantes <= diasAlerta` -> `"A_VENCER"` (inclui vencimento no próprio dia)
  - `diasRestantes > diasAlerta` -> `"EM_DIA"`
- **Possíveis Erros:** `DADOS_INVALIDOS` (campo `dados` ausente, datas inválidas, data futura, `intervaloDias` ausente ou fora dos limites, tipos incorretos).
- **Exemplo de Requisição:**
  ```json
  {"comando":"CALCULAR_STATUS_VACINA","dados":{"dataUltimaAplicacao":"2026-01-10","intervaloDias":365,"diasAlerta":30,"dataReferencia":"2026-10-09"}}
  ```
- **Exemplo de Resposta de Sucesso:**
  ```json
  {"status":"OK","mensagem":"Status da vacina calculado.","dados":{"statusVacina":"EM_DIA","dataProximaDose":"2027-01-10","diasRestantes":93}}
  ```

---

### 5.2 `GERAR_HASH_SENHA`

- **Entrada (`dados`):**
  - `senha` (string, obrigatória): Senha a ser criptografada. Não pode ser nula, vazia ou de outro tipo.
- **Regras:**
  - Derivação de chave via PBKDF2WithHmacSHA256 com 120.000 iterações.
  - Salt criptográfico de 16 bytes gerado via `SecureRandom`.
  - Hash de 32 bytes (256 bits).
  - Formato de saída: `pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>`.
- **Possíveis Erros:** `DADOS_INVALIDOS` (campo `senha` ausente, nulo, não-string ou vazio).
- **Exemplo de Requisição:**
  ```json
  {"comando":"GERAR_HASH_SENHA","dados":{"senha":"senha-falsa-de-teste"}}
  ```
- **Exemplo de Resposta de Sucesso:**
  ```json
  {"status":"OK","mensagem":"Hash gerado com sucesso.","dados":{"hash":"pbkdf2$120000$..."}}
  ```

---

### 5.3 `VERIFICAR_SENHA`

- **Entrada (`dados`):**
  - `senha` (string, obrigatória): Senha em texto plano a validar.
  - `hash` (string, obrigatória): Hash no formato `pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>`.
- **Regras:**
  - Extrai iterações, salt e hash esperado a partir da string de hash.
  - Recalcula o PBKDF2 com os parâmetros do hash fornecido e compara em tempo constante via `MessageDigest.isEqual`.
- **Possíveis Erros:** `DADOS_INVALIDOS` (campos `senha` ou `hash` ausentes, nulos, não-string ou hash com formato/estrutura inválida).
- **Exemplo de Requisição:**
  ```json
  {"comando":"VERIFICAR_SENHA","dados":{"senha":"senha-falsa-de-teste","hash":"pbkdf2$120000$..."}}
  ```
- **Exemplo de Resposta de Sucesso:**
  ```json
  {"status":"OK","mensagem":"Verificação de senha concluída.","dados":{"valida":true}}
  ```

---

### 5.4 `CALCULAR_PROGRESSO_CAMPANHA`

- **Entrada (`dados`):**
  - `valorArrecadado` (número, obrigatório): Valor total arrecadado (`>= 0` e `<= 1000000000000`).
  - `metaValor` (número, obrigatório): Meta financeira (`> 0` e `<= 1000000000000`).
- **Regras:**
  - `porcentagem`: `valorArrecadado * 100 / metaValor` (1 casa decimal, arredondamento `DOWN`).
  - `porcentagemExibicao`: `min(porcentagem, 100.0)` (1 casa decimal).
  - `valorRestante`: `metaValor - valorArrecadado` (mínimo `0.00`, 2 casas decimais, arredondamento `UP`).
  - `statusProgresso`:
    - `SEM_DOACOES`: quando `valorArrecadado == 0`.
    - `META_ATINGIDA`: quando `valorArrecadado >= metaValor`.
    - `QUASE_LA`: quando `valorArrecadado * 100 >= metaValor * 80` (80% ou mais da meta).
    - `EM_ANDAMENTO`: outros casos.
- **Possíveis Erros:** `DADOS_INVALIDOS` (campos ausentes, nulos, tipos não numéricos, valores negativos, `metaValor <= 0` ou valores acima de 1 trilhão).
- **Exemplo de Requisição:**
  ```json
  {"comando":"CALCULAR_PROGRESSO_CAMPANHA","dados":{"valorArrecadado":850.50,"metaValor":1000.00}}
  ```
- **Exemplo de Resposta de Sucesso:**
  ```json
  {"status":"OK","mensagem":"Progresso da campanha calculado com sucesso.","dados":{"porcentagem":85.0,"porcentagemExibicao":85.0,"valorRestante":149.50,"statusProgresso":"QUASE_LA"}}
  ```

---

## 6. Exemplos de Erros Padronizados

### 6.1 Exemplo de `COMANDO_DESCONHECIDO` (comando removido ou inexistente)

**Requisição (comando retirado do servidor Java):**
```json
{"comando":"VALIDAR_DOCUMENTO","dados":{"documento":"12345678909"}}
```

**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"COMANDO_DESCONHECIDO","mensagem":"Comando desconhecido: VALIDAR_DOCUMENTO"}
```

---

### 6.2 Exemplo de `COMANDO_NAO_IMPLEMENTADO` (reservado para comandos previstos)

Caso um novo comando seja cadastrado no roteador como previsto antes da criação de seu respectivo serviço de cálculo, o servidor responderá:
```json
{"status":"ERRO","codigo":"COMANDO_NAO_IMPLEMENTADO","mensagem":"Comando previsto, mas ainda não implementado: NOME_DO_COMANDO"}
```

---

### 6.3 Exemplo de `JSON_INVALIDO`

**Requisição com sintaxe JSON malformatada (chaves não fechadas):**
```json
{"comando":"CALCULAR_PROGRESSO_CAMPANHA","dados":{"valorArrecadado":100
```

**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"JSON_INVALIDO","mensagem":"JSON malformatado: java.io.EOFException: End of input at line 1 column 72 path $.dados.valorArrecadado"}
```

---

### 6.4 Exemplo de `DADOS_INVALIDOS`

**Requisição com parâmetros de negócio inválidos (ex.: valor negativo):**
```json
{"comando":"CALCULAR_PROGRESSO_CAMPANHA","dados":{"valorArrecadado":-50,"metaValor":1000}}
```

**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"DADOS_INVALIDOS","mensagem":"Campo 'valorArrecadado' deve ser maior ou igual a 0."}
```
