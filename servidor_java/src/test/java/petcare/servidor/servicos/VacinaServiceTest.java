// Alinne Monteiro de Melo | RA: 24801649

package petcare.servidor.servicos;

import com.google.gson.JsonObject;
import main.java.petcare.servidor.servicos.VacinaService;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class VacinaServiceTest {

    // sem última aplicação, espera que a vacina fique pendente
    @Test
    void testarVacinaPendente() {
        // usa uma data fixa para o resultado não depender do dia em que o teste roda
        JsonObject dados = new JsonObject();
        dados.addProperty("dataReferencia", "2026-11-20");

        // chama o serviço e pega os campos calculados dentro de dados
        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        // confere se o serviço processou a entrada e retornou pendente
        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("PENDENTE",
                resultado.get("statusVacina").getAsString());
        // sem dose anterior, a resposta não deve incluir data nem contagem de dias
        assertFalse(resultado.has("dataProximaDose"));
        assertFalse(resultado.has("diasRestantes"));
    }

    // testa uma dose com vencimento fora do período de alerta
    @Test
    void testarVacinaEmDia() {
        JsonObject dados = new JsonObject();
        // usa um intervalo de 365 dias a partir da última aplicação
        dados.addProperty("dataUltimaAplicacao", "2026-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        dados.addProperty("dataReferencia", "2026-10-01");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        // espera 92 dias restantes, um prazo maior que o alerta de 30 dias
        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("EM_DIA",
                resultado.get("statusVacina").getAsString());
        // confere se somar 365 dias à última aplicação resulta em 2027-01-01
        assertEquals("2027-01-01",
                resultado.get("dataProximaDose").getAsString());
        assertEquals(92, resultado.get("diasRestantes").getAsInt());
    }

    // testa uma dose que vence dentro do período de alerta
    @Test
    void testarVacinaAVencer() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2026-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        // escolhe uma referência que fica 12 dias antes da próxima dose
        dados.addProperty("dataReferencia", "2026-12-20");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        // como 12 é menor que 30, o estado esperado é a vencer
        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("A_VENCER",
                resultado.get("statusVacina").getAsString());
        assertEquals(12, resultado.get("diasRestantes").getAsInt());
    }

    // testa uma dose cuja data já passou
    @Test
    void testarVacinaAtrasada() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2025-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        // usa uma referência 10 dias depois do vencimento
        dados.addProperty("dataReferencia", "2026-01-11");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        // confere se a vacina ficou atrasada e se a diferença veio negativa
        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("ATRASADA",
                resultado.get("statusVacina").getAsString());
        assertEquals(-10, resultado.get("diasRestantes").getAsInt());
    }

    // testa uma data que não existe no calendário
    @Test
    void testarDataInvalida() {
        JsonObject dados = new JsonObject();
        // fevereiro não tem dia 30
        dados.addProperty("dataUltimaAplicacao", "2026-02-30");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("dataReferencia", "2026-11-20");

        JsonObject resposta = VacinaService.calcularStatus(dados);

        // confere se o serviço retorna erro e explica que a data precisa ser válida
        assertEquals("ERRO", resposta.get("status").getAsString());
        assertTrue(resposta.get("mensagem").getAsString()
                .contains("data válida"));
    }
}
