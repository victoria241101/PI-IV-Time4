/**
 * Helper de lógica de vacina — compartilhado entre rotas.
 *
 * Sem dependências externas além dos tipos nativos do TypeScript/Node.
 */

/**
 * Intervalo padrão (em dias) entre doses de vacina.
 * Padrão ajustável: altere este valor para mudar o comportamento em toda a aplicação.
 */
export const INTERVALO_VACINA_PADRAO_DIAS = 365;

/**
 * Normaliza um texto para comparação:
 * trim → NFD (decompõe acentos) → remove diacríticos → minúsculas.
 * Retorna string vazia se o valor não for string.
 */
function normalizar(valor: unknown): string {
    if (typeof valor !== "string") {
        return "";
    }
    return valor
        .trim()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase();
}

/**
 * Regex de palavra inteira para detectar vacina no texto normalizado.
 *
 * Casa como palavra completa (delimitada por \b):
 *   "vacina"    → vacina antirrábica, Vacina, vacina
 *   "vacinas"   → Vacinas V10
 *   "vacinacao" → VACINAÇÃO (após normalização)
 *   "vacinacoes"→ variação plural de vacinação
 *
 * NÃO casa (sufixo diferente, fora do padrão):
 *   "vacinador" — sufixo "dor" não está no padrão → false
 */
const REGEX_VACINA = /\bvacin(a|as|acao|acoes)\b/;

/**
 * Retorna true se "tipo" OU "nome" indicar vacina (regex de palavra inteira
 * aplicada sobre texto normalizado sem acentos).
 */
export function ehVacina(tipo: unknown, nome: unknown): boolean {
    return REGEX_VACINA.test(normalizar(tipo)) || REGEX_VACINA.test(normalizar(nome));
}

/**
 * Converte um objeto Date para a string "yyyy-MM-dd" no fuso America/Sao_Paulo.
 * Usa Intl.DateTimeFormat com locale "en-CA", que formata como yyyy-MM-dd.
 */
export function dateParaDataSP(data: Date): string {
    return new Intl.DateTimeFormat("en-CA", {
        timeZone: "America/Sao_Paulo"
    }).format(data);
}
