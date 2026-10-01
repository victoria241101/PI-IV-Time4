import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Classe principal do backend PetCare.
 * 
 * Inicializa um servidor de socket TCP simples ouvindo na porta 5000.
 * Utiliza um pool de threads (ExecutorService) com 20 threads para
 * processar múltiplas conexões de clientes simultaneamente.
 */
public class Servidor {

    // Porta TCP definida para o protocolo do PetCare
    public static final int PORTA = 5000;

    // Tamanho do pool de threads para conexões simultâneas
    private static final int THREAD_POOL_SIZE = 20;

    public static void main(String[] args) {
        ExecutorService pool = Executors.newFixedThreadPool(THREAD_POOL_SIZE);

        System.out.println("==================================================");
        System.out.println("        INICIANDO SERVIDOR PETCARE (TCP)          ");
        System.out.println("==================================================");

        try (ServerSocket serverSocket = new ServerSocket(PORTA)) {
            System.out.println("[SERVIDOR] Servidor iniciado na porta " + PORTA);
            System.out.println("[SERVIDOR] Pool de threads configurado com " + THREAD_POOL_SIZE + " threads.");
            System.out.println("[SERVIDOR] Aguardando conexões de clientes...");

            // Registra hook de encerramento gracioso (Ctrl+C ou fechamento do processo)
            Runtime.getRuntime().addShutdownHook(new Thread(() -> {
                System.out.println("\n[SERVIDOR] Encerrando servidor e liberando recursos...");
                pool.shutdown();
                try {
                    if (!pool.awaitTermination(5, TimeUnit.SECONDS)) {
                        pool.shutdownNow();
                    }
                } catch (InterruptedException e) {
                    pool.shutdownNow();
                }
                MongoConexao.fecharConexao();
                System.out.println("[SERVIDOR] Servidor finalizado com sucesso.");
            }));

            // Loop contínuo de aceitação de clientes
            while (!serverSocket.isClosed()) {
                try {
                    // Bloqueia até que um cliente se conecte
                    Socket socketCliente = serverSocket.accept();

                    System.out.println("[SERVIDOR] Novo cliente conectado: " + socketCliente.getRemoteSocketAddress());

                    // Envia a tarefa de atendimento para uma thread disponível no pool
                    pool.execute(new ClienteHandler(socketCliente));

                } catch (IOException e) {
                    if (serverSocket.isClosed()) {
                        System.out.println("[SERVIDOR] ServerSocket foi fechado.");
                        break;
                    }
                    System.err.println("[SERVIDOR] Erro ao aceitar conexão de cliente: " + e.getMessage());
                }
            }

        } catch (IOException e) {
            System.err.println("[SERVIDOR] Falha fatal ao iniciar o ServerSocket na porta " + PORTA + ": " + e.getMessage());
            e.printStackTrace();
        } finally {
            pool.shutdown();
        }
    }
}
