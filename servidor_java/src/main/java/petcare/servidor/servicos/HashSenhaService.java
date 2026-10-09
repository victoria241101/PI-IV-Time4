package petcare.servidor.servicos;

import com.google.gson.JsonObject;
import petcare.servidor.ClienteHandler;
import petcare.servidor.protocolo.CodigoErro;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 Serviço GERAR_HASH_SENHA.
 Gera hash PBKDF2-HMAC-SHA256 com salt aleatório.
 Formato: pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>
 
 Requisição: {"comando":"GERAR_HASH_SENHA","dados":{"senha":"..."}}
 Resposta:   {"status":"OK","mensagem":"...","dados":{"hash":"pbkdf2$..."}}
 */
public class HashSenhaService {

    private static final String ALGORITMO = "PBKDF2WithHmacSHA256";
    private static final int ITERACOES = 120_000;
    private static final int TAMANHO_SALT = 16; // bytes
    private static final int TAMANHO_HASH = 32; // bytes
    private static final SecureRandom RANDOM = new SecureRandom();

    /** Ponto de entrada chamado pelo ClienteHandler. Nunca loga a senha */
    public static JsonObject gerar(JsonObject dados) {
        if (dados == null || !dados.has("senha") || dados.get("senha").isJsonNull()
                || !dados.get("senha").isJsonPrimitive()
                || !dados.get("senha").getAsJsonPrimitive().isString()) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS,
                    "Campo 'senha' é obrigatório e deve ser uma string.");
        }

        String senha = dados.get("senha").getAsString();
        if (senha.isEmpty()) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Senha vazia.");
        }

        String hash = gerarHash(senha);

        JsonObject resposta = ClienteHandler.respostaOk("Hash gerado com sucesso.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("hash", hash);
        resposta.add("dados", dadosResposta);
        return resposta;
    }

    /** Gera o hash. Lança IllegalArgumentException se a senha for nula ou vazia. */
    public static String gerarHash(String senha) {
        if (senha == null || senha.isEmpty()) {
            throw new IllegalArgumentException("Senha vazia");
        }

        byte[] salt = new byte[TAMANHO_SALT];
        RANDOM.nextBytes(salt);

        byte[] hash = pbkdf2(senha.toCharArray(), salt, ITERACOES, TAMANHO_HASH);

        Base64.Encoder b64 = Base64.getEncoder();
        return "pbkdf2$" + ITERACOES + "$" + b64.encodeToString(salt) + "$" + b64.encodeToString(hash);
    }

    /** Usado só nos testes do Java (o login real é feito no Node) */
    public static boolean verificar(String senha, String hashSalvo) {
        if (senha == null || hashSalvo == null) return false;
        String[] partes = hashSalvo.split("\\$");
        if (partes.length != 4 || !partes[0].equals("pbkdf2")) return false;

        int iteracoes = Integer.parseInt(partes[1]);
        byte[] salt = Base64.getDecoder().decode(partes[2]);
        byte[] esperado = Base64.getDecoder().decode(partes[3]);
        byte[] calculado = pbkdf2(senha.toCharArray(), salt, iteracoes, esperado.length);

        return MessageDigest.isEqual(esperado, calculado); // comparação em tempo constante
    }

    private static byte[] pbkdf2(char[] senha, byte[] salt, int iteracoes, int tamanhoBytes) {
        PBEKeySpec spec = new PBEKeySpec(senha, salt, iteracoes, tamanhoBytes * 8);
        try {
            return SecretKeyFactory.getInstance(ALGORITMO).generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new IllegalStateException("Falha ao gerar hash", e);
        } finally {
            spec.clearPassword();
        }
    }
}