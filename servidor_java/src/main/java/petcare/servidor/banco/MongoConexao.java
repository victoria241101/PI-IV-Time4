package petcare.servidor.banco;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;

/**
 * Classe responsável por gerenciar a conexão com o MongoDB Atlas.
 * 
 * ATENÇÃO: Esta é uma estrutura preparatória inicial. A conexão real ainda
 * não está ativa pois a URI do MongoDB Atlas e o nome do banco ainda precisam
 * ser configurados quando o cluster for disponibilizado.
 */
public class MongoConexao {

    // TODO: Preencher com a URI real do MongoDB Atlas quando o cluster for configurado
    // Exemplo: "mongodb+srv://<usuario>:<senha>@cluster0.abcde.mongodb.net/?retryWrites=true&w=majority"
    private static final String CONNECTION_STRING = "SUA_URI_DO_MONGODB_ATLAS_AQUI";

    // TODO: Definir o nome do banco de dados oficial do projeto PetCare
    // Exemplo: "petcare_db"
    private static final String DATABASE_NAME = "petcare_db";

    // Instância única do cliente e banco (padrão Singleton)
    private static MongoClient mongoClient = null;
    private static MongoDatabase database = null;

    // Construtor privado para evitar instanciação direta
    private MongoConexao() {}

    /**
     * Retorna a instância do banco de dados MongoDB (MongoDatabase).
     * Quando o MongoDB Atlas estiver configurado, este método inicializará
     * o MongoClient e retornará a referência para o banco de dados.
     *
     * @return Instância de MongoDatabase configurada, ou null enquanto estiver em modo preparatório.
     */
    public static synchronized MongoDatabase getDatabase() {
        if (database == null) {
            // Verifica se a connection string ainda é o placeholder padrão
            if ("SUA_URI_DO_MONGODB_ATLAS_AQUI".equals(CONNECTION_STRING)) {
                System.out.println("[MongoConexao] AVISO: MongoDB ainda não configurado. Utilizando estrutura preparatória.");
                return null;
            }

            try {
                System.out.println("[MongoConexao] Conectando ao MongoDB Atlas...");
                mongoClient = MongoClients.create(CONNECTION_STRING);
                database = mongoClient.getDatabase(DATABASE_NAME);
                System.out.println("[MongoConexao] Conexão com o banco '" + DATABASE_NAME + "' estabelecida com sucesso.");
            } catch (Exception e) {
                System.err.println("[MongoConexao] Erro ao conectar ao MongoDB: " + e.getMessage());
                e.printStackTrace();
            }
        }
        return database;
    }

    /**
     * Fecha a conexão com o MongoDB caso o cliente esteja ativo.
     * Útil para encerramento gracioso do servidor.
     */
    public static synchronized void fecharConexao() {
        if (mongoClient != null) {
            try {
                mongoClient.close();
                mongoClient = null;
                database = null;
                System.out.println("[MongoConexao] Conexão com MongoDB encerrada.");
            } catch (Exception e) {
                System.err.println("[MongoConexao] Erro ao fechar conexão com MongoDB: " + e.getMessage());
            }
        }
    }
}
