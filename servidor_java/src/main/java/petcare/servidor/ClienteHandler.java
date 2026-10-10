package petcare.servidor;

import petcare.servidor.protocolo.CodigoErro;
import petcare.servidor.servicos.HashSenhaService;
import petcare.servidor.servicos.VacinaService;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSyntaxException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;

/**
 * Manipulador de conexão de cliente individual (executado em uma thread do ExecutorService).
 * 
 * Responsável por:
 * 1. Definir timeout de leitura e limitar o tamanho da linha recebida para blindagem.
 * 2. Ler e validar a mensagem JSON de linha única enviada pelo cliente.
 * 3. Rotear comandos normalizados via switch padronizado.
 * 4. Retornar respostas JSON sempre contendo status e mensagem, com códigos de erro padronizados.
 * 5. Garantir fechamento de recursos em qualquer cenário sem derrubar o pool de threads.
 */
public class ClienteHandler implements Runnable {

    /**
     * Timeout de leitura em milissegundos (5 segundos).
     */
    public static final int SO_TIMEOUT_MS = 5000;

    /**
     * Limite máximo do tamanho da linha lida (64 KB = 65.536 caracteres).
     */
    public static final int MAX_LINHA_BYTES = 65536;

    private final Socket socket;
    private static final Gson gson = new Gson();

    /**
     * Exceção interna para controle de requisições que excedem o tamanho máximo permitido.
     */
    private static class LinhaMuitoGrandeException extends Exception {
        private static final long serialVersionUID = 1L;

        public LinhaMuitoGrandeException(String mensagem) {
            super(mensagem);
        }
    }

    /**
     * Construtor que recebe o socket do cliente conectado.
     *
     * @param socket Conexão de socket TCP estabelecida com o cliente
     */
    public ClienteHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        String enderecoCliente = (socket != null && socket.getRemoteSocketAddress() != null)
                ? socket.getRemoteSocketAddress().toString()
                : "desconhecido";

        try (Socket s = this.socket) {
            // Configura timeout de leitura do socket (5 segundos)
            s.setSoTimeout(SO_TIMEOUT_MS);

            try (
                BufferedReader leitor = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
                PrintWriter escritor = new PrintWriter(new OutputStreamWriter(s.getOutputStream(), StandardCharsets.UTF_8), true)
            ) {
                String linhaRecebida;
                try {
                    linhaRecebida = lerLinhaComLimite(leitor, MAX_LINHA_BYTES);
                } catch (SocketTimeoutException e) {
                    System.err.println("[ClienteHandler] Timeout de leitura (" + SO_TIMEOUT_MS + " ms) esgotado para " + enderecoCliente);
                    JsonObject respostaTimeout = respostaErro(CodigoErro.JSON_INVALIDO,
                            "Tempo limite de leitura esgotado (timeout de " + SO_TIMEOUT_MS + " ms).");
                    enviarResposta(escritor, respostaTimeout, enderecoCliente);
                    return;
                } catch (LinhaMuitoGrandeException e) {
                    System.err.println("[ClienteHandler] Linha excedeu limite de 64 KB de " + enderecoCliente + ": " + e.getMessage());
                    JsonObject respostaGrande = respostaErro(CodigoErro.JSON_INVALIDO,
                            "Requisição excede o limite máximo permitido de 64 KB.");
                    enviarResposta(escritor, respostaGrande, enderecoCliente);
                    return;
                }

                // Linha nula ou vazia é tratada como JSON inválido conforme especificação
                if (linhaRecebida == null || linhaRecebida.trim().isEmpty()) {
                    System.out.println("[ClienteHandler] Requisição vazia recebida de " + enderecoCliente);
                    JsonObject respostaVazia = respostaErro(CodigoErro.JSON_INVALIDO,
                            "Requisição vazia: esperado objeto JSON.");
                    enviarResposta(escritor, respostaVazia, enderecoCliente);
                    return;
                }

                System.out.println("[ClienteHandler] Mensagem recebida de " + enderecoCliente + ": " + linhaRecebida);

                JsonObject respostaJson;

                try {
                    // Interpreta a string JSON recebida usando JsonParser do Gson
                    JsonElement elemento = JsonParser.parseString(linhaRecebida);

                    if (!elemento.isJsonObject()) {
                        respostaJson = respostaErro(CodigoErro.JSON_INVALIDO,
                                "Requisição inválida: esperava-se um objeto JSON na raiz.");
                    } else {
                        JsonObject requisicao = elemento.getAsJsonObject();

                        // 1. Validação do campo 'comando'
                        if (!requisicao.has("comando") || requisicao.get("comando").isJsonNull()) {
                            respostaJson = respostaErro(CodigoErro.COMANDO_AUSENTE,
                                    "Campo 'comando' é obrigatório.");
                        } else if (!requisicao.get("comando").isJsonPrimitive()
                                || !requisicao.get("comando").getAsJsonPrimitive().isString()) {
                            respostaJson = respostaErro(CodigoErro.COMANDO_AUSENTE,
                                    "Campo 'comando' deve ser uma string.");
                        } else {
                            String comandoBruto = requisicao.get("comando").getAsString();
                            String comando = comandoBruto.trim().toUpperCase();

                            if (comando.isEmpty()) {
                                respostaJson = respostaErro(CodigoErro.COMANDO_AUSENTE,
                                        "Campo 'comando' não pode ser vazio.");
                            } else {
                                // 2. Validação do campo 'dados'
                                // No protocolo PetCare, todos os comandos exigem o objeto 'dados'
                                if (!requisicao.has("dados")
                                        || requisicao.get("dados").isJsonNull()
                                        || !requisicao.get("dados").isJsonObject()) {
                                    respostaJson = respostaErro(CodigoErro.DADOS_INVALIDOS,
                                            "Campo 'dados' ausente ou inválido: deve ser um objeto JSON.");
                                } else {
                                    JsonObject dados = requisicao.getAsJsonObject("dados");

                                    // 3. Roteamento do comando normalizado via switch
                                    switch (comando) {

                                        // =====================================================================
                                        // COMO REGISTRAR UM NOVO COMANDO:
                                        // 1. Remova o comando da lista de previstos abaixo.
                                        // 2. Adicione um novo 'case' aqui chamando o método estático do Service.
                                        // Exemplo:
                                        // case "CALCULAR_STATUS_VACINA":
                                        //     respostaJson = VacinaService.calcularStatus(dados);
                                        //     break;
                                        // =====================================================================

                                        // =====================================================================
                                        // COMANDOS PREVISTOS (aguardando implementação dos serviços de cálculo)
                                        // =====================================================================
                                        case "CALCULAR_STATUS_VACINA":
                                            respostaJson = VacinaService.calcularStatus(dados);
                                            break;
                                        case "VERIFICAR_CONFLITO_HORARIO":
                                        case "GERAR_HASH_SENHA":
                                            resposta = HashSenhaService.executar(campos.get("senha"));
                                            break;
                                        case "CALCULAR_PROGRESSO_CAMPANHA":
                                        case "VALIDAR_DOCUMENTO":
                                            respostaJson = respostaErro(CodigoErro.COMANDO_NAO_IMPLEMENTADO,
                                                    "Comando previsto, mas ainda não implementado: " + comando);
                                            break;

                                        default:
                                            respostaJson = respostaErro(CodigoErro.COMANDO_DESCONHECIDO,
                                                    "Comando desconhecido: " + comandoBruto);
                                            break;
                                    }
                                }
                            }
                        }
                    }
                } catch (JsonSyntaxException e) {
                    System.err.println("[ClienteHandler] JSON malformatado recebido de " + enderecoCliente + ": " + e.getMessage());
                    respostaJson = respostaErro(CodigoErro.JSON_INVALIDO,
                            "JSON malformatado: " + e.getMessage());
                } catch (Exception e) {
                    System.err.println("[ClienteHandler] Erro interno inesperado ao processar requisição de " + enderecoCliente + ": " + e.getMessage());
                    e.printStackTrace();
                    respostaJson = respostaErro(CodigoErro.ERRO_INTERNO,
                            "Erro interno no servidor ao processar a requisição.");
                }

                // Envia a resposta de volta ao cliente em uma única linha JSON
                enviarResposta(escritor, respostaJson, enderecoCliente);

            } catch (IOException e) {
                System.err.println("[ClienteHandler] Erro de I/O na comunicação com " + enderecoCliente + ": " + e.getMessage());
            } catch (Throwable t) {
                System.err.println("[ClienteHandler] Erro fatal inesperado no atendimento a " + enderecoCliente + ": " + t.getMessage());
                t.printStackTrace();
            }
        } catch (IOException e) {
            System.err.println("[ClienteHandler] Erro ao gerenciar socket de " + enderecoCliente + ": " + e.getMessage());
        } catch (Throwable t) {
            System.err.println("[ClienteHandler] Erro inesperado ao fechar recursos de " + enderecoCliente + ": " + t.getMessage());
            t.printStackTrace();
        } finally {
            System.out.println("[ClienteHandler] Conexão com " + enderecoCliente + " encerrada.");
        }
    }

    /**
     * Lê uma linha do fluxo de entrada respeitando o limite máximo de caracteres.
     * Ignora caracteres de retorno de carro '\r' e termina ao encontrar '\n'.
     *
     * @param leitor BufferedReader conectado ao stream de entrada do socket
     * @param limiteMaximo Quantidade máxima de caracteres permitidos na linha
     * @return String contendo a linha lida, ou null se fim do fluxo sem caracteres
     * @throws IOException Em caso de falha de I/O ou timeout no socket
     * @throws LinhaMuitoGrandeException Se a linha exceder limiteMaximo
     */
    private String lerLinhaComLimite(BufferedReader leitor, int limiteMaximo)
            throws IOException, LinhaMuitoGrandeException {
        StringBuilder sb = new StringBuilder();
        int c;
        while ((c = leitor.read()) != -1) {
            if (c == '\n') {
                break;
            }
            if (c == '\r') {
                continue;
            }
            sb.append((char) c);
            if (sb.length() > limiteMaximo) {
                throw new LinhaMuitoGrandeException(
                        "Tamanho da requisição excedeu o limite máximo permitido de " + limiteMaximo + " bytes.");
            }
        }
        if (c == -1 && sb.length() == 0) {
            return null;
        }
        return sb.toString();
    }

    /**
     * Serializa o objeto JsonObject e envia como uma única linha de texto terminada em '\n'.
     *
     * @param escritor PrintWriter conectado ao stream de saída do socket
     * @param respostaJson JsonObject contendo a resposta a ser enviada
     * @param enderecoCliente Identificador do cliente para fins de log
     */
    private void enviarResposta(PrintWriter escritor, JsonObject respostaJson, String enderecoCliente) {
        if (escritor == null || respostaJson == null) {
            return;
        }
        try {
            String linhaResposta = gson.toJson(respostaJson);
            escritor.println(linhaResposta);
            escritor.flush();
            System.out.println("[ClienteHandler] Resposta enviada para " + enderecoCliente + ": " + linhaResposta);
        } catch (Exception e) {
            System.err.println("[ClienteHandler] Falha ao enviar resposta para " + enderecoCliente + ": " + e.getMessage());
        }
    }

    /**
     * Constrói um JsonObject de resposta de sucesso com status "OK" e mensagem.
     *
     * @param mensagem Descrição do sucesso da operação
     * @return JsonObject estruturado
     */
    public static JsonObject respostaOk(String mensagem) {
        JsonObject resposta = new JsonObject();
        resposta.addProperty("status", "OK");
        resposta.addProperty("mensagem", mensagem);
        return resposta;
    }

    /**
     * Constrói um JsonObject de resposta de erro com status "ERRO", codigo e mensagem.
     *
     * @param codigo Código padronizado do erro (enum CodigoErro)
     * @param mensagem Descrição amigável do erro
     * @return JsonObject estruturado
     */
    public static JsonObject respostaErro(CodigoErro codigo, String mensagem) {
        JsonObject resposta = new JsonObject();
        resposta.addProperty("status", "ERRO");
        resposta.addProperty("codigo", codigo.name());
        resposta.addProperty("mensagem", mensagem);
        return resposta;
    }
}
