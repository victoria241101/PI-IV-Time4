# Backend PetCare - Servidor TCP em Java Puro

O Servidor PetCare em Java puro presta serviços isolados de cálculo e processamento via Socket TCP nativo, respondendo exclusivamente a quem fez a requisição.
Ele opera de forma independente do backend principal em Node.js/TypeScript e NÃO realiza operações de CRUD de negócio (usuários, pets, consultas, campanhas, doações).
Todas as mensagens seguem estritamente o protocolo JSON em linha única documentado em [docs/PROTOCOLO.md](docs/PROTOCOLO.md).

---

## Estrutura de Arquivos

```
servidor_java/
├── README.md
├── package.json
├── .gitignore
├── .gitattributes
├── .gitkeep
├── scripts/
│   ├── baixar-dependencias.js
│   ├── compilar.js
│   └── iniciar.js
├── docs/
│   └── PROTOCOLO.md
├── lib/                          (não versionada, gerada via npm install / script)
├── out/                          (não versionada, saída do javac)
└── src/
    ├── main/java/petcare/servidor/
    │   ├── Servidor.java                     (package petcare.servidor)
    │   ├── ClienteHandler.java               (package petcare.servidor)
    │   ├── protocolo/CodigoErro.java         (package petcare.servidor.protocolo)
    │   ├── servicos/UsuarioService.java      (package petcare.servidor.servicos)
    │   └── banco/MongoConexao.java           (package petcare.servidor.banco)
    └── test/java/petcare/servidor/
        └── ClienteTeste.java                 (package petcare.servidor)
```

---

## Como Configurar, Compilar e Executar

### Pré-requisitos
- **JDK 17 ou superior**
- **Node.js (versão LTS)**

---

### Passo 1. Baixar as Dependências (.jar)

Na pasta `servidor_java/`, instale os arquivos `.jar` necessários do Maven Central (`gson` e MongoDB driver) executando:

```bash
npm install
```

> **Alternativa manual:** Você também pode rodar `npm run baixar-dependencias` ou diretamente `node scripts/baixar-dependencias.js`. Se os `.jar` já estiverem na pasta `lib/`, o download será ignorado automaticamente.

---

### Passo 2. Compilar o Projeto

Compile todos os arquivos Java a partir da pasta `src/` gerando os `.class` em `out/`:

```bash
npm run compilar
```

> **Comando manual equivalente:**
> - Windows: `javac -Xlint:all -encoding UTF-8 -cp "lib/*" -d out src/main/java/petcare/servidor/*.java src/main/java/petcare/servidor/protocolo/*.java src/main/java/petcare/servidor/servicos/*.java src/main/java/petcare/servidor/banco/*.java src/test/java/petcare/servidor/*.java`
> - Linux / macOS: `javac -Xlint:all -encoding UTF-8 -cp "lib/*" -d out $(find src -name "*.java")`

---

### Passo 3. Iniciar o Servidor

Inicie o servidor TCP na porta 5000:

```bash
npm run iniciar
```

O script multiplataforma inicializará a classe principal `petcare.servidor.Servidor`. O console exibirá:
```
==================================================
        INICIANDO SERVIDOR PETCARE (TCP)          
==================================================
[SERVIDOR] Servidor iniciado na porta 5000
[SERVIDOR] Pool de threads configurado com 20 threads.
[SERVIDOR] Aguardando conexões de clientes...
```

> **Comando manual equivalente:**
> - Windows (PowerShell / CMD): `java -cp "out;lib/*" petcare.servidor.Servidor`
> - Linux / macOS: `java -cp "out:lib/*" petcare.servidor.Servidor`

---

### Passo 4. Executar o Cliente de Teste

Abra **outro terminal**, acesse `servidor_java/` e execute:

#### No Windows (PowerShell / CMD):
```powershell
java -cp "out;lib/*" petcare.servidor.ClienteTeste
```

#### No Linux / macOS:
```bash
java -cp "out:lib/*" petcare.servidor.ClienteTeste
```

O `ClienteTeste` enviará requisições cobrindo cenários de sucesso e erro para validar o funcionamento do servidor.

---

## Protocolo de Comunicação

Para detalhes sobre o formato de mensagens, códigos de erro padronizados (`JSON_INVALIDO`, `COMANDO_AUSENTE`, `COMANDO_DESCONHECIDO`, `COMANDO_NAO_IMPLEMENTADO`, `DADOS_INVALIDOS`, `ERRO_INTERNO`) e exemplos práticos, consulte a documentação oficial em:
👉 **[docs/PROTOCOLO.md](docs/PROTOCOLO.md)**

---

## Como Adicionar um Novo Comando

Para registrar um novo serviço de cálculo no Servidor Java:

1. **Criar a classe de serviço:** Na pasta `src/main/java/petcare/servidor/servicos/`, crie uma classe (ex.: `VacinaService.java`) no pacote `petcare.servidor.servicos`. Ela deve conter métodos estáticos que recebem `JsonObject dados` e devolvem `JsonObject` de resposta (usando `ClienteHandler.respostaOk(...)` ou `ClienteHandler.respostaErro(...)`).
   > **Observação:** `ClienteHandler.respostaOk(String mensagem)` devolve um `JsonObject` ao qual se pode acrescentar campos extras com `.addProperty(...)` (ex.: `resposta.addProperty("proximaData", data);`).
2. **Importar o service no ClienteHandler:** Em `src/main/java/petcare/servidor/ClienteHandler.java`, adicione o import do novo serviço:
   ```java
   import petcare.servidor.servicos.VacinaService;
   ```
3. **Registrar o comando no roteador:** No mesmo arquivo `ClienteHandler.java`, localize o `switch (comando)` e mova o comando da lista de comandos previstos para um novo `case`, chamando o seu service:
   ```java
   case "CALCULAR_STATUS_VACINA":
       respostaJson = VacinaService.calcularStatus(dados);
       break;
   ```
4. **Atualizar a documentação:** No arquivo [docs/PROTOCOLO.md](docs/PROTOCOLO.md), atualize a tabela de comandos alterando o status de *Previsto* para **Implementado**, descrevendo seus parâmetros e respostas.
