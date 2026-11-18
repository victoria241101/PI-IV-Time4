# Backend PetCare - Servidor TCP em Java Puro

O Servidor PetCare em Java puro presta serviços isolados de cálculo matemático e operações de segurança criptográfica via Socket TCP nativo (porta 5000), respondendo exclusivamente a quem abriu a conexão.

---

## O que o Servidor Faz e Não Faz

- **O que faz:**
  - Gera hashes PBKDF2 com HMAC-SHA256 e salt aleatório (`GERAR_HASH_SENHA`).
  - Verifica senhas contra hashes PBKDF2 em tempo constante (`VERIFICAR_SENHA`).
  - Calcula metas financeiras, porcentagens e status de campanhas de arrecadação via `BigDecimal` (`CALCULAR_PROGRESSO_CAMPANHA`).
- **O que NÃO faz:**
  - Não realiza operações de CRUD de banco de dados (a classe `MongoConexao` é uma estrutura preparatória que retorna `null`).
  - Não faz autenticação com emissão ou validação de JWT (pertence ao backend Node.js).
  - Não gerencia agendamentos, consultas veterinárias nem histórico de usuários ou pets.

Todas as mensagens seguem estritamente o protocolo JSON em linha única documentado em [docs/PROTOCOLO.md](docs/PROTOCOLO.md).

---

## Estrutura Real de Arquivos

```
servidor_java/
├── README.md
├── package.json
├── .gitignore
├── .gitattributes
├── .gitkeep
├── docs/
│   └── PROTOCOLO.md
├── lib/                                      (não versionada; gerada via npm install)
│   ├── bson-4.11.1.jar
│   ├── gson-2.10.1.jar
│   ├── mongodb-driver-core-4.11.1.jar
│   └── mongodb-driver-sync-4.11.1.jar
├── out/                                      (não versionada; gerada via compilação)
├── scripts/
│   ├── baixar-dependencias.js
│   ├── compilar.js
│   └── iniciar.js
└── src/
    └── main/java/petcare/servidor/
        ├── ClienteHandler.java               (roteador e manipulador de conexões TCP)
        ├── Servidor.java                     (classe principal e pool de threads)
        ├── banco/
        │   └── MongoConexao.java             (estrutura preparatória - sem conexão ativa)
        ├── protocolo/
        │   └── CodigoErro.java               (enum de códigos padronizados)
        └── servicos/
            ├── HashSenhaService.java         (serviço de hash e verificação PBKDF2)
            └── ProgressoCampanhaService.java (serviço de cálculo de progresso)
```

---

## Pré-requisitos

1. **Node.js (versão LTS):** Utilizado para executar os scripts de automação (`npm install`, `npm run compilar`, `npm run iniciar`).
2. **JDK 17 ou superior:** Os scripts de compilação e execução invocam os comandos `javac` e `java` através do `PATH` do sistema operacional (eles **não** consultam a variável de ambiente `JAVA_HOME`).

> **Dica para Windows (caso `javac` não esteja no PATH):** Se você utiliza o Android Studio, o JDK integrado encontra-se tipicamente em:
> `C:\Program Files\Android\Android Studio\jbr\bin`
> Você pode adicioná-lo temporariamente ao `PATH` da sessão atual do PowerShell com:
> ```powershell
> $env:Path = "C:\Program Files\Android\Android Studio\jbr\bin;$env:Path"
> ```

---

## Como Configurar, Compilar e Executar

### 1. Baixar as Dependências (.jar)

Na pasta `servidor_java/`, baixe os arquivos `.jar` necessários do Maven Central (`gson` e drivers do MongoDB):

```bash
npm install
```

> O comando executa o script nativo `scripts/baixar-dependencias.js` via hook `postinstall`. Também pode ser executado via `npm run baixar-dependencias`. Se os arquivos já existirem na pasta `lib/`, o download é ignorado automaticamente.

---

### 2. Compilar o Projeto

Compile todos os arquivos Java a partir da pasta `src/`:

```bash
npm run compilar
```
*(ou `node scripts/compilar.js`)*

O script varre os arquivos `.java` recursivamente e executa `javac` com flags `-Xlint:all -encoding UTF-8 -cp "lib/*" -d out`.

---

### 3. Iniciar o Servidor

Inicie o servidor TCP na porta 5000:

```bash
npm run iniciar
```
*(ou `node scripts/iniciar.js`)*

O console exibirá:
```text
==================================================
        INICIANDO SERVIDOR PETCARE (TCP)          
==================================================
[SERVIDOR] Servidor iniciado na porta 5000
[SERVIDOR] Pool de threads configurado com 20 threads.
[SERVIDOR] Aguardando conexões de clientes...
```

---

### 4. Como Parar o Servidor

Pressione `Ctrl+C` no terminal onde o servidor está rodando. O servidor registrará um encerramento gracioso via *Shutdown Hook*, aguardando até 5 segundos para finalizar tarefas em andamento no pool antes de fechar os recursos.

---

## Como Testar Manualmente por Socket

Com o servidor rodando, abra outro terminal PowerShell e envie um comando JSON via `System.Net.Sockets.TcpClient` (exemplo testando `GERAR_HASH_SENHA` com uma senha de teste):

```powershell
$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 5000)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8)
$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)

# Envia comando terminado em quebra de linha
$writer.WriteLine('{"comando":"GERAR_HASH_SENHA","dados":{"senha":"senha-falsa-de-teste"}}')
$writer.Flush()

# Lê a resposta de linha única
$resposta = $reader.ReadLine()
Write-Output $resposta

$client.Close()
```

Resposta esperada:
```json
{"status":"OK","mensagem":"Hash gerado com sucesso.","dados":{"hash":"pbkdf2$120000$..."}}
```

---

## Como Adicionar um Novo Comando

O `ClienteHandler` atua como roteador central agrupando as chamadas para os serviços especializados. Para registrar um novo cálculo:

1. **Criar a classe de serviço:** Na pasta `src/main/java/petcare/servidor/servicos/`, crie uma classe (por exemplo, `ExemploService.java`, no pacote `petcare.servidor.servicos`). A classe deve disponibilizar métodos públicos estáticos que recebam `JsonObject dados` e retornem um `JsonObject` construído com `ClienteHandler.respostaOk(...)` ou `ClienteHandler.respostaErro(...)`.
   *(Aviso: o nome `ExemploService` e o comando `CALCULAR_EXEMPLO` são meramente ilustrativos e não devem ser criados no projeto).*

2. **Registrar o comando no ClienteHandler:** Em `src/main/java/petcare/servidor/ClienteHandler.java`:
   - Importe a nova classe:
     ```java
     import petcare.servidor.servicos.ExemploService;
     ```
   - No `switch (comando)`, adicione o novo case direcionando a requisição para o serviço:
     ```java
     case "CALCULAR_EXEMPLO":
         respostaJson = ExemploService.calcular(dados);
         break;
     ```

3. **Atualizar a documentação:** Documente o comando, parâmetros esperados, retornos e erros no arquivo [docs/PROTOCOLO.md](docs/PROTOCOLO.md).
