package petcare.servidor.servicos;

import com.google.gson.JsonObject;
import main.java.petcare.servidor.servicos.VacinaService;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class VacinaServiceTest {

    @Test
    void testarVacinaPendente() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataReferencia", "2026-11-20");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("PENDENTE",
                resultado.get("statusVacina").getAsString());
        assertFalse(resultado.has("dataProximaDose"));
        assertFalse(resultado.has("diasRestantes"));
    }

    @Test
    void testarVacinaEmDia() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2026-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        dados.addProperty("dataReferencia", "2026-10-01");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("EM_DIA",
                resultado.get("statusVacina").getAsString());
        assertEquals("2027-01-01",
                resultado.get("dataProximaDose").getAsString());
        assertEquals(92, resultado.get("diasRestantes").getAsInt());
    }

    @Test
    void testarVacinaAVencer() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2026-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        dados.addProperty("dataReferencia", "2026-12-20");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("A_VENCER",
                resultado.get("statusVacina").getAsString());
        assertEquals(12, resultado.get("diasRestantes").getAsInt());
    }

    @Test
    void testarVacinaAtrasada() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2025-01-01");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("diasAlerta", 30);
        dados.addProperty("dataReferencia", "2026-01-11");

        JsonObject resposta = VacinaService.calcularStatus(dados);
        JsonObject resultado = resposta.getAsJsonObject("dados");

        assertEquals("OK", resposta.get("status").getAsString());
        assertEquals("ATRASADA",
                resultado.get("statusVacina").getAsString());
        assertEquals(-10, resultado.get("diasRestantes").getAsInt());
    }

    @Test
    void testarDataInvalida() {
        JsonObject dados = new JsonObject();
        dados.addProperty("dataUltimaAplicacao", "2026-02-30");
        dados.addProperty("intervaloDias", 365);
        dados.addProperty("dataReferencia", "2026-11-20");

        JsonObject resposta = VacinaService.calcularStatus(dados);

        assertEquals("ERRO", resposta.get("status").getAsString());
        assertTrue(resposta.get("mensagem").getAsString()
                .contains("data válida"));
    }
}
