package petcare.servidor;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * Cliente de teste em modo console para validar o protocolo de comunicação
 * TCP e o formato das mensagens JSON trocadas com o Servidor PetCare.
 */
public class ClienteTeste {

    private static final String HOST = "localhost";
    private static final int PORTA = 5000;

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("      CLIENTE DE TESTE - BACKEND PETCARE          ");
        System.out.println("==================================================");

        // 1. Teste de CADASTRO de um novo usuário
        System.out.println("\n--- [TESTE 1] CADASTRAR Novo Usuário ---");
        String jsonCadastro = "{\"comando\": \"CADASTRAR\", \"dados\": {\"nome\": \"Dra. Camila Santos\", \"email\": \"camila@petcare.com\", \"senha\": \"senhaForte123\"}}";
        enviarRequisicao(jsonCadastro);

        // 2. Teste de CADASTRO DUPLICADO com o mesmo e-mail (deve retornar ERRO)
        System.out.println("\n--- [TESTE 2] CADASTRAR E-mail Duplicado ---");
        String jsonCadastroDuplicado = "{\"comando\": \"CADASTRAR\", \"dados\": {\"nome\": \"Camila Outra\", \"email\": \"camila@petcare.com\", \"senha\": \"outrasenha\"}}";
        enviarRequisicao(jsonCadastroDuplicado);

        // 3. Teste de LOGIN com credenciais corretas (deve retornar OK)
        System.out.println("\n--- [TESTE 3] LOGIN com Sucesso ---");
        String jsonLoginSucesso = "{\"comando\": \"LOGIN\", \"dados\": {\"email\": \"camila@petcare.com\", \"senha\": \"senhaForte123\"}}";
        enviarRequisicao(jsonLoginSucesso);

        // 4. Teste de LOGIN com senha incorreta (deve retornar ERRO)
        System.out.println("\n--- [TESTE 4] LOGIN com Senha Incorreta ---");
        String jsonLoginSenhaErrada = "{\"comando\": \"LOGIN\", \"dados\": {\"email\": \"camila@petcare.com\", \"senha\": \"senhaErrada\"}}";
        enviarRequisicao(jsonLoginSenhaErrada);

        // 5. Teste de LOGIN com e-mail não existente (deve retornar ERRO)
        System.out.println("\n--- [TESTE 5] LOGIN com E-mail Inexistente ---");
        String jsonLoginEmailInexistente = "{\"comando\": \"LOGIN\", \"dados\": {\"email\": \"naoexiste@petcare.com\", \"senha\": \"qualquer\"}}";
        enviarRequisicao(jsonLoginEmailInexistente);

        // 6. Teste de Comando Desconhecido (deve retornar ERRO de comando desconhecido)
        System.out.println("\n--- [TESTE 6] Comando Desconhecido ---");
        String jsonComandoDesconhecido = "{\"comando\": \"AGENDAR_CONSULTA\", \"dados\": {}}";
        enviarRequisicao(jsonComandoDesconhecido);

        System.out.println("\n==================================================");
        System.out.println("            FIM DOS TESTES AUTOMATIZADOS          ");
        System.out.println("==================================================");
    }

    /**
     * Abre uma conexão de socket TCP com o servidor, envia a mensagem em JSON (uma linha)
     * e aguarda a resposta (uma linha), imprimindo ambos no console.
     *
     * @param mensagemJson String contendo o JSON a ser enviado
     */
    private static void enviarRequisicao(String mensagemJson) {
        System.out.println("[CLIENTE] Conectando a " + HOST + ":" + PORTA + "...");

        try (
            Socket socket = new Socket(HOST, PORTA);
            PrintWriter escritor = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);
            BufferedReader leitor = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8))
        ) {
            System.out.println("[CLIENTE] Enviando:  " + mensagemJson);
            escritor.println(mensagemJson);

            String resposta = leitor.readLine();
            System.out.println("[CLIENTE] Resposta:  " + resposta);

        } catch (Exception e) {
            System.err.println("[CLIENTE] Erro ao comunicar com o servidor: " + e.getMessage());
        }
    }
}
