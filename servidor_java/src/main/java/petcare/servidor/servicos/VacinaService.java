package main.java.petcare.servidor.servicos;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import petcare.servidor.ClienteHandler;
import petcare.servidor.protocolo.CodigoErro;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;

/**
 * Serviço CALCULAR_STATUS_VACINA
  Requisição:
    {"comando":"CALCULAR_STATUS_VACINA","dados":{
        "dataUltimaAplicacao":"2026-01-10",   (yyyy-MM-dd; ausente/vazia = vacina PENDENTE)
        "intervaloDias":365,                  (obrigatório quando há aplicação)
        "diasAlerta":30,                      (opcional, padrão 30)
        "dataReferencia":"2026-10-09"         (opcional, padrão hoje)
    }}
 
  Resposta:
    {"status":"OK","mensagem":"...","dados":{
        "statusVacina":"EM_DIA | A_VENCER | ATRASADA | PENDENTE",
        "dataProximaDose":"2027-01-10",
        "diasRestantes":93}}          (negativo se atrasada)
 
  Regras:
    proximaDose = dataUltimaAplicacao + intervaloDias
    diasRestantes = proximaDose - dataReferencia
    diasRestantes < 0            -> ATRASADA
    0 <= diasRestantes <= alerta -> A_VENCER (inclui vencendo hoje)
    diasRestantes > alerta       -> EM_DIA
    sem aplicação registrada     -> PENDENTE (sem dataProximaDose e diasRestantes)
 */
public class VacinaService {

    public static final String EM_DIA = "EM_DIA";
    public static final String A_VENCER = "A_VENCER";
    public static final String ATRASADA = "ATRASADA";
    public static final String PENDENTE = "PENDENTE";

    private static final int DIAS_ALERTA_PADRAO = 30;
    private static final int LIMITE_DIAS = 3650; // 10 anos, evita estouro de data
    private static final ZoneId FUSO = ZoneId.of("America/Sao_Paulo");

    // Ponto de entrada chamado pelo ClienteHandler 
    public static JsonObject calcularStatus(JsonObject dados) {
        if (dados == null) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Campo 'dados' ausente.");
        }

        try {
            LocalDate referencia = lerData(dados, "dataReferencia");
            if (referencia == null) {
                referencia = LocalDate.now(FUSO);
            }

            int diasAlerta = lerInteiro(dados, "diasAlerta", DIAS_ALERTA_PADRAO, 0, LIMITE_DIAS);

            LocalDate ultimaAplicacao = lerData(dados, "dataUltimaAplicacao");
            if (ultimaAplicacao == null) {
                return montarResposta(PENDENTE, null, null);
            }

            int intervaloDias = lerInteiro(dados, "intervaloDias", null, 1, LIMITE_DIAS);

            if (ultimaAplicacao.isAfter(referencia)) {
                throw new IllegalArgumentException("A data da última aplicação não pode ser futura.");
            }

            LocalDate proximaDose = ultimaAplicacao.plusDays(intervaloDias);
            long diasRestantes = ChronoUnit.DAYS.between(referencia, proximaDose);

            String status;
            if (diasRestantes < 0) {
                status = ATRASADA;
            } else if (diasRestantes <= diasAlerta) {
                status = A_VENCER;
            } else {
                status = EM_DIA;
            }

            return montarResposta(status, proximaDose, diasRestantes);

        } catch (IllegalArgumentException e) {
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, e.getMessage());
        }
    }

    // Auxiliares
    private static JsonObject montarResposta(String status, LocalDate proximaDose, Long diasRestantes) {
        JsonObject resposta = ClienteHandler.respostaOk("Status da vacina calculado.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("statusVacina", status);
        if (proximaDose != null) {
            dadosResposta.addProperty("dataProximaDose", proximaDose.toString()); // yyyy-MM-dd
            dadosResposta.addProperty("diasRestantes", diasRestantes);
        }
        resposta.add("dados", dadosResposta);
        return resposta;
    }

    // Lê uma data yyyy-MM-dd. Retorna null se o campo estiver ausente, nulo ou vazio
    private static LocalDate lerData(JsonObject dados, String campo) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            return null;
        }
        JsonElement el = dados.get(campo);
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isString()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser uma string no formato yyyy-MM-dd.");
        }
        String texto = el.getAsString().trim();
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(texto); // ISO estrito: rejeita 2026-02-30
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException(
                    "Campo '" + campo + "' deve ser uma data válida no formato yyyy-MM-dd.");
        }
    }

    // Lê um inteiro no intervalo [min, max]. Se ausente: usa o padrão, ou erro quando padrao == null
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
            valor = numero.intValueExact(); // rejeita 30.5 e números gigantes
        } catch (ArithmeticException e) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro.");
        }
        if (valor < min || valor > max) {
            throw new IllegalArgumentException(
                    "Campo '" + campo + "' deve estar entre " + min + " e " + max + ".");
        }
        return valor;
    }
}