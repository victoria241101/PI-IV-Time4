package main.java.petcare.servidor.servicos;

import java.nio.charset.StandardCharsets;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/*
Serviço GERAR_HASH_SENHA
Gera hash PBKDF2-HMAC-SHA256 com salt aleatório.
Formato: pbkdf2$<iteracoes>$<saltBase64>$<hashBase64>
*/
public class HashSenhaService {

    private static final String ALGORITMO = "PBKDF2WithHmacSHA256";
    private static final int ITERACOES = 120_000;
    private static final int TAMANHO_SALT = 16;   // bytes
    private static final int TAMANHO_HASH = 32;   // bytes
    private static final SecureRandom RANDOM = new SecureRandom();

    /** Gera o hash da senha. Lança IllegalArgumentException se a senha for nula ou vazia. */
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

    /** Usado só nos testes do Java (o login real é feito no Node). */
    public static boolean verificar(String senha, String hashSalvo) {
        if (senha == null || hashSalvo == null) return false;
        String[] partes = hashSalvo.split("\\$");
        if (partes.length != 4 || !partes[0].equals("pbkdf2")) return false;

        int iteracoes = Integer.parseInt(partes[1]);
        byte[] salt = Base64.getDecoder().decode(partes[2]);
        byte[] esperado = Base64.getDecoder().decode(partes[3]);
        byte[] calculado = pbkdf2(senha.toCharArray(), salt, iteracoes, esperado.length);

        return java.security.MessageDigest.isEqual(esperado, calculado); // tempo constante
    }

    private static byte[] pbkdf2(char[] senha, byte[] salt, int iteracoes, int tamanhoBytes) {
        PBEKeySpec spec = new PBEKeySpec(senha, salt, iteracoes, tamanhoBytes * 8);
        try {
            return SecretKeyFactory.getInstance(ALGORITMO).generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new IllegalStateException("Falha ao gerar hash", e);
        } finally {
            spec.clearPassword(); // limpa a senha da memória
        }
    }

    /**
     Trata o comando do protocolo.
     Entrada: Base64 da senha (UTF-8). Saída: linha de resposta ("OK|hash=..." ou "ERRO|mensagem=...").
     */
    public static String executar(String senhaBase64) {
        try {
            if (senhaBase64 == null || senhaBase64.isEmpty()) {
                return "ERRO|mensagem=Senha vazia";
            }
            String senha = new String(Base64.getDecoder().decode(senhaBase64), StandardCharsets.UTF_8);
            return "OK|hash=" + gerarHash(senha);
        } catch (IllegalArgumentException e) {
            return "ERRO|mensagem=" + e.getMessage();
        } catch (Exception e) {
            return "ERRO|mensagem=Falha ao gerar hash";
        }
    }
}