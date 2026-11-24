// Alinne Monteiro de Melo | RA: 24801649

package petcare.servidor.servicos;

import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

// testa a entrada e a saída em json do cálculo de progresso
public class ProgressoCampanhaInterclasseTest {

    // cenário normal
    @Test
    void testarCenarioNormal() {

        // monta uma campanha que arrecadou exatamente metade da meta
        JsonObject dados = new JsonObject();
        dados.addProperty("valorArrecadado", 1500);
        dados.addProperty("metaValor", 3000);

        // envia os dados pelo mesmo método que recebe o json da campanha
        JsonObject resposta =
                ProgressoCampanhaService.calcularProgresso(dados);

        // confere o status da resposta antes de verificar os dados calculados
        assertEquals("OK",
                resposta.get("status").getAsString());

        JsonObject resultado = resposta.getAsJsonObject("dados");

        // espera 50 por cento e um saldo restante de 1500
        assertEquals(50.0,
                resultado.get("porcentagem").getAsDouble());

        assertEquals(1500.00,
                resultado.get("valorRestante").getAsDouble());

        // como ainda falta metade, a campanha deve estar em andamento
        assertEquals("EM_ANDAMENTO",
                resultado.get("statusProgresso").getAsString());
    }

    // cenário alternativo / erro
    @Test
    void testarCenarioErro() {

        // usa uma meta igual a zero para acionar a validação
        JsonObject dados = new JsonObject();
        dados.addProperty("valorArrecadado", 100);
        dados.addProperty("metaValor", 0);

        JsonObject resposta =
                ProgressoCampanhaService.calcularProgresso(dados);

        // confere se o serviço devolve erro com o código de dados inválidos
        assertEquals("ERRO",
                resposta.get("status").getAsString());

        assertEquals("DADOS_INVALIDOS",
                resposta.get("codigo").getAsString());

        // verifica se a mensagem aponta qual campo foi rejeitado
        assertTrue(
                resposta.get("mensagem").getAsString()
                        .contains("metaValor")
        );
    }
}

