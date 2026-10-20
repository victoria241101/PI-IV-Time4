import type { ObjectId } from "mongodb";
import { enviarComandoJava } from "./javaClient.js";

export const PAPEIS_GESTAO_CAMPANHAS: readonly string[] = ["SECRETARIA"];
export const PAPEIS_EQUIPE: readonly string[] = ["SECRETARIA", "VETERINARIO", "ENFERMEIRO"];

export const TETO_VALOR = 1000000000000;
export const VALOR_MINIMO_DOACAO = 1;
export const VALOR_MAXIMO_DOACAO = 1000000;

export type ResultadoValidacao<T> =
    | { ok: true; valor: T }
    | { ok: false; mensagem: string };

export interface ProgressoJava {
    porcentagem: number;
    porcentagemExibicao: number;
    valorRestante: number;
    statusProgresso: string;
}

export interface CampanhaDocumento {
    _id: ObjectId | string;
    criadoPorId?: ObjectId | string;
    titulo: string;
    descricao: string;
    metaValor: number;
    valorArrecadado: number;
    status: "ativa" | "encerrada";
    imagemCapa: string | null;
    dataInicio: Date;
    dataFim: Date | null;
    criadoEm: Date;
}

export interface CampanhaFormatada {
    _id: string;
    titulo: string;
    descricao: string;
    metaValor: number;
    valorArrecadado: number;
    status: "ativa" | "encerrada";
    imagemCapa: string | null;
    dataInicio: Date;
    dataFim: Date | null;
    criadoEm: Date;
    criadoPorId?: string;
    progresso: ProgressoJava | null;
}

export function ehEquipe(tipoUsuario?: string): boolean {
    return tipoUsuario !== undefined && PAPEIS_EQUIPE.includes(tipoUsuario);
}

export function arredondarCentavos(n: number): number {
    return Math.round(n * 100) / 100;
}

export function temNoMaximoDuasCasas(n: number): boolean {
    if (typeof n !== "number" || !Number.isFinite(n)) {
        return false;
    }
    return Math.round(n * 100) / 100 === n;
}

export function deveEncerrarPorMeta(valorArrecadado: number, metaValor: number): boolean {
    return arredondarCentavos(valorArrecadado) >= metaValor;
}

export function validarMeta(valor: unknown): ResultadoValidacao<number> {
    if (typeof valor !== "number" || !Number.isFinite(valor)) {
        return { ok: false, mensagem: "A meta deve ser um número válido." };
    }

    if (valor <= 0) {
        return { ok: false, mensagem: "A meta deve ser maior que zero." };
    }

    if (valor > TETO_VALOR) {
        return { ok: false, mensagem: `A meta não pode ultrapassar ${TETO_VALOR}.` };
    }

    if (!temNoMaximoDuasCasas(valor)) {
        return { ok: false, mensagem: "A meta deve ter no máximo duas casas decimais." };
    }

    return { ok: true, valor: arredondarCentavos(valor) };
}

export function validarValorDoacao(valor: unknown): ResultadoValidacao<number> {
    if (typeof valor !== "number" || !Number.isFinite(valor)) {
        return { ok: false, mensagem: "O valor da doação deve ser um número válido." };
    }

    if (valor < VALOR_MINIMO_DOACAO) {
        return { ok: false, mensagem: `O valor mínimo para doação é R$ ${VALOR_MINIMO_DOACAO}.` };
    }

    if (valor > VALOR_MAXIMO_DOACAO) {
        return { ok: false, mensagem: `O valor máximo para doação é R$ ${VALOR_MAXIMO_DOACAO}.` };
    }

    if (!temNoMaximoDuasCasas(valor)) {
        return { ok: false, mensagem: "O valor da doação deve ter no máximo duas casas decimais." };
    }

    return { ok: true, valor: arredondarCentavos(valor) };
}

export function validarTitulo(titulo: unknown): ResultadoValidacao<string> {
    if (typeof titulo !== "string") {
        return { ok: false, mensagem: "O título deve ser um texto." };
    }

    const aparado = titulo.trim();

    if (aparado.length < 3 || aparado.length > 100) {
        return { ok: false, mensagem: "O título deve ter entre 3 e 100 caracteres." };
    }

    return { ok: true, valor: aparado };
}

export function validarDescricao(descricao: unknown): ResultadoValidacao<string> {
    if (typeof descricao !== "string") {
        return { ok: false, mensagem: "A descrição deve ser um texto." };
    }

    const aparado = descricao.trim();

    if (aparado.length < 1 || aparado.length > 2000) {
        return { ok: false, mensagem: "A descrição deve ter entre 1 e 2000 caracteres." };
    }

    return { ok: true, valor: aparado };
}

export function validarImagemCapa(imagemCapa: unknown): ResultadoValidacao<string | null> {
    if (imagemCapa === undefined || imagemCapa === null || imagemCapa === "") {
        return { ok: true, valor: null };
    }

    if (typeof imagemCapa !== "string") {
        return { ok: false, mensagem: "A imagem de capa deve ser uma URL válida." };
    }

    const urlStr = imagemCapa.trim();

    if (urlStr.length > 500) {
        return { ok: false, mensagem: "A URL da imagem de capa não pode exceder 500 caracteres." };
    }

    try {
        const parsed = new URL(urlStr);
        if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
            return { ok: false, mensagem: "A URL da imagem deve utilizar protocolo HTTP ou HTTPS." };
        }
    } catch {
        return { ok: false, mensagem: "A imagem de capa deve ser uma URL válida." };
    }

    return { ok: true, valor: urlStr };
}

const REGEX_DATA = /^(\d{4}-\d{2}-\d{2})(?:T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?(?:Z|([+-]\d{2}:?\d{2}))?)?$/;

function converterParaData(texto: string): Date | null {
    if (!REGEX_DATA.test(texto)) {
        return null;
    }

    const data = new Date(texto);
    if (isNaN(data.getTime())) {
        return null;
    }

    return data;
}

export function validarDatasCampanha(
    dataInicioInput: unknown,
    dataFimInput: unknown,
    agora: Date = new Date()
): ResultadoValidacao<{ dataInicio: Date; dataFim: Date | null }> {
    let dataInicio: Date;

    if (dataInicioInput === undefined || dataInicioInput === null || dataInicioInput === "") {
        dataInicio = agora;
    } else if (typeof dataInicioInput !== "string") {
        return { ok: false, mensagem: "A data de início deve ser uma string válida." };
    } else {
        const parsedInicio = converterParaData(dataInicioInput.trim());
        if (!parsedInicio) {
            return { ok: false, mensagem: "Data de início inválida. Use YYYY-MM-DD ou formato ISO." };
        }
        dataInicio = parsedInicio;
    }

    let dataFim: Date | null = null;

    if (dataFimInput !== undefined && dataFimInput !== null && dataFimInput !== "") {
        if (typeof dataFimInput !== "string") {
            return { ok: false, mensagem: "A data final deve ser uma string válida." };
        }

        const parsedFim = converterParaData(dataFimInput.trim());
        if (!parsedFim) {
            return { ok: false, mensagem: "Data final inválida. Use YYYY-MM-DD ou formato ISO." };
        }

        if (parsedFim.getTime() <= dataInicio.getTime()) {
            return { ok: false, mensagem: "A data final deve ser posterior à data de início." };
        }

        if (parsedFim.getTime() <= agora.getTime()) {
            return { ok: false, mensagem: "A data final deve ser posterior ao momento atual." };
        }

        dataFim = parsedFim;
    }

    return { ok: true, valor: { dataInicio, dataFim } };
}

export function validarMetodoPagamento(metodo: unknown): ResultadoValidacao<"pix" | "cartao"> {
    if (typeof metodo !== "string") {
        return { ok: false, mensagem: "O método de pagamento deve ser um texto." };
    }

    const aparado = metodo.trim().toLowerCase();

    if (aparado !== "pix" && aparado !== "cartao") {
        return { ok: false, mensagem: "Método de pagamento inválido. Use 'pix' ou 'cartao'." };
    }

    return { ok: true, valor: aparado as "pix" | "cartao" };
}

export function formatarCampanha(
    campanha: CampanhaDocumento,
    progresso: ProgressoJava | null,
    incluirCriadoPorId: boolean
): CampanhaFormatada {
    const base: CampanhaFormatada = {
        _id: campanha._id.toString(),
        titulo: campanha.titulo,
        descricao: campanha.descricao,
        metaValor: arredondarCentavos(campanha.metaValor),
        valorArrecadado: arredondarCentavos(campanha.valorArrecadado),
        status: campanha.status,
        imagemCapa: campanha.imagemCapa,
        dataInicio: campanha.dataInicio,
        dataFim: campanha.dataFim,
        criadoEm: campanha.criadoEm,
        progresso
    };

    if (incluirCriadoPorId && campanha.criadoPorId) {
        base.criadoPorId = campanha.criadoPorId.toString();
    }

    return base;
}

export async function obterProgresso(
    campanha: { valorArrecadado: number; metaValor: number }
): Promise<ProgressoJava | null> {
    try {
        const resposta = await enviarComandoJava("CALCULAR_PROGRESSO_CAMPANHA", {
            valorArrecadado: arredondarCentavos(campanha.valorArrecadado),
            metaValor: arredondarCentavos(campanha.metaValor)
        });

        if (resposta.status !== "OK" || !resposta.dados) {
            console.error("Servidor Java retornou status não-OK ao calcular progresso:", resposta);
            return null;
        }

        const dados = resposta.dados as unknown as {
            porcentagem?: unknown;
            porcentagemExibicao?: unknown;
            valorRestante?: unknown;
            statusProgresso?: unknown;
        };

        if (
            typeof dados.porcentagem !== "number" ||
            typeof dados.porcentagemExibicao !== "number" ||
            typeof dados.valorRestante !== "number" ||
            typeof dados.statusProgresso !== "string"
        ) {
            console.error("Campos de progresso ausentes ou inválidos na resposta do Java:", dados);
            return null;
        }

        return {
            porcentagem: dados.porcentagem,
            porcentagemExibicao: dados.porcentagemExibicao,
            valorRestante: dados.valorRestante,
            statusProgresso: dados.statusProgresso
        };
    } catch (erro) {
        console.error("Falha ao comunicar com o servidor Java para cálculo de progresso:", erro);
        return null;
    }
}
