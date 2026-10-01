import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * Manipulador de conexão de cliente individual (executado em uma thread do ExecutorService).
 * 
 * Responsável por:
 * 1. Ler a mensagem JSON de linha única enviada pelo cliente.
 * 2. Interpretar o comando e os dados via Gson.
 * 3. Rotear para a camada de serviços correspondente (ex: UsuarioService).
 * 4. Devolver a resposta em uma única linha JSON.
 * 5. Fechar a conexão de socket no bloco finally.
 */
public class ClienteHandler implements Runnable {

    private final Socket socket;
    private static final Gson gson = new Gson();

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
        String enderecoCliente = socket.getRemoteSocketAddress() != null 
                ? socket.getRemoteSocketAddress().toString() 
                : "desconhecido";

        BufferedReader leitor = null;
        PrintWriter escritor = null;

        try {
            // Inicializa streams de leitura e escrita com codificação UTF-8
            leitor = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            // autoFlush = true garante o envio imediato da linha pelo socket
            escritor = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);

            // Lê uma linha de texto do cliente contendo a mensagem JSON
            String linhaRecebida = leitor.readLine();

            if (linhaRecebida == null || linhaRecebida.trim().isEmpty()) {
                System.out.println("[ClienteHandler] Conexão encerrada pelo cliente (" + enderecoCliente + ") sem envio de dados.");
                return;
            }

            System.out.println("[ClienteHandler] Mensagem recebida de " + enderecoCliente + ": " + linhaRecebida);

            JsonObject respostaJson;

            try {
                // Interpreta a string JSON recebida usando JsonParser do Gson
                JsonElement elemento = JsonParser.parseString(linhaRecebida);

                if (!elemento.isJsonObject()) {
                    respostaJson = new JsonObject();
                    respostaJson.addProperty("status", "ERRO");
                    respostaJson.addProperty("mensagem", "Requisição inválida: esperava-se um objeto JSON.");
                } else {
                    JsonObject requisicao = elemento.getAsJsonObject();

                    String comandoBruto = requisicao.has("comando") && !requisicao.get("comando").isJsonNull()
                            ? requisicao.get("comando").getAsString()
                            : "";
                    String comando = comandoBruto.trim().toUpperCase();

                    JsonObject dados = requisicao.has("dados") && requisicao.get("dados").isJsonObject()
                            ? requisicao.getAsJsonObject("dados")
                            : new JsonObject();

                    // Roteamento do comando para o respectivo serviço
                    switch (comando) {
                        case "CADASTRAR":
                            respostaJson = UsuarioService.cadastrar(dados);
                            break;

                        case "LOGIN":
                            respostaJson = UsuarioService.login(dados);
                            break;

                        default:
                            respostaJson = new JsonObject();
                            respostaJson.addProperty("status", "ERRO");
                            respostaJson.addProperty("mensagem", "Comando desconhecido: " + comandoBruto);
                            break;
                    }
                }
            } catch (JsonSyntaxException e) {
                System.err.println("[ClienteHandler] JSON malformatado recebido de " + enderecoCliente + ": " + e.getMessage());
                respostaJson = new JsonObject();
                respostaJson.addProperty("status", "ERRO");
                respostaJson.addProperty("mensagem", "JSON malformatado: " + e.getMessage());
            }

            // Envia a resposta de volta ao cliente em uma única linha JSON
            String linhaResposta = gson.toJson(respostaJson);
            escritor.println(linhaResposta);
            System.out.println("[ClienteHandler] Resposta enviada para " + enderecoCliente + ": " + linhaResposta);

        } catch (IOException e) {
            System.err.println("[ClienteHandler] Erro de I/O na comunicação com " + enderecoCliente + ": " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[ClienteHandler] Erro inesperado ao atender cliente " + enderecoCliente + ": " + e.getMessage());
            e.printStackTrace();
        } finally {
            // Garante que a conexão do socket seja sempre fechada ao final do processamento
            try {
                if (leitor != null) {
                    leitor.close();
                }
                if (escritor != null) {
                    escritor.close();
                }
                if (socket != null && !socket.isClosed()) {
                    socket.close();
                }
                System.out.println("[ClienteHandler] Conexão com " + enderecoCliente + " encerrada.");
            } catch (IOException e) {
                System.err.println("[ClienteHandler] Erro ao fechar socket de " + enderecoCliente + ": " + e.getMessage());
            }
        }
    }
}
