package petcare.servidor.servicos;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import petcare.servidor.ClienteHandler;
import petcare.servidor.protocolo.CodigoErro;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Serviço responsável por calcular o progresso de arrecadação de uma campanha.
 * 
 * Lógica pura de cálculo isolada de sockets e de JSON/Gson para permitir
 * testes unitários independentes e determinísticos.
 */
public class ProgressoCampanhaService {

    public static final BigDecimal CEM = new BigDecimal("100");
    public static final BigDecimal CEM_PONTO_ZERO = new BigDecimal("100.0");
    public static final BigDecimal OITENTA = new BigDecimal("80");
    public static final BigDecimal ZERO = BigDecimal.ZERO;
    public static final BigDecimal ZERO_PONTO_ZERO_ZERO = new BigDecimal("0.00");
    public static final BigDecimal TETO = new BigDecimal("1000000000000");

    public static final String STATUS_SEM_DOACOES = "SEM_DOACOES";
    public static final String STATUS_META_ATINGIDA = "META_ATINGIDA";
    public static final String STATUS_QUASE_LA = "QUASE_LA";
    public static final String STATUS_EM_ANDAMENTO = "EM_ANDAMENTO";

    /**
     * Resultado puro do cálculo de progresso de campanha.
     */
    public static class ResultadoProgresso {
        private final BigDecimal porcentagem;
        private final BigDecimal porcentagemExibicao;
        private final BigDecimal valorRestante;
        private final String statusProgresso;

        public ResultadoProgresso(BigDecimal porcentagem, BigDecimal porcentagemExibicao,
                                 BigDecimal valorRestante, String statusProgresso) {
            this.porcentagem = porcentagem;
            this.porcentagemExibicao = porcentagemExibicao;
            this.valorRestante = valorRestante;
            this.statusProgresso = statusProgresso;
        }

        public BigDecimal getPorcentagem() {
            return porcentagem;
        }

        public BigDecimal getPorcentagemExibicao() {
            return porcentagemExibicao;
        }

        public BigDecimal getValorRestante() {
            return valorRestante;
        }

        public String getStatusProgresso() {
            return statusProgresso;
        }
    }

    /**
     * Ponto de entrada chamado pelo ClienteHandler.
     * Valida os campos da requisição JSON e delega para o cálculo puro.
     *
     * @param dados JsonObject contendo os dados da requisição
     * @return JsonObject com a resposta formatada no protocolo PetCare
     */
    public static JsonObject calcularProgresso(JsonObject dados) {
        if (dados == null) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Campo 'dados' ausente.");
        }

        try {
            BigDecimal valorArrecadado = lerValorArrecadado(dados);
            BigDecimal metaValor = lerMetaValor(dados);

            ResultadoProgresso resultado = calcular(valorArrecadado, metaValor);

            return montarResposta(resultado);

        } catch (IllegalArgumentException e) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, e.getMessage());
        } catch (Exception e) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Dados inválidos: " + e.getMessage());
        }
    }

    /**
     * Lógica pura de cálculo do progresso da campanha em BigDecimal.
     * Não utiliza Gson e nem manipula sockets.
     *
     * @param valorArrecadado Valor total arrecadado (>= 0 e <= 10^12)
     * @param metaValor Meta financeira da campanha (> 0 e <= 10^12)
     * @return ResultadoProgresso contendo os valores calculados
     */
    public static ResultadoProgresso calcular(BigDecimal valorArrecadado, BigDecimal metaValor) {
        if (valorArrecadado == null) {
            throw new IllegalArgumentException("Campo 'valorArrecadado' é obrigatório.");
        }
        if (metaValor == null) {
            throw new IllegalArgumentException("Campo 'metaValor' é obrigatório.");
        }
        if (valorArrecadado.compareTo(ZERO) < 0) {
            throw new IllegalArgumentException("Campo 'valorArrecadado' deve ser maior ou igual a 0.");
        }
        if (metaValor.compareTo(ZERO) <= 0) {
            throw new IllegalArgumentException("Campo 'metaValor' deve ser estritamente maior que 0.");
        }
        if (valorArrecadado.compareTo(TETO) > 0) {
            throw new IllegalArgumentException("Campo 'valorArrecadado' deve ser menor ou igual a " + TETO.toPlainString() + ".");
        }
        if (metaValor.compareTo(TETO) > 0) {
            throw new IllegalArgumentException("Campo 'metaValor' deve ser menor ou igual a " + TETO.toPlainString() + ".");
        }

        // porcentagem = valorArrecadado * 100 / metaValor com 1 casa decimal e RoundingMode.DOWN
        BigDecimal porcentagem = valorArrecadado.multiply(CEM).divide(metaValor, 1, RoundingMode.DOWN);

        // porcentagemExibicao = min(porcentagem, 100.0) com 1 casa decimal
        BigDecimal porcentagemExibicao = porcentagem.compareTo(CEM_PONTO_ZERO) > 0 ? CEM_PONTO_ZERO : porcentagem;

        // valorRestante = metaValor - valorArrecadado, nunca menor que zero, com 2 casas decimais e RoundingMode.UP
        BigDecimal diferenca = metaValor.subtract(valorArrecadado);
        BigDecimal valorRestante;
        if (diferenca.compareTo(ZERO) <= 0) {
            valorRestante = ZERO_PONTO_ZERO_ZERO;
        } else {
            valorRestante = diferenca.setScale(2, RoundingMode.UP);
        }

        // statusProgresso usando comparacoes exatas com os valores originais
        String statusProgresso;
        if (valorArrecadado.compareTo(ZERO) == 0) {
            statusProgresso = STATUS_SEM_DOACOES;
        } else if (valorArrecadado.compareTo(metaValor) >= 0) {
            statusProgresso = STATUS_META_ATINGIDA;
        } else if (valorArrecadado.multiply(CEM).compareTo(metaValor.multiply(OITENTA)) >= 0) {
            statusProgresso = STATUS_QUASE_LA;
        } else {
            statusProgresso = STATUS_EM_ANDAMENTO;
        }

        return new ResultadoProgresso(porcentagem, porcentagemExibicao, valorRestante, statusProgresso);
    }

    // =========================================================================
    // MÉTODOS AUXILIARES DE MONTAGEM E VALIDAÇÃO JSON
    // =========================================================================

    private static JsonObject montarResposta(ResultadoProgresso resultado) {
        JsonObject resposta = ClienteHandler.respostaOk("Progresso da campanha calculado com sucesso.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("porcentagem", resultado.getPorcentagem());
        dadosResposta.addProperty("porcentagemExibicao", resultado.getPorcentagemExibicao());
        dadosResposta.addProperty("valorRestante", resultado.getValorRestante());
        dadosResposta.addProperty("statusProgresso", resultado.getStatusProgresso());
        resposta.add("dados", dadosResposta);
        return resposta;
    }

    private static BigDecimal lerValorArrecadado(JsonObject dados) {
        return lerNumero(dados, "valorArrecadado", ZERO, TETO, false);
    }

    private static BigDecimal lerMetaValor(JsonObject dados) {
        return lerNumero(dados, "metaValor", ZERO, TETO, true);
    }

    private static BigDecimal lerNumero(JsonObject dados, String campo, BigDecimal min, BigDecimal max, boolean estritamenteMaiorQueMin) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            throw new IllegalArgumentException("Campo '" + campo + "' é obrigatório.");
        }
        JsonElement el = dados.get(campo);
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isNumber()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número.");
        }
        BigDecimal valor;
        try {
            valor = el.getAsBigDecimal();
        } catch (Exception e) {
            throw new IllegalArgumentException("Campo '" + campo + "' contém um número inválido.");
        }

        if (estritamenteMaiorQueMin) {
            if (valor.compareTo(min) <= 0) {
                throw new IllegalArgumentException("Campo '" + campo + "' deve ser estritamente maior que " + min.toPlainString() + ".");
            }
        } else {
            if (valor.compareTo(min) < 0) {
                throw new IllegalArgumentException("Campo '" + campo + "' deve ser maior ou igual a " + min.toPlainString() + ".");
            }
        }

        if (max != null && valor.compareTo(max) > 0) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser menor ou igual a " + max.toPlainString() + ".");
        }

        return valor;
    }
}
