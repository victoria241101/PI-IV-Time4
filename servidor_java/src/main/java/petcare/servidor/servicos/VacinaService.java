// Alinne Monteiro de Melo | RA: 24801649

package petcare.servidor.servicos;

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
 * serviço calcular_status_vacina
  requisição:
    {"comando":"calcular_status_vacina","dados":{
        "dataultimaaplicacao":"2026-01-10",   (yyyy-mm-dd; ausente/vazia = vacina pendente)
        "intervalodias":365,                  (obrigatório quando há aplicação)
        "diasalerta":30,                      (opcional, padrão 30)
        "datareferencia":"2026-10-09"         (opcional, padrão hoje)
    }}
 
  resposta:
    {"status":"ok","mensagem":"...","dados":{
        "statusvacina":"em_dia | a_vencer | atrasada | pendente",
        "dataproximadose":"2027-01-10",
        "diasrestantes":93}}          (negativo se atrasada)
 
  regras:
    proximadose = dataultimaaplicacao + intervalodias
    diasrestantes = proximadose - datareferencia
    diasrestantes < 0            -> atrasada
    0 <= diasrestantes <= alerta -> a_vencer (inclui vencendo hoje)
    diasrestantes > alerta       -> em_dia
    sem aplicação registrada     -> pendente (sem dataproximadose e diasrestantes)
 */
public class VacinaService {

    // define os quatro estados que podem aparecer na resposta
    public static final String EM_DIA = "EM_DIA";
    public static final String A_VENCER = "A_VENCER";
    public static final String ATRASADA = "ATRASADA";
    public static final String PENDENTE = "PENDENTE";

    // usa 30 dias de alerta quando o cliente não informa esse campo
    private static final int DIAS_ALERTA_PADRAO = 30;
    private static final int LIMITE_DIAS = 3650; // 10 anos, evita estouro de data
    // usa o horário de são paulo para descobrir a data de hoje
    private static final ZoneId FUSO = ZoneId.of("America/Sao_Paulo");

    // ponto de entrada chamado pelo clientehandler 
    public static JsonObject calcularStatus(JsonObject dados) {
        System.out.println("[VacinaService] Iniciando cálculo de status de vacina...");

        // sem o objeto de dados, não tem como processar a requisição
        if (dados == null) {
            System.err.println("[VacinaService] Erro de validação: campo 'dados' ausente.");
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, "Campo 'dados' ausente.");
        }

        try {
            // a data de referência é o dia usado para calcular se a dose venceu
            LocalDate referencia = lerData(dados, "dataReferencia");
            if (referencia == null) {
                // se não veio uma data de referência, usa a data de hoje
                referencia = LocalDate.now(FUSO);
            }

            // o alerta aceita zero para sinalizar só no dia do vencimento
            int diasAlerta = lerInteiro(dados, "diasAlerta", DIAS_ALERTA_PADRAO, 0, LIMITE_DIAS);

            // sem aplicação registrada, a vacina fica pendente e não tem próxima dose calculada
            LocalDate ultimaAplicacao = lerData(dados, "dataUltimaAplicacao");
            System.out.println("[VacinaService] Parâmetros validados: dataReferencia=" + referencia
                    + ", diasAlerta=" + diasAlerta
                    + ", dataUltimaAplicacao=" + (ultimaAplicacao != null ? ultimaAplicacao : "não informada"));

            if (ultimaAplicacao == null) {
                System.out.println("[VacinaService] Nenhuma aplicação anterior registrada. Status definido como: " + PENDENTE);
                return montarResposta(PENDENTE, null, null);
            }

            // só exige o intervalo quando existe uma aplicação anterior
            int intervaloDias = lerInteiro(dados, "intervaloDias", null, 1, LIMITE_DIAS);
            System.out.println("[VacinaService] Calculando próxima dose com intervaloDias=" + intervaloDias + "...");

            // impede que uma aplicação futura seja tratada como uma dose já tomada
            if (ultimaAplicacao.isAfter(referencia)) {
                throw new IllegalArgumentException("A data da última aplicação não pode ser futura.");
            }

            // soma o intervalo à última aplicação para achar a data da próxima dose
            LocalDate proximaDose = ultimaAplicacao.plusDays(intervaloDias);
            // conta os dias da referência até a próxima dose, com sinal negativo se já passou
            long diasRestantes = ChronoUnit.DAYS.between(referencia, proximaDose);

            String status;
            // se a próxima dose já passou, marca como atrasada
            if (diasRestantes < 0) {
                status = ATRASADA;
            } else if (diasRestantes <= diasAlerta) {
                // entra no período de alerta quando faltam poucos dias ou vence hoje
                status = A_VENCER;
            } else {
                // se ainda faltam mais dias do que o alerta, a vacina está em dia
                status = EM_DIA;
            }

            System.out.println("[VacinaService] Cálculo concluído -> statusVacina=" + status
                    + ", dataProximaDose=" + proximaDose + ", diasRestantes=" + diasRestantes);

            return montarResposta(status, proximaDose, diasRestantes);

        } catch (IllegalArgumentException e) {
            // devolve a mensagem da validação como erro de dados inválidos
            System.err.println("[VacinaService] Falha na validação dos dados: " + e.getMessage());
            return ClienteHandler.respostaErro(CodigoErro.DADOS_INVALIDOS, e.getMessage());
        }
    }

    // auxiliares
    private static JsonObject montarResposta(String status, LocalDate proximaDose, Long diasRestantes) {
        // monta a resposta de sucesso e coloca o estado da vacina dentro de dados
        JsonObject resposta = ClienteHandler.respostaOk("Status da vacina calculado.");
        JsonObject dadosResposta = new JsonObject();
        dadosResposta.addProperty("statusVacina", status);
        // só inclui a próxima data e os dias restantes quando existe uma dose calculada
        if (proximaDose != null) {
            dadosResposta.addProperty("dataProximaDose", proximaDose.toString()); // yyyy-mm-dd
            dadosResposta.addProperty("diasRestantes", diasRestantes);
        }
        resposta.add("dados", dadosResposta);
        return resposta;
    }

    // lê uma data yyyy-mm-dd. retorna null se o campo estiver ausente, nulo ou vazio
    private static LocalDate lerData(JsonObject dados, String campo) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            return null;
        }
        JsonElement el = dados.get(campo);
        // verifica se o campo é texto antes de tentar converter a data
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isString()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser uma string no formato yyyy-MM-dd.");
        }
        // remove espaços das pontas e trata texto vazio como campo ausente
        String texto = el.getAsString().trim();
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(texto); // iso estrito: rejeita 2026-02-30
        } catch (DateTimeParseException e) {
            // transforma o erro de conversão em uma mensagem que identifica o campo
            throw new IllegalArgumentException(
                    "Campo '" + campo + "' deve ser uma data válida no formato yyyy-MM-dd.");
        }
    }

    // lê um inteiro no intervalo [min, max]. se ausente: usa o padrão, ou erro quando padrao == null
    private static int lerInteiro(JsonObject dados, String campo, Integer padrao, int min, int max) {
        if (!dados.has(campo) || dados.get(campo).isJsonNull()) {
            // quando o campo é obrigatório, não existe valor padrão para usar
            if (padrao == null) {
                throw new IllegalArgumentException("Campo '" + campo + "' é obrigatório.");
            }
            return padrao;
        }
        JsonElement el = dados.get(campo);
        // exige um número no json, então um texto como "30" não é aceito
        if (!el.isJsonPrimitive() || !el.getAsJsonPrimitive().isNumber()) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro.");
        }
        int valor;
        try {
            // converte para inteiro sem arredondar e sem aceitar valores fora do tipo int
            BigDecimal numero = el.getAsBigDecimal();
            valor = numero.intValueExact(); // rejeita 30.5 e números gigantes
        } catch (ArithmeticException e) {
            throw new IllegalArgumentException("Campo '" + campo + "' deve ser um número inteiro.");
        }
        // confere o limite específico do campo depois da conversão
        if (valor < min || valor > max) {
            throw new IllegalArgumentException(
                    "Campo '" + campo + "' deve estar entre " + min + " e " + max + ".");
        }
        return valor;
    }
}