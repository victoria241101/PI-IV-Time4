package petcare.servidor.servicos;

import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class ProgressoCampanhaInterclasseTest {

    // CENÁRIO NORMAL
    @Test
    void testarCenarioNormal() {

        JsonObject dados = new JsonObject();
        dados.addProperty("valorArrecadado", 1500);
        dados.addProperty("metaValor", 3000);

        JsonObject resposta =
                ProgressoCampanhaService.calcularProgresso(dados);

        assertEquals("OK",
                resposta.get("status").getAsString());

        JsonObject resultado = resposta.getAsJsonObject("dados");

        assertEquals(50.0,
                resultado.get("porcentagem").getAsDouble());

        assertEquals(1500.00,
                resultado.get("valorRestante").getAsDouble());

        assertEquals("EM_ANDAMENTO",
                resultado.get("statusProgresso").getAsString());
    }

    // CENÁRIO ALTERNATIVO / ERRO
    @Test
    void testarCenarioErro() {

        JsonObject dados = new JsonObject();
        dados.addProperty("valorArrecadado", 100);
        dados.addProperty("metaValor", 0);

        JsonObject resposta =
                ProgressoCampanhaService.calcularProgresso(dados);

        assertEquals("ERRO",
                resposta.get("status").getAsString());

        assertEquals("DADOS_INVALIDOS",
                resposta.get("codigo").getAsString());

        assertTrue(
                resposta.get("mensagem").getAsString()
                        .contains("metaValor")
        );
    }
}

