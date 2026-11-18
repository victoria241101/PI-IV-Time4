
package petcare.servidor.servicos;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class ProgressoCampanhaServiceTest {

    @Test
    void testarCampanhaSemDoacoes() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("0"),
                new BigDecimal("3000")
            );

        assertEquals("SEM_DOACOES", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("0.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("3000.00")));
    }

    @Test
    void testarCampanhaEmAndamento() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("1500"),
                new BigDecimal("3000")
            );

        assertEquals("EM_ANDAMENTO", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("50.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("1500.00")));
    }

    @Test
    void testarCampanhaQuaseLa() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("2400"),
                new BigDecimal("3000")
            );

        assertEquals("QUASE_LA", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("80.0")));
    }

    @Test
    void testarMetaAtingida() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("3000"),
                new BigDecimal("3000")
            );

        assertEquals("META_ATINGIDA", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("100.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("0.00")));
    }

    @Test
    void testarMetaUltrapassada() {
        ProgressoCampanhaService.ResultadoProgresso resultado =
            ProgressoCampanhaService.calcular(
                new BigDecimal("3500"),
                new BigDecimal("3000")
            );

        assertEquals("META_ATINGIDA", resultado.getStatusProgresso());
        assertEquals(0, resultado.getPorcentagem().compareTo(new BigDecimal("116.6")));
        assertEquals(0, resultado.getPorcentagemExibicao().compareTo(new BigDecimal("100.0")));
        assertEquals(0, resultado.getValorRestante().compareTo(new BigDecimal("0.00")));
    }

    @Test
    void testarMetaInvalida() {
        IllegalArgumentException erro = assertThrows(
            IllegalArgumentException.class,
            () -> ProgressoCampanhaService.calcular(
                new BigDecimal("100"),
                new BigDecimal("0")
            )
        );

        assertEquals(
            "Campo 'metaValor' deve ser estritamente maior que 0.",
            erro.getMessage()
        );
    }
}
