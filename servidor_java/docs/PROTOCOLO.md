# Protocolo de Comunicação TCP - Backend PetCare (Java)

Este documento especifica o protocolo oficial de comunicação via Socket TCP entre clientes (como o Backend em Node.js/TypeScript) e o Servidor PetCare em Java puro.

---

## 1. Visão Geral e Restrições de Conexão

- **Transporte:** Socket TCP nativo (`ServerSocket` / `Socket`).
- **Porta padrão:** `5000`.
- **Codificação de caracteres:** `UTF-8`.
- **Delimitador de mensagem:** Quebra de linha (`\n` ou `\r\n`). Cada mensagem trafega em uma **única linha**.
- **Ciclo de vida da conexão:** Uma requisição por conexão (estilo *request-response*). O cliente conecta, envia uma linha contendo a requisição JSON terminada em `\n`, o servidor processa, envia uma linha com a resposta JSON terminada em `\n` e encerra a conexão de socket imediatamente.
- **Timeout de leitura (`SO_TIMEOUT`):** `5000 ms` (5 segundos). Se o cliente conectar e não concluir o envio da linha dentro desse período, a conexão é encerrada com erro `JSON_INVALIDO`.
- **Tamanho máximo de requisição:** `64 KB` (65.536 caracteres). Linhas que excederem esse limite são rejeitadas com erro `JSON_INVALIDO` e a conexão é encerrada.

---

## 2. Formato das Mensagens

### 2.1 Requisição

O cliente deve enviar um objeto JSON em linha única contendo obrigatoriamente:
- `comando` (string, não-vazia): Nome da operação a ser executada. O servidor normaliza o comando aplicando `trim()` e comparando em letras maiúsculas (`toUpperCase()`).
- `dados` (objeto JSON): Objeto contendo os parâmetros específicos da operação.

```json
{"comando":"NOME_DO_COMANDO","dados":{"campo1":"valor1","campo2":123}}
```

### 2.2 Resposta

O servidor responde com um objeto JSON em linha única contendo obrigatoriamente:
- `status` (string): `"OK"` para sucesso ou `"ERRO"` para falha.
- `mensagem` (string): Descrição legível do resultado ou da causa do erro.
- `codigo` (string, presente apenas quando `status == "ERRO"`): Código padronizado do erro para tratamento programático pelo cliente.
- Campos adicionais específicos de cada comando (ex.: `"nome"` no login).

> **Atenção:** Os comandos legados `CADASTRAR` e `LOGIN` ainda podem devolver erros SEM o campo `"codigo"` (ex.: `{"status":"ERRO","mensagem":"E-mail não cadastrado."}`); isso será corrigido quando o CRUD de usuário for removido do Servidor.

**Exemplo de Resposta de Sucesso:**
```json
{"status":"OK","mensagem":"Operação realizada com sucesso."}
```

**Exemplo de Resposta de Erro:**
```json
{"status":"ERRO","codigo":"CODIGO_PADRONIZADO","mensagem":"Descrição detalhada do motivo do erro."}
```

---

## 3. Tabela de Códigos de Erro Padronizados

Em qualquer resposta onde `"status": "ERRO"`, o campo `"codigo"` conterá exatamente um dos seguintes valores:

| Código | Descrição / Causa | Equivalente HTTP Típico |
|---|---|---|
| `JSON_INVALIDO` | Linha vazia ou nula; sintaxe JSON malformatada (`JsonSyntaxException`); raiz da mensagem não é um objeto JSON; linha que excede 64 KB; ou tempo limite de leitura (timeout de 5000 ms) esgotado. | `400 Bad Request` / `408 Request Timeout` / `413 Payload Too Large` |
| `COMANDO_AUSENTE` | Requisição em JSON válido, porém sem a propriedade `comando`, com valor nulo, com tipo não-string (ex.: número/booleano) ou contendo apenas espaços em branco. | `400 Bad Request` |
| `COMANDO_DESCONHECIDO` | O comando informado não está registrado no roteador do servidor (nem como implementado, nem como previsto). | `404 Not Found` |
| `COMANDO_NAO_IMPLEMENTADO` | Comando previsto na arquitetura do PetCare, registrado no roteador, mas cujo serviço isolado de cálculo ainda não foi implementado. | `501 Not Implemented` |
| `DADOS_INVALIDOS` | Propriedade `dados` ausente na requisição, com valor nulo ou cujo tipo não seja um objeto JSON (`{...}`). | `422 Unprocessable Entity` |
| `ERRO_INTERNO` | Exceção inesperada capturada no servidor durante o processamento (`Exception`). O stack trace é registrado no `stderr` do servidor e nunca vazado ao cliente. | `500 Internal Server Error` |

---

## 4. Tabela de Comandos

| Comando | Status | Finalidade / Serviço Responsável |
|---|---|---|
| `CADASTRAR` | **Implementado** (legado) | Cadastro de usuário no sistema (nome, e-mail, senha criptografada em SHA-256). Atendido por `UsuarioService.cadastrar`. |
| `LOGIN` | **Implementado** (legado) | Autenticação de usuário por e-mail e hash SHA-256 de senha. Atendido por `UsuarioService.login`. |
| `CALCULAR_STATUS_VACINA` | *Previsto* (aguardando implementação) | Calcula próxima data de vencimento e status (em dia / próximo / atrasado) a partir da data da última aplicação e da frequência em dias. |
| `VERIFICAR_CONFLITO_HORARIO` | *Previsto* (aguardando implementação) | Serviço de cálculo e validação de conflito de agenda/horários de consultas veterinárias. |
| `GERAR_HASH_SENHA` | *Previsto* (aguardando implementação) | Serviço isolado para cálculo de hash criptográfico seguro (SHA-256). |
| `CALCULAR_PROGRESSO_CAMPANHA` | *Previsto* (aguardando implementação) | Serviço isolado de cálculo de metas, percentuais e arrecadação de campanhas beneficentes. |
| `VALIDAR_DOCUMENTO` | *Previsto* (aguardando implementação) | Validação de CPF e CNPJ por dígito verificador. |

---

## 5. Exemplos Concretos de Comunicação

### 5.1 Exemplo de Sucesso (Comando `LOGIN` implementado)

**Requisição (enviada pelo cliente em uma única linha com `\n`):**
```json
{"comando":"LOGIN","dados":{"email":"camila@petcare.com","senha":"senhaForte123"}}
```

**Resposta do Servidor (uma linha terminada em `\n`):**
```json
{"status":"OK","mensagem":"Login realizado com sucesso.","nome":"Dra. Camila Santos"}
```

---

### 5.2 Exemplo de `COMANDO_DESCONHECIDO`

**Requisição (enviada pelo cliente):**
```json
{"comando":"EMITIR_RELATORIO_FINANCEIRO","dados":{}}
```

**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"COMANDO_DESCONHECIDO","mensagem":"Comando desconhecido: EMITIR_RELATORIO_FINANCEIRO"}
```

---

### 5.3 Exemplo de `JSON_INVALIDO`

**Requisição com sintaxe JSON malformatada (falta fechamento de chaves):**
```json
{"comando":"LOGIN","dados":{"email":"camila@petcare.com"
```

**Resposta do Servidor:**
```json
{"status":"ERRO","codigo":"JSON_INVALIDO","mensagem":"JSON malformatado: java.io.EOFException: End of input at line 1 column 57 path $.dados.email"}
```
