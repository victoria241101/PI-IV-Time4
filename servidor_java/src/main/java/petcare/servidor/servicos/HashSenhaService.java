// Alinne Monteiro de Melo | RA: 24801649

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
 serviço gerar_hash_senha.
 gera hash pbkdf2-hmac-sha256 com salt aleatório.
 formato: pbkdf2$<iteracoes>$<saltbase64>$<hashbase64>
 
 requisição: {"comando":"gerar_hash_senha","dados":{"senha":"..."}}
 resposta:   {"status":"ok","mensagem":"...","dados":{"hash":"pbkdf2$..."}}
 */
public class HashSenhaService {

    // define o algoritmo usado na criação e na conferência do hash
    private static final String ALGORITMO = "PBKDF2WithHmacSHA256";
    // repete o cálculo para aumentar o custo de cada tentativa de senha
    private static final int ITERACOES = 120_000;
    private static final int TAMANHO_SALT = 16; // bytes
    private static final int TAMANHO_HASH = 32; // bytes
    // usa um gerador seguro para criar os bytes aleatórios do salt
    private static final SecureRandom RANDOM = new SecureRandom();

    /** ponto de entrada chamado pelo clientehandler. nunca loga a senha */
    // recebe a senha pelo json e devolve apenas o hash no campo dados
    public static JsonObject gerar(JsonObject dados) {
        // confere se existe uma senha em formato de texto antes de ler o valor
        if (dados == null || !dados.has("senha") || dados.get("senha").isJsonNull()
                || !dados.get("senha").isJsonPrimitive()
                || !dados.get("senha").getAsJsonPrimitive().isString()) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS,
                    "Campo 'senha' é obrigatório e deve ser uma string.");
        }

        String senha = dados.get("senha").getAsString();
        // rejeita texto vazio mesmo quando o campo é uma string válida
        if (senha.isEmpty()) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Senha vazia.");
        }

        String hash = gerarHash(senha);

        // monta o json de sucesso com o hash que será guardado pelo sistema
        JsonObject resposta = ClienteHandler.respostaOk("Hash gerado com sucesso.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("hash", hash);
        resposta.add("dados", dadosResposta);
        return resposta;
    }

    /** gera o hash. lança illegalargumentexception se a senha for nula ou vazia. */
    public static String gerarHash(String senha) {
        if (senha == null || senha.isEmpty()) {
            throw new IllegalArgumentException("Senha vazia");
        }

        // cria um salt novo para que duas senhas iguais possam gerar hashes diferentes
        byte[] salt = new byte[TAMANHO_SALT];
        RANDOM.nextBytes(salt);

        // usa a senha, o salt e o número de iterações para calcular os bytes do hash
        byte[] hash = pbkdf2(senha.toCharArray(), salt, ITERACOES, TAMANHO_HASH);

        // converte o salt e o hash para texto e salva os parâmetros junto com o resultado
        Base64.Encoder b64 = Base64.getEncoder();
        return "pbkdf2$" + ITERACOES + "$" + b64.encodeToString(salt) + "$" + b64.encodeToString(hash);
    }

    // compara a senha informada com o hash salvo
    public static boolean verificar(String senha, String hashSalvo) {
        if (senha == null || hashSalvo == null) return false;
        // separa o texto salvo em algoritmo, iterações, salt e hash
        String[] partes = hashSalvo.split("\\$");
        // confere se o texto tem as quatro partes esperadas e usa o formato certo
        if (partes.length != 4 || !partes[0].equals("pbkdf2")) return false;

        // recupera os parâmetros usados quando o hash foi criado
        int iteracoes = Integer.parseInt(partes[1]);
        byte[] salt = Base64.getDecoder().decode(partes[2]);
        byte[] esperado = Base64.getDecoder().decode(partes[3]);
        // calcula um novo hash com a senha recebida e os parâmetros recuperados
        byte[] calculado = pbkdf2(senha.toCharArray(), salt, iteracoes, esperado.length);

        return MessageDigest.isEqual(esperado, calculado); // comparação em tempo constante
    }

    // recebe senha e hash pelo json e devolve o resultado da conferência
    public static JsonObject verificar(JsonObject dados) {
    JsonObject resposta = new JsonObject();

    // valida se os dois campos existem e são textos
    if (
        dados == null ||
        !dados.has("senha") ||
        !dados.get("senha").isJsonPrimitive() ||
        !dados.get("senha").getAsJsonPrimitive().isString() ||
        !dados.has("hash") ||
        !dados.get("hash").isJsonPrimitive() ||
        !dados.get("hash").getAsJsonPrimitive().isString()
    ) {
        resposta.addProperty("status", "ERRO");
        resposta.addProperty("codigo", "DADOS_INVALIDOS");
        resposta.addProperty("mensagem", "Senha ou hash inválido.");
        return resposta;
    }

    // lê os valores depois de validar os tipos
    String senha = dados.get("senha").getAsString();
    String hash = dados.get("hash").getAsString();

    boolean senhaCorreta;

    // chama a versão que compara a senha com o hash salvo
    try {
        senhaCorreta = verificar(senha, hash);
    // trata formatos que falham na leitura das iterações ou na conversão dos dados
    } catch (RuntimeException e) {
        resposta.addProperty("status", "ERRO");
        resposta.addProperty("codigo", "DADOS_INVALIDOS");
        resposta.addProperty("mensagem", "Não foi possível verificar a senha.");
        return resposta;
    }

    // a verificação pode terminar com sucesso mesmo quando a senha está incorreta
    resposta.addProperty("status", "OK");
    resposta.addProperty("mensagem", "Verificação de senha concluída.");

    // coloca em dados.valida o resultado da comparação
    JsonObject resultado = new JsonObject();
    resultado.addProperty("valida", senhaCorreta);

    resposta.add("dados", resultado);

    return resposta;
}

    private static byte[] pbkdf2(char[] senha, byte[] salt, int iteracoes, int tamanhoBytes) {
        // o tamanho chega em bytes, mas a configuração da chave espera bits
        PBEKeySpec spec = new PBEKeySpec(senha, salt, iteracoes, tamanhoBytes * 8);
        try {
            // gera a chave derivada e devolve os bytes que serão usados como hash
            return SecretKeyFactory.getInstance(ALGORITMO).generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            // trata a falha do algoritmo como erro interno do serviço
            throw new IllegalStateException("Falha ao gerar hash", e);
        } finally {
            // limpa a senha guardada na configuração mesmo se o cálculo falhar
            spec.clearPassword();
        }
    }
}