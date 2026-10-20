import test from "node:test";
import assert from "node:assert/strict";

import {
    arredondarCentavos,
    temNoMaximoDuasCasas,
    validarMeta,
    validarValorDoacao,
    validarTitulo,
    validarDescricao,
    validarImagemCapa,
    validarDatasCampanha,
    validarMetodoPagamento,
    deveEncerrarPorMeta,
    formatarCampanha,
    type CampanhaDocumento
} from "./campanhasUtil.js";

test("arredondarCentavos: arredonda corretamente somas com imprecisão de ponto flutuante", () => {
    assert.equal(arredondarCentavos(0.1 + 0.2), 0.3);
    assert.equal(arredondarCentavos(10.1 + 20.2), 30.3);
    assert.equal(arredondarCentavos(0.29999999999999993), 0.3);
    assert.equal(arredondarCentavos(10.254), 10.25);
    assert.equal(arredondarCentavos(10.256), 10.26);
});

test("temNoMaximoDuasCasas: valida se um número possui no máximo duas casas decimais", () => {
    assert.equal(temNoMaximoDuasCasas(10.25), true);
    assert.equal(temNoMaximoDuasCasas(10), true);
    assert.equal(temNoMaximoDuasCasas(10.5), true);
    assert.equal(temNoMaximoDuasCasas(10.255), false);
    assert.equal(temNoMaximoDuasCasas(0.30000000000000004), false);
});

test("validarMeta: valida valores válidos e rejeita inválidos conforme requisitos", () => {
    // Válidas
    const res1000 = validarMeta(1000);
    assert.equal(res1000.ok, true);
    if (res1000.ok) assert.equal(res1000.valor, 1000);

    const resTeto = validarMeta(1000000000000);
    assert.equal(resTeto.ok, true);
    if (resTeto.ok) assert.equal(resTeto.valor, 1000000000000);

    // Inválidas
    assert.equal(validarMeta(0).ok, false);
    assert.equal(validarMeta(-1).ok, false);
    assert.equal(validarMeta("1000").ok, false);
    assert.equal(validarMeta(NaN).ok, false);
    assert.equal(validarMeta(Infinity).ok, false);
    assert.equal(validarMeta(-Infinity).ok, false);
    assert.equal(validarMeta(1000000000001).ok, false);
    assert.equal(validarMeta(10.555).ok, false);
    assert.equal(validarMeta(null).ok, false);
    assert.equal(validarMeta(undefined).ok, false);
});

test("validarValorDoacao: valida valores mínimos, máximos e casas decimais", () => {
    // Válidas
    const res1 = validarValorDoacao(1);
    assert.equal(res1.ok, true);
    if (res1.ok) assert.equal(res1.valor, 1);

    const res10Meio = validarValorDoacao(10.5);
    assert.equal(res10Meio.ok, true);
    if (res10Meio.ok) assert.equal(res10Meio.valor, 10.5);

    const resMax = validarValorDoacao(1000000);
    assert.equal(resMax.ok, true);
    if (resMax.ok) assert.equal(resMax.valor, 1000000);

    // Inválidas
    assert.equal(validarValorDoacao(0.99).ok, false);
    assert.equal(validarValorDoacao(1000000.01).ok, false);
    assert.equal(validarValorDoacao("10").ok, false);
    assert.equal(validarValorDoacao(0).ok, false);
    assert.equal(validarValorDoacao(-5).ok, false);
    assert.equal(validarValorDoacao(10.555).ok, false);
    assert.equal(validarValorDoacao(NaN).ok, false);
    assert.equal(validarValorDoacao(null).ok, false);
});

test("validarTitulo: valida comprimento de 3 a 100 caracteres e apara espaços", () => {
    // Inválido curto
    assert.equal(validarTitulo("ab").ok, false);
    // Válido
    const resAbc = validarTitulo("abc");
    assert.equal(resAbc.ok, true);
    if (resAbc.ok) assert.equal(resAbc.valor, "abc");

    // Espaços aparados
    const resEspacos = validarTitulo("   Campanha PetCare   ");
    assert.equal(resEspacos.ok, true);
    if (resEspacos.ok) assert.equal(resEspacos.valor, "Campanha PetCare");

    // Limite superior: 100 caracteres válido, 101 inválido
    const cem = "a".repeat(100);
    const centoEUm = "a".repeat(101);
    assert.equal(validarTitulo(cem).ok, true);
    assert.equal(validarTitulo(centoEUm).ok, false);

    // Tipos inválidos
    assert.equal(validarTitulo(123).ok, false);
    assert.equal(validarTitulo(null).ok, false);
    assert.equal(validarTitulo(undefined).ok, false);
});

test("validarDescricao: valida comprimento entre 1 e 2000 caracteres e apara espaços", () => {
    // Vazia ou só espaços inválida
    assert.equal(validarDescricao("").ok, false);
    assert.equal(validarDescricao("   ").ok, false);

    // Válida 1 caractere
    const res1 = validarDescricao("X");
    assert.equal(res1.ok, true);
    if (res1.ok) assert.equal(res1.valor, "X");

    // Limites de 2000 e 2001 caracteres
    const doisMil = "d".repeat(2000);
    const doisMilEUm = "d".repeat(2001);
    assert.equal(validarDescricao(doisMil).ok, true);
    assert.equal(validarDescricao(doisMilEUm).ok, false);

    // Tipos inválidos
    assert.equal(validarDescricao(null).ok, false);
    assert.equal(validarDescricao(undefined).ok, false);
});

test("validarImagemCapa: valida URLs http/https, comprimento até 500 e campos ausentes", () => {
    // Válida HTTPS
    const resValida = validarImagemCapa("https://exemplo.com/a.png");
    assert.equal(resValida.ok, true);
    if (resValida.ok) assert.equal(resValida.valor, "https://exemplo.com/a.png");

    // Válida HTTP
    const resHttp = validarImagemCapa("http://exemplo.com/capa.jpg");
    assert.equal(resHttp.ok, true);
    if (resHttp.ok) assert.equal(resHttp.valor, "http://exemplo.com/capa.jpg");

    // Ausente / nula / vazia é válida e vira null
    const resAusente = validarImagemCapa(undefined);
    assert.equal(resAusente.ok, true);
    if (resAusente.ok) assert.equal(resAusente.valor, null);

    const resNull = validarImagemCapa(null);
    assert.equal(resNull.ok, true);
    if (resNull.ok) assert.equal(resNull.valor, null);

    const resVazia = validarImagemCapa("");
    assert.equal(resVazia.ok, true);
    if (resVazia.ok) assert.equal(resVazia.valor, null);

    // Inválidas
    assert.equal(validarImagemCapa("ftp://x").ok, false);
    assert.equal(validarImagemCapa("abc").ok, false);
    const urlLonga = "https://exemplo.com/" + "a".repeat(500);
    assert.equal(validarImagemCapa(urlLonga).ok, false);
    assert.equal(validarImagemCapa(12345).ok, false);
});

test("validarDatasCampanha: valida formato YYYY-MM-DD e ISO, ordenação de datas e momentos futuros", () => {
    const agoraFixa = new Date("2026-10-20T12:00:00.000Z");

    // Ambas ausentes: dataInicio vira agora, dataFim vira null
    const resAusentes = validarDatasCampanha(undefined, undefined, agoraFixa);
    assert.equal(resAusentes.ok, true);
    if (resAusentes.ok) {
        assert.equal(resAusentes.valor.dataInicio.getTime(), agoraFixa.getTime());
        assert.equal(resAusentes.valor.dataFim, null);
    }

    // Datas válidas com YYYY-MM-DD
    const resValidas = validarDatasCampanha("2026-10-21", "2026-10-25", agoraFixa);
    assert.equal(resValidas.ok, true);
    if (resValidas.ok) {
        assert.equal(resValidas.valor.dataInicio instanceof Date, true);
        assert.equal(resValidas.valor.dataFim instanceof Date, true);
    }

    // Datas válidas com ISO completo
    const resIso = validarDatasCampanha("2026-10-21T00:00:00.000Z", "2026-10-25T23:59:59.000Z", agoraFixa);
    assert.equal(resIso.ok, true);

    // dataFim anterior a dataInicio
    const resFimAnterior = validarDatasCampanha("2026-10-25", "2026-10-21", agoraFixa);
    assert.equal(resFimAnterior.ok, false);

    // dataFim igual a dataInicio
    const resFimIgual = validarDatasCampanha("2026-10-25", "2026-10-25", agoraFixa);
    assert.equal(resFimIgual.ok, false);

    // dataFim no passado relativo a agora
    const resFimPassado = validarDatasCampanha("2026-10-01", "2026-10-10", agoraFixa);
    assert.equal(resFimPassado.ok, false);

    // Texto inválido
    assert.equal(validarDatasCampanha("data-invalida", "2026-10-25", agoraFixa).ok, false);
    assert.equal(validarDatasCampanha("2026-10-21", "data-invalida", agoraFixa).ok, false);
    assert.equal(validarDatasCampanha("20/10/2026", "25/10/2026", agoraFixa).ok, false);
});

test("validarMetodoPagamento: aceita pix e cartao e rejeita qualquer outro valor", () => {
    const resPix = validarMetodoPagamento("pix");
    assert.equal(resPix.ok, true);
    if (resPix.ok) assert.equal(resPix.valor, "pix");

    const resCartao = validarMetodoPagamento("cartao");
    assert.equal(resCartao.ok, true);
    if (resCartao.ok) assert.equal(resCartao.valor, "cartao");

    // Com espaços e maiúsculas
    const resPixEspaco = validarMetodoPagamento("  PIX  ");
    assert.equal(resPixEspaco.ok, true);
    if (resPixEspaco.ok) assert.equal(resPixEspaco.valor, "pix");

    // Inválidos
    assert.equal(validarMetodoPagamento("boleto").ok, false);
    assert.equal(validarMetodoPagamento("dinheiro").ok, false);
    assert.equal(validarMetodoPagamento(null).ok, false);
    assert.equal(validarMetodoPagamento(123).ok, false);
});

test("deveEncerrarPorMeta: compara com precisão de centavos se a arrecadação atingiu ou superou a meta", () => {
    assert.equal(deveEncerrarPorMeta(999.99, 1000), false);
    assert.equal(deveEncerrarPorMeta(1000, 1000), true);
    assert.equal(deveEncerrarPorMeta(1500, 1000), true);
    assert.equal(deveEncerrarPorMeta(0.30000000000000004, 0.3), true);
    assert.equal(deveEncerrarPorMeta(0.29999999999999993, 0.3), true);
});

test("formatarCampanha: formata documento e oculta criadoPorId quando não for da equipe", () => {
    const doc: CampanhaDocumento = {
        _id: "671000000000000000000001",
        criadoPorId: "671000000000000000000002",
        titulo: "Campanha Castração",
        descricao: "Ajude na castração",
        metaValor: 1000,
        valorArrecadado: 250,
        status: "ativa",
        imagemCapa: null,
        dataInicio: new Date("2026-10-20"),
        dataFim: null,
        criadoEm: new Date("2026-10-20")
    };

    const progressoMock = {
        porcentagem: 25.0,
        porcentagemExibicao: 25.0,
        valorRestante: 750.0,
        statusProgresso: "EM_ANDAMENTO"
    };

    // Para equipe: criadoPorId deve estar presente
    const formatadaEquipe = formatarCampanha(doc, progressoMock, true);
    assert.equal(formatadaEquipe.criadoPorId, "671000000000000000000002");
    assert.deepEqual(formatadaEquipe.progresso, progressoMock);

    // Para não equipe: criadoPorId deve ser omitido
    const formatadaTutor = formatarCampanha(doc, progressoMock, false);
    assert.equal("criadoPorId" in formatadaTutor, false);
    assert.deepEqual(formatadaTutor.progresso, progressoMock);
});
