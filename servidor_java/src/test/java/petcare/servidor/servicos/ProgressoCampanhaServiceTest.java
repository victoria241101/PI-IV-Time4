// Alinne Monteiro de Melo | RA: 24801649

package petcare.servidor.servicos;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

// testa o cálculo direto com bigdecimal para os valores da campanha
public class ProgressoCampanhaServiceTest {

    // sem doações, a porcentagem é zero e falta o valor inteiro da meta
    @Test
    void testarCampanhaSemDoacoes() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("0"),
                new BigDecimal("3000")
            );

        // confere se o status indica que ninguém doou
        assertEquals("SEM_DOACOES", resultado.getStatusProgresso());
        // compareto devolve zero quando os números têm o mesmo valor, mesmo com casas decimais diferentes
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("0.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("3000.00")));
    }

    // testa uma arrecadação de 1500 para uma meta de 3000
    @Test
    void testarCampanhaEmAndamento() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("1500"),
                new BigDecimal("3000")
            );

        // espera a campanha em andamento, com metade da meta ainda faltando
        assertEquals("EM_ANDAMENTO", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("50.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("1500.00")));
    }

    // testa se atingir 80 por cento coloca a campanha no estado quase lá
    @Test
    void testarCampanhaQuaseLa() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("2400"),
                new BigDecimal("3000")
            );

        // confere o status e a porcentagem de 2400 em relação a 3000
        assertEquals("QUASE_LA", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("80.0")));
    }

    // testa o caso em que a arrecadação é exatamente igual à meta
    @Test
    void testarMetaAtingida() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("3000"),
                new BigDecimal("3000")
            );

        // confere se chegou a 100 por cento e se o restante ficou zerado
        assertEquals("META_ATINGIDA", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("100.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("0.00")));
    }

    // testa a campanha que arrecadou mais do que a meta
    @Test
    void testarMetaUltrapassada() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("3500"),
                new BigDecimal("3000")
            );

        // mesmo acima da meta, o estado esperado continua sendo meta atingida
        assertEquals("META_ATINGIDA", resultado.getStatusProgresso());
        // confere o valor calculado acima de 100 e o valor de exibição limitado a 100
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("116.6")));
        assertEquals(0, resultado.getPorcentagemExibicao().compareTo(new BigDecimal("100.0")));
        // o valor restante fica zerado mesmo quando sobra dinheiro
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("0.00")));
    }

    // testa se o cálculo rejeita uma meta igual a zero
    @Test
    void testarMetaInvalida() {
        // o teste só passa aqui se a chamada lançar a exceção esperada
        IllegalArgumentException erro = assertThrows(
            IllegalArgumentException.class,
            () -> ProgressoCampanhaService.calcular(
                new BigDecimal("100"),
                new BigDecimal("0")
            )
        );

        // confere se a mensagem explica que a meta precisa ser maior que zero
        assertEquals(
            "Campo 'metaValor' deve ser estritamente maior que 0.",
            erro.getMessage()
        );
    }
}
