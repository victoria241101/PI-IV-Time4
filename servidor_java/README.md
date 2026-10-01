# Backend PetCare - Servidor TCP em Java Puro

Servidor backend em Java puro para o aplicativo **PetCare** (sistema de clínica veterinária, agendamento de consultas e campanhas beneficentes/doações).

Este projeto atende rigorosamente às restrições acadêmicas da disciplina:
- **Linguagem:** Java puro (compatível com Java 17+ e Java 25 LTS).
- **Comunicação:** Socket TCP nativo (`ServerSocket` / `Socket`), **sem** WebSocket e **sem** frameworks web (Spring Boot, Javalin, Vert.x, etc.).
- **Multithreading:** `ExecutorService` (pool fixo de 20 threads) nativo do JDK.
- **Formato das mensagens:** JSON em linha única codificado em UTF-8, interpretado com a biblioteca **Gson**.
- **Segurança:** Hash de senhas com `MessageDigest` (algoritmo SHA-256) nativo do Java, sem BCrypt.
- **Banco de dados:** Estruturado e preparado para integração com **MongoDB Atlas** via driver oficial síncrono (`org.mongodb:mongodb-driver-sync`). No momento, utiliza persistência em memória (`ConcurrentHashMap`) enquanto o cluster do banco não for conectado.
- **Automação de dependências:** Script leve via Node.js puro (`npm install`) para baixar os arquivos `.jar` sem versioná-los no Git.

---

## Estrutura de Arquivos

```
servidor_java/
├── lib/                                    # Pasta gerada pelo comando npm install (ignorada no Git)
│   ├── gson-2.10.1.jar                     # Manipulação e parse de JSON
│   ├── mongodb-driver-sync-4.11.1.jar      # Driver oficial síncrono do MongoDB
│   ├── mongodb-driver-core-4.11.1.jar      # Núcleo do driver MongoDB
│   └── bson-4.11.1.jar                     # Manipulação de documentos BSON
├── Servidor.java                           # Ponto de entrada, ServerSocket porta 5000 e pool de threads
├── ClienteHandler.java                     # Manipulador de cada conexão em thread dedicada
├── UsuarioService.java                     # Lógica de negócio (CADASTRAR, LOGIN, SHA-256 e mock em memória)
├── MongoConexao.java                       # Conexão singleton preparatória para o MongoDB Atlas
├── ClienteTeste.java                       # Cliente de teste manual/automatizado via terminal
├── package.json                            # Gatilho do npm para automação do setup (sem libs externas)
├── baixar-dependencias.js                  # Script Node.js puro para download dos .jar do Maven Central
├── .gitignore                              # Ignora arquivos compilados (.class), lib/*.jar e node_modules/
└── README.md                               # Esta documentação
```

---

## Como Configurar, Compilar e Executar

### Pré-requisitos
- **JDK instalado** (versão 17 ou superior; testado com JDK 25 LTS).
- **Node.js instalado** (versão 18 ou superior, usado exclusivamente para automação do download dos `.jar`).

---

### Passo 0. Baixar as Dependências (.jar)

Antes de compilar o servidor pela primeira vez, abra o terminal dentro da pasta `servidor_java/` e execute:

```bash
npm install
```

> **Nota:** O comando acima executará automaticamente o script `baixar-dependencias.js` (via hook `postinstall`), baixando os 4 arquivos `.jar` necessários diretamente do Maven Central para dentro da pasta `servidor_java/lib/`. Se os arquivos já existirem, o download será ignorado para economizar tempo e banda.
>
> Caso prefira ou esteja no PowerShell do Windows com restrição de política de scripts, você também pode executar diretamente:
> ```bash
> node baixar-dependencias.js
> ```

---

### Passo 1. Compilação do Java

Dentro da pasta `servidor_java/`, execute:

#### No Windows (PowerShell ou Prompt de Comando):
```powershell
javac -cp "lib/*" -encoding UTF-8 *.java
```

#### No Linux / macOS (Bash):
```bash
javac -cp "lib/*" -encoding UTF-8 *.java
```

---

### Passo 2. Executando o Servidor

Após compilar, inicie o servidor:

#### No Windows (PowerShell / CMD):
```powershell
java -cp ".;lib/*" Servidor
```

#### No Linux / macOS:
```bash
java -cp ".:lib/*" Servidor
```

O console exibirá:
```
==================================================
        INICIANDO SERVIDOR PETCARE (TCP)          
==================================================
[SERVIDOR] Servidor iniciado na porta 5000
[SERVIDOR] Pool de threads configurado com 20 threads.
[SERVIDOR] Aguardando conexões de clientes...
```

---

### Passo 3. Executando o Cliente de Teste

Abra **outro terminal**, navegue até a pasta `servidor_java/` e execute:

#### No Windows (PowerShell / CMD):
```powershell
java -cp ".;lib/*" ClienteTeste
```

#### No Linux / macOS:
```bash
java -cp ".:lib/*" ClienteTeste
```

O `ClienteTeste` enviará automaticamente requisições cobrindo todos os fluxos:
1. Cadastro de usuário com sucesso
2. Tentativa de cadastro duplicado (validação de e-mail existente)
3. Login com credenciais válidas
4. Tentativa de login com senha incorreta
5. Tentativa de login com e-mail não cadastrado
6. Envio de comando desconhecido

---

## Especificação do Protocolo de Comunicação (API TCP)

### Formato Geral da Mensagem

Todas as mensagens enviadas do cliente para o servidor devem ser enviadas como uma **única linha de texto** terminada por caractere de quebra de linha (`\n`), contendo um objeto JSON com a seguinte estrutura:

```json
{
  "comando": "NOME_DO_COMANDO",
  "dados": {
    "campo1": "valor1",
    "campo2": "valor2"
  }
}
```

A resposta do servidor também é devolvida em uma **única linha de texto** (`\n`) contendo um JSON com a propriedade `"status"` (`"OK"` ou `"ERRO"`).

---

### 1. Comando: `CADASTRAR`

Registra um novo usuário no sistema com senha criptografada em SHA-256.

#### Requisição:
```json
{
  "comando": "CADASTRAR",
  "dados": {
    "nome": "Dra. Camila Santos",
    "email": "camila@petcare.com",
    "senha": "minhaSenhaSegura123"
  }
}
```

#### Resposta de Sucesso:
```json
{
  "status": "OK",
  "mensagem": "Cadastro realizado com sucesso."
}
```

#### Respostas de Erro:
- **E-mail já cadastrado:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "Este e-mail já está cadastrado."
  }
  ```
- **Campos obrigatórios ausentes:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "Todos os campos (nome, email, senha) são obrigatórios."
  }
  ```

---

### 2. Comando: `LOGIN`

Autentica um usuário existente conferindo o hash SHA-256 da senha informada.

#### Requisição:
```json
{
  "comando": "LOGIN",
  "dados": {
    "email": "camila@petcare.com",
    "senha": "minhaSenhaSegura123"
  }
}
```

#### Resposta de Sucesso:
```json
{
  "status": "OK",
  "mensagem": "Login realizado com sucesso.",
  "nome": "Dra. Camila Santos"
}
```

#### Respostas de Erro:
- **E-mail não encontrado:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "E-mail não cadastrado."
  }
  ```
- **Senha incorreta:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "Senha incorreta."
  }
  ```
- **Campos vazios:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "E-mail e senha são obrigatórios."
  }
  ```

---

### 3. Comandos Não Reconhecidos ou Erros de Protocolo

- **Comando não implementado:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "Comando desconhecido: AGENDAR_CONSULTA"
  }
  ```
- **JSON malformatado:**
  ```json
  {
    "status": "ERRO",
    "mensagem": "JSON malformatado: <detalhes do parser>"
  }
  ```

---

## Integração com MongoDB Atlas (Próximos Passos)

1. Abrir o arquivo `MongoConexao.java`.
2. Substituir `CONNECTION_STRING` pela URI do seu cluster no MongoDB Atlas (ex: `mongodb+srv://...`).
3. Definir o `DATABASE_NAME` correto.
4. No arquivo `UsuarioService.java`, substituir os pontos marcados com `// TODO:` pelas chamadas à coleção `MongoCollection<Document>`.
