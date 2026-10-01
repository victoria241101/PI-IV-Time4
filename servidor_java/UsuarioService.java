import com.google.gson.JsonObject;
import org.bson.Document;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Serviço responsável pela lógica de negócios relacionada a usuários (cadastro e autenticação).
 * 
 * Atualmente utiliza uma estrutura de dados thread-safe em memória (ConcurrentHashMap)
 * simulando uma coleção do MongoDB, até que a integração com o MongoDB Atlas seja configurada.
 */
public class UsuarioService {

    // =========================================================================
    // ESTRUTURA EM MEMÓRIA (MOCK)
    // =========================================================================
    // TODO: substituir por MongoCollection<Document> quando o MongoDB Atlas estiver configurado
    // Exemplo futuro com MongoDB:
    // private static MongoCollection<Document> getColecao() {
    //     return MongoConexao.getDatabase().getCollection("usuarios");
    // }
    private static final Map<String, Document> colecaoUsuariosEmMemoria = new ConcurrentHashMap<>();

    /**
     * Realiza o cadastro de um novo usuário no sistema.
     *
     * @param dados Objeto JsonObject contendo "nome", "email" e "senha"
     * @return JsonObject com status ("OK" ou "ERRO") e mensagem explicativa
     */
    public static JsonObject cadastrar(JsonObject dados) {
        JsonObject resposta = new JsonObject();

        if (dados == null) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "Dados de cadastro não fornecidos.");
            return resposta;
        }

        String nome = dados.has("nome") && !dados.get("nome").isJsonNull() ? dados.get("nome").getAsString().trim() : "";
        String email = dados.has("email") && !dados.get("email").isJsonNull() ? dados.get("email").getAsString().trim().toLowerCase() : "";
        String senha = dados.has("senha") && !dados.get("senha").isJsonNull() ? dados.get("senha").getAsString() : "";

        // Validação básica dos campos
        if (nome.isEmpty() || email.isEmpty() || senha.isEmpty()) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "Todos os campos (nome, email, senha) são obrigatórios.");
            return resposta;
        }

        // =====================================================================
        // VERIFICAÇÃO DE DUPLICIDADE DE E-MAIL
        // =====================================================================
        // TODO: substituir por consulta no MongoDB:
        // Document existente = getColecao().find(Filters.eq("email", email)).first();
        // if (existente != null) { ... }
        if (colecaoUsuariosEmMemoria.containsKey(email)) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "Este e-mail já está cadastrado.");
            return resposta;
        }

        // Gera o hash SHA-256 da senha para armazenamento seguro
        String senhaHash = gerarHash(senha);

        // Cria o documento de usuário seguindo a estrutura padrão do MongoDB
        Document novoUsuario = new Document();
        novoUsuario.append("nome", nome);
        novoUsuario.append("email", email);
        novoUsuario.append("senha", senhaHash);
        novoUsuario.append("dataCadastro", System.currentTimeMillis());

        // =====================================================================
        // PERSISTÊNCIA DO USUÁRIO
        // =====================================================================
        // TODO: substituir por inserção no MongoDB Atlas:
        // getColecao().insertOne(novoUsuario);
        colecaoUsuariosEmMemoria.put(email, novoUsuario);

        System.out.println("[UsuarioService] Usuário cadastrado com sucesso: " + email + " (" + nome + ")");

        resposta.addProperty("status", "OK");
        resposta.addProperty("mensagem", "Cadastro realizado com sucesso.");
        return resposta;
    }

    /**
     * Realiza a autenticação de login de um usuário.
     *
     * @param dados Objeto JsonObject contendo "email" e "senha"
     * @return JsonObject com status ("OK" ou "ERRO"), mensagem e nome (em caso de sucesso)
     */
    public static JsonObject login(JsonObject dados) {
        JsonObject resposta = new JsonObject();

        if (dados == null) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "Dados de login não fornecidos.");
            return resposta;
        }

        String email = dados.has("email") && !dados.get("email").isJsonNull() ? dados.get("email").getAsString().trim().toLowerCase() : "";
        String senha = dados.has("senha") && !dados.get("senha").isJsonNull() ? dados.get("senha").getAsString() : "";

        // Validação básica dos campos
        if (email.isEmpty() || senha.isEmpty()) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "E-mail e senha são obrigatórios.");
            return resposta;
        }

        // =====================================================================
        // BUSCA DO USUÁRIO PELO E-MAIL
        // =====================================================================
        // TODO: substituir por busca no MongoDB Atlas:
        // Document usuario = getColecao().find(Filters.eq("email", email)).first();
        Document usuario = colecaoUsuariosEmMemoria.get(email);

        if (usuario == null) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "E-mail não cadastrado.");
            return resposta;
        }

        // Calcula o hash da senha informada e compara com o hash armazenado
        String senhaHashDigitada = gerarHash(senha);
        String senhaHashSalva = usuario.getString("senha");

        if (!senhaHashDigitada.equals(senhaHashSalva)) {
            resposta.addProperty("status", "ERRO");
            resposta.addProperty("mensagem", "Senha incorreta.");
            return resposta;
        }

        String nome = usuario.getString("nome");
        System.out.println("[UsuarioService] Login efetuado com sucesso: " + email + " (" + nome + ")");

        resposta.addProperty("status", "OK");
        resposta.addProperty("mensagem", "Login realizado com sucesso.");
        resposta.addProperty("nome", nome);
        return resposta;
    }

    /**
     * Calcula o hash criptográfico SHA-256 de uma sequência de texto (senha).
     *
     * @param texto Texto a ser transformado em hash
     * @return String hexadecimal de 64 caracteres representando o hash SHA-256
     */
    private static String gerarHash(String texto) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(texto.getBytes(StandardCharsets.UTF_8));
            
            // Converte os bytes do hash para representação hexadecimal
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0'); // Garante 2 dígitos por byte
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Erro ao instanciar algoritmo de hash SHA-256", e);
        }
    }
}
