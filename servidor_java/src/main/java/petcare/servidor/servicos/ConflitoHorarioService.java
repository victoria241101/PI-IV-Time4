package petcare.servidor.servicos;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import petcare.servidor.ClienteHandler;
import petcare.servidor.protocolo.CodigoErro;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Serviço responsável por verificar conflitos de horário de agendamentos
 * e sugerir horários alternativos quando houver colisão.
 * 
 * Lógica pura de cálculo isolada de sockets e de JSON/Gson para permitir
 * testes unitários independentes.
 */
public class ConflitoHorarioService {

    private static final DateTimeFormatter FORMATADOR_ISO = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    /**
     * Representa um intervalo semiaberto [inicio, fim).
     */
    public static class Intervalo {
        private final LocalDateTime inicio;
        private final LocalDateTime fim;

        public Intervalo(LocalDateTime inicio, LocalDateTime fim) {
            if (inicio == null || fim == null) {
                throw new IllegalArgumentException("Início e fim do intervalo não podem ser nulos.");
            }
            if (!inicio.isBefore(fim)) {
                throw new IllegalArgumentException("Início deve ser estritamente anterior ao fim.");
            }
            this.inicio = inicio;
            this.fim = fim;
        }

        public LocalDateTime getInicio() {
            return inicio;
        }

        public LocalDateTime getFim() {
            return fim;
        }
    }

    /**
     * Resultado puro do cálculo de verificação de conflito e sugestões.
     */
    public static class ResultadoConflito {
        private final boolean conflito;
        private final List<LocalDateTime> sugestoes;

        public ResultadoConflito(boolean conflito, List<LocalDateTime> sugestoes) {
            this.conflito = conflito;
            this.sugestoes = sugestoes != null ? sugestoes : Collections.emptyList();
        }

        public boolean isConflito() {
            return conflito;
        }

        public List<LocalDateTime> getSugestoes() {
            return sugestoes;
        }
    }

    /**
     * Janela diária de atendimento da clínica [inicio, fim).
     */
    public static class JanelaAtendimento {
        private final LocalTime inicio;
        private final LocalTime fim;

        public JanelaAtendimento(LocalTime inicio, LocalTime fim) {
            if (inicio == null || fim == null) {
                throw new IllegalArgumentException("Início e fim da janela não podem ser nulos.");
            }
            if (!inicio.isBefore(fim)) {
                throw new IllegalArgumentException("Início da janela deve ser estritamente anterior ao fim.");
            }
            this.inicio = inicio;
            this.fim = fim;
        }

        public LocalTime getInicio() {
            return inicio;
        }

        public LocalTime getFim() {
            return fim;
        }
    }

    /**
     * Ponto de entrada chamado pelo ClienteHandler.
     * Realiza a validação da requisição JSON e delega para o cálculo puro.
     *
     * @param dados JsonObject contendo os dados da requisição
     * @return JsonObject com a resposta formatada no protocolo PetCare
     */
    public static JsonObject verificarConflito(JsonObject dados) {
        if (dados == null) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Campo 'dados' ausente.");
        }

        try {
            LocalDateTime dataHora = lerDataHora(dados, "dataHora");
            int duracaoMinutos = lerInteiro(dados, "duracaoMinutos", null, 1, 1440);
            List<Intervalo> ocupados = lerOcupados(dados);
            JanelaAtendimento janela = lerJanela(dados);
            int passoMinutos = lerInteiro(dados, "passoMinutos", 30, 1, 1440);
            int maxSugestoes = lerInteiro(dados, "maxSugestoes", 3, 0, 50);

            ResultadoConflito resultado = calcular(
                    dataHora,
                    duracaoMinutos,
                    ocupados,
                    janela.getInicio(),
                    janela.getFim(),
                    passoMinutos,
                    maxSugestoes
            );

            return montarResposta(resultado);

        } catch (IllegalArgumentException e) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, e.getMessage());
        }
    }

    /**
     * Lógica pura de cálculo de sobreposição e geração de sugestões.
     * Não utiliza Gson e nem manipula sockets.
     *
     * @param dataHora Início do horário solicitado
     * @param duracaoMinutos Duração do horário solicitado em minutos
     * @param ocupados Lista de intervalos já ocupados
     * @param janelaInicio Início da janela de funcionamento da clínica
     * @param janelaFim Fim da janela de funcionamento da clínica
     * @param passoMinutos Passo da grade de sugestões em minutos
     * @param maxSugestoes Quantidade máxima de sugestões a retornar
     * @return Objeto ResultadoConflito contendo o booleano de conflito e as sugestões ordenadas
     */
    public static ResultadoConflito calcular(
            LocalDateTime dataHora,
            int duracaoMinutos,
            List<Intervalo> ocupados,
            LocalTime janelaInicio,
            LocalTime janelaFim,
            int passoMinutos,
            int maxSugestoes) {

        if (dataHora == null) {
            throw new IllegalArgumentException("Campo 'dataHora' não pode ser nulo.");
        }
        if (duracaoMinutos < 1 || duracaoMinutos > 1440) {
            throw new IllegalArgumentException("Campo 'duracaoMinutos' deve estar entre 1 e 1440.");
        }
        if (janelaInicio == null || janelaFim == null) {
            throw new IllegalArgumentException("Janela de atendimento não pode ser nula.");
        }
        if (!janelaInicio.isBefore(janelaFim)) {
            throw new IllegalArgumentException("Início da janela deve ser estritamente anterior ao fim.");
        }
        if (passoMinutos < 1 || passoMinutos > 1440) {
            throw new IllegalArgumentException("Campo 'passoMinutos' deve estar entre 1 e 1440.");
        }
        if (maxSugestoes < 0 || maxSugestoes > 50) {
            throw new IllegalArgumentException("Campo 'maxSugestoes' deve estar entre 0 e 50.");
        }

        LocalDateTime novoFim = dataHora.plusMinutes(duracaoMinutos);

        // 1. Verificação de conflito: novoInicio < ocupadoFim && ocupadoInicio < novoFim
        // A janela NÃO é usada para decidir conflito
        boolean conflito = false;
        if (ocupados != null) {
            for (Intervalo ocupado : ocupados) {
                if (dataHora.isBefore(ocupado.getFim()) && ocupado.getInicio().isBefore(novoFim)) {
                    conflito = true;
                    break;
                }
            }
        }

        // Sugestões só são calculadas quando conflito é true. Sem conflito ou se maxSugestoes == 0, retorna vazio
        if (!conflito || maxSugestoes == 0) {
            return new ResultadoConflito(conflito, Collections.emptyList());
        }

        // 2. Grade de candidatos na mesma data de dataHora
        LocalDate data = dataHora.toLocalDate();
        LocalDateTime gradeInicio = LocalDateTime.of(data, janelaInicio);
        LocalDateTime gradeFim = LocalDateTime.of(data, janelaFim);

        List<LocalDateTime> candidatosValidos = new ArrayList<>();
        LocalDateTime c = gradeInicio;

        // Avança de passoMinutos em passoMinutos enquanto o intervalo inteiro couber na janela
        while (!c.plusMinutes(duracaoMinutos).isAfter(gradeFim)) {
            LocalDateTime cFim = c.plusMinutes(duracaoMinutos);
            boolean sobreposicao = false;

            if (ocupados != null) {
                for (Intervalo ocupado : ocupados) {
                    if (c.isBefore(ocupado.getFim()) && ocupado.getInicio().isBefore(cFim)) {
                        sobreposicao = true;
                        break;
                    }
                }
            }

            if (!sobreposicao) {
                candidatosValidos.add(c);
            }

            c = c.plusMinutes(passoMinutos);
        }

        // 3. Ordenação: por proximidade de dataHora (menor diferença absoluta em minutos);
        // em empate, o horário mais cedo primeiro
        candidatosValidos.sort((c1, c2) -> {
            long diff1 = Math.abs(Duration.between(dataHora, c1).toMinutes());
            long diff2 = Math.abs(Duration.between(dataHora, c2).toMinutes());
            if (diff1 != diff2) {
                return Long.compare(diff1, diff2);
            }
            return c1.compareTo(c2);
        });

        // 4. Limitação ao máximo de sugestões
        List<LocalDateTime> sugestoesFinal;
        if (candidatosValidos.size() > maxSugestoes) {
            sugestoesFinal = new ArrayList<>(candidatosValidos.subList(0, maxSugestoes));
        } else {
            sugestoesFinal = candidatosValidos;
        }

        return new ResultadoConflito(true, sugestoesFinal);
    }

    // =========================================================================
    // MÉTODOS AUXILIARES DE MONTAGEM E VALIDAÇÃO JSON
    // =========================================================================

    private static JsonObject montarResposta(ResultadoConflito resultado) {
        JsonObject resposta = ClienteHandler.respostaOk("Verificação de conflito de horário concluída.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("conflito", resultado.isConflito());

        JsonArray sugestoesArray = new JsonArray();
        for (LocalDateTime sugestao : resultado.getSugestoes()) {
            sugestoesArray.add(sugestao.format(FORMATADOR_ISO));
        }
        dadosResposta.add("sugestoes", sugestoesArray);

        resposta.add("dados", dadosResposta);
        return resposta;
    }

    private static LocalDateTime lerDataHora(JsonObject dados, String campo) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            throw new IllegalArgumentException("Campo '" + campo + "' é obrigatório.");
        }
        return lerDataHoraElemento(dados.get(campo), campo);
    }

    private static LocalDateTime lerDataHoraElemento(JsonElement el, String campo) {
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isString()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser uma string no formato ISO sem fuso.");
        }
        String texto = el.getAsString().trim();
        if (texto.isEmpty()) {
            throw new IllegalArgumentException("Campo '" + campo + "' não pode ser vazio.");
        }
        if (texto.endsWith("Z") || texto.endsWith("z") || texto.contains("+")
                || (texto.indexOf('T') != -1 && texto.lastIndexOf('-') > texto.indexOf('T'))) {
            throw new IllegalArgumentException("Campo '" + campo + "' não deve conter fuso horário ou deslocamento.");
        }
        try {
            return LocalDateTime.parse(texto);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser uma data e hora válida no formato ISO sem fuso (ex: 2026-10-20T14:00:00).");
        }
    }

    private static int lerInteiro(JsonObject dados, String campo, Integer padrao, int min, int max) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            if (padrao == null) {
                throw new IllegalArgumentException("Campo '" + campo + "' é obrigatório.");
            }
            return padrao;
        }
        JsonElement el = dados.get(campo);
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isNumber()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro.");
        }
        int valor;
        try {
            BigDecimal numero = el.getAsBigDecimal();
            valor = numero.intValueExact();
        } catch (ArithmeticException e) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro.");
        }
        if (valor < min || valor > max) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro entre " + min + " e " + max + ".");
        }
        return valor;
    }

    private static List<Intervalo> lerOcupados(JsonObject dados) {
        if (!dados.has("ocupados") || dados.get("ocupados").isJsonNull()) {
            throw new IllegalArgumentException("Campo 'ocupados' é obrigatório.");
        }
        JsonElement el = dados.get("ocupados");
        if (!el.isJsonArray()) {
            throw new IllegalArgumentException("Campo 'ocupados' deve ser uma lista.");
        }
        JsonArray array = el.getAsJsonArray();
        List<Intervalo> lista = new ArrayList<>();
        for (int i = 0; i < array.size(); i++) {
            JsonElement itemEl = array.get(i);
            if (!itemEl.isJsonObject()) {
                throw new IllegalArgumentException("Item " + i + " de 'ocupados' deve ser um objeto.");
            }
            JsonObject itemObj = itemEl.getAsJsonObject();
            if (!itemObj.has("inicio") || itemObj.get("inicio").isJsonNull()) {
                throw new IllegalArgumentException("Item " + i + " de 'ocupados' deve conter o campo 'inicio'.");
            }
            if (!itemObj.has("fim") || itemObj.get("fim").isJsonNull()) {
                throw new IllegalArgumentException("Item " + i + " de 'ocupados' deve conter o campo 'fim'.");
            }

            LocalDateTime inicio = lerDataHoraElemento(itemObj.get("inicio"), "Item " + i + " de 'ocupados' (inicio)");
            LocalDateTime fim = lerDataHoraElemento(itemObj.get("fim"), "Item " + i + " de 'ocupados' (fim)");

            if (!inicio.isBefore(fim)) {
                throw new IllegalArgumentException("Item " + i + " de 'ocupados' deve ter 'inicio' estritamente anterior a 'fim'.");
            }

            lista.add(new Intervalo(inicio, fim));
        }
        return lista;
    }

    private static JanelaAtendimento lerJanela(JsonObject dados) {
        if (!dados.has("janela") || dados.get("janela").isJsonNull()) {
            throw new IllegalArgumentException("Campo 'janela' é obrigatório.");
        }
        JsonElement el = dados.get("janela");
        if (!el.isJsonObject()) {
            throw new IllegalArgumentException("Campo 'janela' deve ser um objeto.");
        }
        JsonObject obj = el.getAsJsonObject();
        if (!obj.has("inicio") || obj.get("inicio").isJsonNull()) {
            throw new IllegalArgumentException("Campo 'janela.inicio' é obrigatório.");
        }
        if (!obj.has("fim") || obj.get("fim").isJsonNull()) {
            throw new IllegalArgumentException("Campo 'janela.fim' é obrigatório.");
        }
        LocalTime inicio = lerHora(obj.get("inicio"), "janela.inicio");
        LocalTime fim = lerHora(obj.get("fim"), "janela.fim");
        if (!inicio.isBefore(fim)) {
            throw new IllegalArgumentException("Campo 'janela' deve ter 'inicio' estritamente anterior a 'fim'.");
        }
        return new JanelaAtendimento(inicio, fim);
    }

    private static LocalTime lerHora(JsonElement el, String campo) {
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isString()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser uma string no formato HH:mm.");
        }
        String texto = el.getAsString().trim();
        if (texto.isEmpty()) {
            throw new IllegalArgumentException("Campo '" + campo + "' não pode ser vazio.");
        }
        try {
            return LocalTime.parse(texto);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve estar no formato HH:mm.");
        }
    }
}
