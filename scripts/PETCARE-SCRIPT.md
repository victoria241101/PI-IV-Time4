# PetCare - Guia do Script de Controle (`petcare.js`)

Script Node.js para checagem de ambiente, inicializacao coordenada e controle dos servicos do projeto **PetCare (PI-IV-Time4)**: Servidor Java (porta 5000), Backend Node.js (porta 3000) e Frontend Flutter.

---

## 1. Pre-requisitos do Ambiente

- **Windows 10 ou 11** com CMD ou PowerShell.
- **Node.js 18+** e `npm`/`npx` configurados no `PATH`.
- **JDK 17+** no `PATH` ou instalado no Android Studio (`C:\Program Files\Android\Android Studio\jbr\bin`).
- **Flutter SDK** no `PATH` com licencas do Android aceitas (`flutter doctor --android-licenses`).
- Dependencias instaladas:
  - `servidor_java`: 4 bibliotecas JAR em `servidor_java/lib` (`bson`, `gson`, `mongodb-driver-core`, `mongodb-driver-sync`).
  - `backend`: dependencias em `backend/node_modules` (`express`, `nodemailer`, `fontkit`) e arquivo `backend/.env`.
  - `frontend`: arquivo `frontend/pubspec.yaml` e pasta `.dart_tool`.

---

## 2. Sintaxe e Linha de Comando Rapida

```
node scripts/petcare.js [acao] [flags]
```

Se executado sem argumento posicional, um **menu interativo numerado** sera exibido.

---

## 3. Acoes Disponiveis

| Acao | Descricao |
| :--- | :--- |
| `checar` | Checagem completa de ambiente e dependencias (somente leitura; nao altera nada). Retorna codigo de saida diferente de zero se houver FALHA. |
| `iniciar` | Executa `checar` primeiro. Se nao houver FALHA, sobe na ordem: Java (porta 5000), Backend (porta 3000) e Frontend Flutter, aguardando cada porta. |
| `java` | Sobe apenas o Servidor Java (`node scripts/compilar.js` e `node scripts/iniciar.js`), configurando o JDK dos processos filhos se necessario. Aguarda ate 30s pela porta 5000. |
| `back` | Sobe apenas o Backend (`npx.cmd tsx src/index.ts`) com `LEMBRETES_ATIVOS=false` (ou `true` se `--com-lembretes`). Aguarda ate 30s pela porta 3000. |
| `front` | Lista dispositivos Flutter, solicita a escolha (ou usa `--dispositivo`) e executa `flutter run` com ou sem `--dart-define=API_URL`. |
| `parar` | Encerra os processos escutando nas portas 5000 e 3000 por PID (`taskkill /PID <pid> /T /F`). Nao afeta outros processos. |
| `reiniciar` | Executa `parar`, aguarda 2 segundos e executa `iniciar`. |
| `status` | Testa conectividade nas portas 5000 e 3000 (via `net.Socket`), faz GET HTTP em `http://localhost:3000/` e verifica se a janela do Frontend esta aberta. |
| `verificar` | Executa 5 testes de integracao via socket TCP na porta 5000 do Servidor Java para validar o protocolo de mensagens. |
| `ajuda` | Exibe resumo das acoes, flags e sintaxe de uso. |

---

## 4. Flags Opcionais

- `--dispositivo=<id>`: Identificador do dispositivo para o `flutter run` (ex: `emulator-5554`).
- `--ip=<ipv4>`: Endereco IPv4 do computador na rede local para conexao de celular fisico (`--dart-define=API_URL=http://<IP>:3000`).
- `--com-lembretes`: Ativa o servico de lembretes no Backend (`LEMBRETES_ATIVOS=true`). Por padrao, e iniciado como `false`.
- `--sem-front`: Inicia apenas o Servidor Java e o Backend, sem abrir o Flutter.
- `--janelas`: Forca a abertura de janelas CMD independentes mesmo se o Windows Terminal (`wt.exe`) estiver disponivel.
- `--dry-run`: Modo simulacao que apenas imprime o conteudo dos arquivos `.cmd` e os argumentos (`argv`) de cada aba, sem criar arquivos nem iniciar processos.

> **Nota sobre o Windows Terminal**: Para evitar erros de escape de aspas e variaveis de ambiente no `wt`, cada aba executa um script `.cmd` temporario gerado no diretorio temporario do sistema (`os.tmpdir()`), fora do repositorio.

---

## 5. Diagnostico de Ambiente: O que `checar` Verifica

A acao `checar` gera uma tabela detalhada com tres classificacoes:

- **`[ OK ]`**: Requisito satisfeito e pronto para operacao.
- **`[AVISO]`**: O sistema consegue operar, mas ha pendencias recomendadas (ex: licencas Android pendentes, versao do Node abaixo da 18, portas ocupadas, ausencia de dispositivos conectados).
- **`[FALHA]`**: Impede a execucao do projeto. O script listara ao final a numeracao das correcoes com os comandos exatos para resolucao e retornara codigo de saida `1`.

### Itens avaliados por `checar`:
1. **Node.js e npx**: Presenca no PATH e versao do Node (aviso se menor que 18).
2. **JDK**: `javac` e `java` no PATH; caso ausentes, busca o JDK embutido no Android Studio (`jbr\bin`).
3. **Flutter SDK**: Presenca no PATH, versao e checagem de licencas Android (`flutter doctor`).
4. **Dispositivos**: Lista emuladores e celulares fisicos via `flutter devices --machine`.
5. **Jars do Java**: Presenca dos 4 arquivos JAR em `servidor_java/lib`.
6. **Dependencias do Backend**: Presenca de `express`, `nodemailer/dist` e `fontkit/dist` em `backend/node_modules`.
7. **Variaveis do Backend**: Existencia de `backend/.env` e presenca dos nomes de variaveis obrigatorias (sem expor valores).
8. **Portas 5000 e 3000**: Checa se estao livres ou ocupadas (com indicacao de PID e nome do processo).
9. **IPv4 da Maquina**: Detecta o IP local para configuracao em dispositivos moveis fisicos.
10. **Frontend**: Presenca de `frontend/pubspec.yaml` e diretorio `.dart_tool`.
11. **Git**: Lembrete de que arquivos de compilacao em `frontend/linux`, `macos` e `windows` nao devem ser commitados.

---

## 6. Exemplos de Uso

### Checagem rapida de dependencias:
```
node scripts/petcare.js checar
```

### Simular comandos e argumentos sem subir processos (--dry-run):
```
node scripts/petcare.js iniciar --sem-front --dry-run
```

### Iniciar Java e Backend apenas (sem Frontend):
```
node scripts/petcare.js iniciar --sem-front
```

### Iniciar tudo com Emulador Android:
```
node scripts/petcare.js iniciar --dispositivo=emulator-5554
```

### Iniciar com Celular Fisico na mesma rede Wi-Fi:
```
node scripts/petcare.js iniciar --ip=192.168.3.202
```
> **Atencao**: Celular e computador devem estar na mesma rede Wi-Fi, e a porta 3000 deve estar liberada no Firewall do Windows em rede privada.

### Iniciar Backend com envio de lembretes ativo:
```
node scripts/petcare.js back --com-lembretes
```

### Encerrar todos os servicos:
```
node scripts/petcare.js parar
```

---

## 7. Roteiro de 5 Minutos para Apresentacao a Banca

1. **Checagem de Integridade (30 segundos)**:
   ```
   node scripts/petcare.js checar
   ```
   *Mostra a banca que todas as dependencias, portas e ferramentas estao auditadas e em conformidade.*

2. **Inicializacao Coordenada (1 minuto)**:
   ```
   node scripts/petcare.js iniciar
   ```
   *Demonstra a abertura organizada dos 3 servicos: compilacao e subida do Servidor Java, subida do Backend Node e lancamento do Flutter.*

3. **Validacao do Status dos Servicos (30 segundos)**:
   ```
   node scripts/petcare.js status
   ```
   *Confirma que a porta 5000 esta aberta, o Backend esta respondendo HTTP na porta 3000 e o Frontend esta em execucao.*

4. **Verificacao do Protocolo Socket do Servidor Java (1 minuto)**:
   ```
   node scripts/petcare.js verificar
   ```
   *Executa em tempo real os testes de socket TCP: calculo de progresso de campanha, calculo de vacinas, hash PBKDF2 e validacao de senhas.*

5. **Simulacao de Resiliencia e Tolerancia a Falhas (1 minuto e meio)**:
   - Encerrar o Servidor Java pelo script:
     ```
     node scripts/petcare.js parar
     ```
   - Tentar realizar uma operacao no aplicativo Flutter.
   - **Observacao Importante**: O aplicativo Flutter possui um timeout de rede configurado de **ate 10 segundos** para exibir visualmente a mensagem de erro quando o backend ou servidor estiver indisponivel.
   - Subir o Servidor Java novamente:
     ```
     node scripts/petcare.js java
     ```
   - Repetir a operacao no aplicativo e comprovar a recuperacao do sistema.
