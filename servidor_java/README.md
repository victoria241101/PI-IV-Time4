# Backend PetCare - Servidor TCP em Java Puro

O Servidor PetCare em Java puro presta serviços isolados e sem estado (*stateless*) de cálculo e processamento criptográfico via Socket TCP nativo na porta 5000, respondendo exclusivamente em linha única JSON a quem fez a requisição.

### O que o servidor faz:
- Cálculos matemáticos de progresso e metas financeiras de campanhas (`ProgressoCampanhaService`).
- Cálculos de prazos, próxima dose e status de vacinação de pets (`VacinaService`).
- Derivação criptográfica segura de senhas via PBKDF2-HMAC-SHA256 e verificação de integridade de senha (`HashSenhaService`).

### O que o servidor NÃO faz:
- Não executa operações de CRUD de entidades de negócio (usuários, pets, consultas, agendamentos, campanhas, doações).
- Não acessa banco de dados (a classe `MongoConexao` é uma estrutura preparatória/placeholder que retorna `null`).
- Não gerencia sessões nem realiza autenticação de usuários (essas funções pertencem ao Backend em Node.js/TypeScript).

Todas as mensagens seguem estritamente o protocolo JSON em linha única documentado em [docs/PROTOCOLO.md](docs/PROTOCOLO.md).

---

## Estrutura Real de Arquivos

```
servidor_java/
├── .gitattributes
├── .gitignore
├── .gitkeep
├── README.md
├── package.json
├── docs/
│   └── PROTOCOLO.md
├── lib/                                      (não versionada, gerada via npm install)
├── out/                                      (não versionada, saída do javac)
├── scripts/
│   ├── baixar-dependencias.js
│   ├── compilar.js
│   └── iniciar.js
└── src/
    └── main/java/petcare/servidor/
        ├── ClienteHandler.java               (package petcare.servidor)
        ├── Servidor.java                     (package petcare.servidor)
        ├── banco/
        │   └── MongoConexao.java             (package petcare.servidor.banco)
        ├── protocolo/
        │   └── CodigoErro.java               (package petcare.servidor.protocolo)
        └── servicos/
            ├── HashSenhaService.java         (package petcare.servidor.servicos)
            ├── ProgressoCampanhaService.java (package petcare.servidor.servicos)
            └── VacinaService.java            (package petcare.servidor.servicos)
```

---

## Configuração, Compilação e Execução

### Pré-requisitos
- **Node.js (versão LTS)**
- **JDK 17 ou superior** (com `javac` e `java` disponíveis no `PATH`)

> **Nota sobre o JDK no Windows:** Os scripts de automação chamam os executáveis `javac` e `java` diretamente pelo `PATH` do sistema operacional (sem depender da variável `JAVA_HOME`). No Windows com Android Studio instalado, um JDK compatível costuma estar localizado em:
> `C:\Program Files\Android\Android Studio\jbr\bin`
> Se necessário, você pode adicioná-lo temporariamente ao `PATH` da sessão do terminal PowerShell:
> ```powershell
> $env:PATH += ";C:\Program Files\Android\Android Studio\jbr\bin"
> ```

---

### Passo 1. Instalação de Dependências (.jar)

Na pasta `servidor_java/`, execute o comando:

```bash
npm install
```

O hook de `postinstall` acionará automaticamente o script `node scripts/baixar-dependencias.js`, baixando para a pasta `lib/` os 4 arquivos `.jar` necessários do repositório Maven Central:
- `gson-2.10.1.jar`
- `mongodb-driver-sync-4.11.1.jar`
- `mongodb-driver-core-4.11.1.jar`
- `bson-4.11.1.jar`

> Se os `.jar` já existirem na pasta `lib/`, o download será ignorado automaticamente.

---

### Passo 2. Compilar o Projeto

Para compilar todos os 7 arquivos `.java` a partir de `src/` e gerar os arquivos `.class` em `out/`, execute:

```bash
npm run compilar
```

Ou diretamente via Node.js:
```bash
node scripts/compilar.js
```

> **Nota:** A compilação cobre só `src/main` e os testes em `src/test` não são compilados nem executados por estes scripts.

---

### Passo 3. Iniciar o Servidor

Inicie o servidor TCP na porta 5000:

```bash
npm run iniciar
```

Ou diretamente via Node.js:
```bash
node scripts/iniciar.js
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

### Passo 4. Teste Manual por Socket TCP

Para testar o servidor sem depender de serviços externos e sem expor dados sensíveis, abra um terminal PowerShell e envie um comando de cálculo (ex.: `CALCULAR_PROGRESSO_CAMPANHA`) via `System.Net.Sockets.TcpClient`:

```powershell
$tcp = New-Object System.Net.Sockets.TcpClient("localhost", 5000)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8)
$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)

# Envia a requisição em linha única terminada em \n
$requisicao = '{"comando":"CALCULAR_PROGRESSO_CAMPANHA","dados":{"valorArrecadado":850.50,"metaValor":1000.00}}'
$writer.WriteLine($requisicao)
$writer.Flush()

# Lê a resposta enviada pelo servidor
$resposta = $reader.ReadLine()
Write-Output "Resposta do servidor: $resposta"

# Encerra conexão
$tcp.Close()
```

Saída esperada:
```json
{"status":"OK","mensagem":"Progresso da campanha calculado com sucesso.","dados":{"porcentagem":85.0,"porcentagemExibicao":85.0,"valorRestante":149.50,"statusProgresso":"QUASE_LA"}}
```

---

### Como Parar o Servidor

Pressione `Ctrl+C` no terminal onde o servidor está em execução. O *shutdown hook* configurado no `Servidor.java` interceptará o sinal, aguardará a conclusão de tarefas em andamento, encerrará o pool de threads com segurança e fechará as conexões.

---

## Protocolo de Comunicação

Para detalhes sobre os formatos de mensagem, especificações de campos, códigos de erro padronizados (`JSON_INVALIDO`, `COMANDO_AUSENTE`, `COMANDO_DESCONHECIDO`, `COMANDO_NAO_IMPLEMENTADO`, `DADOS_INVALIDOS`, `ERRO_INTERNO`) e exemplos práticos de requisição e resposta, consulte:
👉 **[docs/PROTOCOLO.md](docs/PROTOCOLO.md)**

---

## Como Adicionar um Novo Comando

> **Aviso:** O exemplo abaixo é puramente ilustrativo e fictício para demonstrar a arquitetura; não deve ser criado no projeto.

Para registrar um novo serviço de cálculo no Servidor Java:

1. **Criar a classe de serviço:** Na pasta `src/main/java/petcare/servidor/servicos/`, crie a classe fictícia no pacote `petcare.servidor.servicos`. Ela deve conter métodos estáticos que recebem `JsonObject dados` e devolvem `JsonObject`, utilizando `ClienteHandler.respostaOk(...)` para sucesso e `ClienteHandler.respostaErro(...)` para falhas de validação:
   ```java
   package petcare.servidor.servicos;

   import com.google.gson.JsonObject;
   import petcare.servidor.ClienteHandler;
   import petcare.servidor.protocolo.CodigoErro;

   public class ExemploService {
       public static JsonObject calcularExemplo(JsonObject dados) {
           if (dados == null || !dados.has("fator")) {
               return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Campo 'fator' é obrigatório.");
           }
           double fator = dados.get("fator").getAsDouble();
           JsonObject resposta = ClienteHandler.respostaOk("Cálculo de exemplo executado.");
           JsonObject dadosResp = new JsonObject();
           dadosResp.addProperty("resultado", fator * 2);
           resposta.add("dados", dadosResp);
           return resposta;
       }
   }
   ```

2. **Importar o service no ClienteHandler:** Em `src/main/java/petcare/servidor/ClienteHandler.java`, importe a nova classe:
   ```java
   import petcare.servidor.servicos.ExemploService;
   ```

3. **Registrar o comando no switch:** Localize o `switch (comando)` e adicione o novo caso chamando o método do serviço:
   ```java
   case "CALCULAR_EXEMPLO":
       respostaJson = ExemploService.calcularExemplo(dados);
       break;
   ```

4. **Atualizar a documentação:** No arquivo [docs/PROTOCOLO.md](docs/PROTOCOLO.md), registre os parâmetros de entrada em `dados`, campos de saída, códigos de erro e exemplos de requisição e resposta.
