# 🐾 PetCare

### Projeto Integrador IV — Engenharia de Software

O PetCare é uma aplicação desenvolvida para uma clínica veterinária, com o objetivo de facilitar o gerenciamento de serviços, o acompanhamento da saúde dos animais e a interação entre a clínica e os tutores.

O sistema reúne funcionalidades como cadastro e autenticação de usuários, acompanhamento de vacinas, gerenciamento de agendamentos e campanhas de arrecadação, permitindo uma organização mais eficiente das atividades da clínica.

Desenvolvido com Flutter, Node.js, TypeScript, MongoDB e Java, o projeto utiliza uma arquitetura integrada, na qual o aplicativo mobile se comunica com o backend para gerenciar informações e executar regras de negócio específicas por meio de um servidor Java.

## Equipe

**Time 4**
Alinne Monteiro de Melo | RA: 24801649
Alycia Santos Bond | RA: 25016465
Gabriel Benevides Bosso | RA: 24013653
Victoria Beatriz Nobre Andrade | RA: 25016398

Projeto desenvolvido como parte do Projeto Integrador IV do curso de Engenharia de Software.

## Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| Flutter / Dart | Desenvolvimento da interface da aplicação |
| Node.js / TypeScript | Desenvolvimento do backend e integração entre os serviços |
| Express | Gerenciamento das rotas HTTP |
| MongoDB Atlas | Persistência dos dados |
| Java | Processamento das regras de negócio |
| Gson | Manipulação de JSON no servidor Java |
| JUnit 5 | Automação de testes orientados a objetos |
| Git / GitHub | Versionamento e colaboração |

## Arquitetura da aplicação

O PetCare é organizado em três componentes principais.

### Frontend — Flutter

Responsável pela interface gráfica e pela interação com os usuários, permitindo acessar as funcionalidades disponíveis na aplicação.

### Backend — Node.js e TypeScript

Responsável por receber as requisições HTTP, realizar operações de autenticação, gerenciar os dados e integrar o frontend ao banco de dados e ao servidor Java.

### Servidor Java

Responsável por executar regras de negócio específicas, como cálculos de progresso de campanhas, status de vacinação, validação de senhas e verificação de conflitos de horários.

A comunicação com o backend ocorre por meio de **sockets TCP**, utilizando mensagens no formato JSON.

### Fluxo de comunicação

```text
               Aplicativo Flutter
                       |
                       | HTTP
                       v
             Backend Node.js
               (porta 3000)
                       |
             +---------+---------+
             |                   |
             v                   v
        MongoDB Atlas      Servidor Java
                              (porta 5000)
                                  |
                                  v
                         Regras de negócio
                                  |
                                  v
                           Resposta JSON
                                  |
                                  v
                          Backend → Flutter
```

## Estrutura do projeto

```text
PI-IV-Time4/
├── backend/
│   ├── src/
│   ├── .env
│   └── package.json
│
├── frontend/
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
│
├── servidor_java/
│   ├── docs/
│   ├── lib/
│   ├── scripts/
│   ├── src/
│   │   ├── main/
│   │   │   └── java/
│   │   │       └── petcare/
│   │   │           └── servidor/
│   │   │               ├── banco/
│   │   │               ├── protocolo/
│   │   │               ├── servicos/
│   │   │               ├── ClienteHandler.java
│   │   │               └── Servidor.java
│   │   └── test/
│   │       └── java/
│   │           └── petcare/
│   │               └── servidor/
│   │                   └── servicos/
│   └── package.json
│
├── scripts/
│   └── petcare.js
│
└── README.md
```

O diretório `scripts/` da raiz contém o controlador geral da aplicação. Já o diretório `servidor_java/scripts/` contém os scripts específicos de compilação e inicialização do servidor Java.

## Pré-requisitos

Para executar o PetCare, é necessário possuir:

- Windows 10 ou 11.
- Node.js 18 ou superior.
- npm e npx configurados.
- JDK 17 ou superior.
- Flutter SDK instalado e configurado.
- Emulador Android ou dispositivo compatível.
- Dependências do backend e do servidor Java instaladas.
- Arquivo `backend/.env` configurado.

O script de controle pode localizar o JDK instalado no Android Studio caso ele não esteja disponível no `PATH`.

### Dependências do servidor Java

O servidor utiliza as bibliotecas:

- Gson.
- BSON.
- MongoDB Driver Core.
- MongoDB Driver Sync.

Essas dependências são utilizadas para manipulação de JSON e integração com MongoDB.

## Inicialização do projeto

O PetCare possui um script centralizado de controle, localizado em:

`scripts/petcare.js`

Esse script permite verificar o ambiente, iniciar os componentes, consultar o status dos serviços e executar verificações de integração.

Todos os comandos abaixo devem ser executados **na raiz do repositório**.

### 1. Verificar o ambiente

```bash
node scripts/petcare.js checar
```

O comando realiza uma checagem das ferramentas, dependências, variáveis de ambiente, dispositivos e portas necessárias.

Os resultados são classificados como:

- `[ OK ]` — requisito atendido.
- `[AVISO]` — situação que merece atenção.
- `[FALHA]` — problema que impede a inicialização.

### 2. Iniciar a aplicação completa

```bash
node scripts/petcare.js iniciar
```

O script verifica o ambiente e inicializa os componentes na seguinte ordem:

1. Servidor Java — porta `5000`.
2. Backend Node.js — porta `3000`.
3. Frontend Flutter.

Caso nenhum dispositivo Flutter tenha sido informado, o script permite selecionar um dispositivo disponível.

### 3. Iniciar somente Java e Backend

```bash
node scripts/petcare.js iniciar --sem-front
```

### 4. Consultar o status dos serviços

```bash
node scripts/petcare.js status
```

Verifica a conectividade do servidor Java, a resposta HTTP do backend e a execução do frontend.

### 5. Verificar a integração TCP

```bash
node scripts/petcare.js verificar
```

Executa cinco verificações de integração por socket TCP para validar a comunicação e o protocolo de mensagens do servidor Java.

### 6. Encerrar os serviços

```bash
node scripts/petcare.js parar
```

Encerra os processos associados às portas `5000` e `3000`.

### 7. Reiniciar a aplicação

```bash
node scripts/petcare.js reiniciar
```

## Outros comandos disponíveis

| Comando | Descrição |
|---|---|
| `checar` | Verifica ambiente e dependências |
| `iniciar` | Inicializa os três componentes |
| `java` | Compila e inicia somente o servidor Java |
| `back` | Inicia somente o backend |
| `front` | Executa o frontend Flutter |
| `parar` | Encerra os serviços das portas 5000 e 3000 |
| `reiniciar` | Reinicia os serviços |
| `status` | Consulta o estado dos componentes |
| `verificar` | Executa verificações de integração TCP |
| `ajuda` | Exibe as instruções de uso |

### Flags opcionais

| Flag | Finalidade |
|---|---|
| `--sem-front` | Inicia sem o Flutter |
| `--dispositivo=<id>` | Seleciona um dispositivo Flutter |
| `--ip=<ipv4>` | Configura o endereço da API para celular físico |
| `--com-lembretes` | Ativa o serviço de lembretes no backend |
| `--janelas` | Abre os serviços em janelas CMD independentes |
| `--dry-run` | Simula os comandos sem iniciar processos |

### Exemplos

**Iniciar com emulador Android:**

```bash
node scripts/petcare.js iniciar --dispositivo=emulator-5554
```

**Iniciar com celular físico:**

```bash
node scripts/petcare.js iniciar --ip=192.168.3.202
```

O celular e o computador devem estar na mesma rede Wi-Fi, e o firewall deve permitir a comunicação com o backend.

**Iniciar o backend com lembretes:**

```bash
node scripts/petcare.js back --com-lembretes
```

**Simular a inicialização:**

```bash
node scripts/petcare.js iniciar --sem-front --dry-run
```

## Servidor Java — Principais classes

| Classe | Responsabilidade |
|---|---|
| `Servidor` | Inicialização do servidor TCP |
| `ClienteHandler` | Recebimento e processamento de requisições |
| `ProgressoCampanhaService` | Cálculo do progresso das campanhas |
| `VacinaService` | Cálculo do status de vacinação |
| `HashSenhaService` | Operações de hash e validação de senhas |

O servidor recebe comandos JSON, identifica o serviço solicitado e retorna uma resposta contendo o resultado do processamento ou informações de erro.

## Testes automatizados

O projeto utiliza **JUnit 5** para realizar testes orientados a objetos no servidor Java.

Foram aplicadas técnicas de teste intraclasse e interclasse, verificando regras de negócio e a interação entre classes.

### Testes intraclasse

**ProgressoCampanhaServiceTest**

Técnica: particionamento por categorias de métodos.

Cenários:

1. Campanha sem doações.
2. Campanha em andamento.
3. Campanha próxima da meta.
4. Meta atingida.
5. Meta ultrapassada.
6. Meta inválida.

**Resultado: 6 testes aprovados.**

**VacinaServiceTest**

Técnica: particionamento baseado nos estados calculados da vacina.

Cenários:

1. Vacina pendente.
2. Vacina em dia.
3. Vacina próxima do vencimento.
4. Vacina atrasada.
5. Data inválida.

**Resultado: 5 testes aprovados.**

### Testes interclasse

**ProgressoCampanhaInterclasseTest**

Verifica a integração entre as classes responsáveis pelo cálculo do progresso de campanhas e pela montagem das respostas JSON.

Foram implementados dois cenários:

- **Cenário normal:** campanha com R$ 1.500,00 arrecadados e meta de R$ 3.000,00.
- **Cenário alternativo/de erro:** campanha com meta financeira inválida.

Os testes exercitam a integração interna do serviço sem utilizar sockets.

**Resultado: 2 testes aprovados.**

### Resumo dos testes JUnit

| Categoria | Testes executados | Resultado |
|---|---:|---|
| Intraclasse — Progresso de campanhas | 6 | 6 aprovados |
| Intraclasse — Status de vacinas | 5 | 5 aprovados |
| Interclasse — Progresso de campanhas | 2 | 2 aprovados |
| **Total** | **13** | **13 aprovados** |

Os testes foram executados no IntelliJ IDEA com JUnit 5.

### Verificações de integração TCP

Além dos testes JUnit, o projeto disponibiliza cinco verificações de integração por meio do comando:

```bash
node scripts/petcare.js verificar
```

Essas verificações utilizam comunicação TCP para validar o protocolo do servidor Java, incluindo operações relacionadas a campanhas, vacinas e senhas.

As verificações TCP são independentes dos testes JUnit e possuem objetivos diferentes.



## Finalidade acadêmica

O PetCare foi desenvolvido com fins acadêmicos, permitindo aplicar conhecimentos de desenvolvimento mobile, arquitetura de software, programação orientada a objetos, banco de dados, comunicação entre sistemas, versionamento e testes automatizados.
