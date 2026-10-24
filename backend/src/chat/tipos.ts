import type { ObjectId } from "mongodb";

export type PapelChat = "USUARIO" | "VETERINARIO" | "ENFERMEIRO" | "SECRETARIA";
export const PAPEL_TUTOR: PapelChat = "USUARIO";
export const PAPEL_VETERINARIO: PapelChat = "VETERINARIO";
export const PAPEL_ENFERMEIRO: PapelChat = "ENFERMEIRO";
export const PAPEL_SECRETARIA: PapelChat = "SECRETARIA";
export const LADO_SECRETARIA = "SECRETARIA";

export const LIMITE_TEXTO = 2000;
export const LIMITE_PREVIA = 100;
export const LIMITE_PAGINA = 100;
export const LIMITE_PAGINA_PADRAO = 50;
export const LIMITE_CONVERSAS = 50;
export const LIMITE_CONTATOS = 200;
export const LIMITE_BUSCA = 100;

export type TipoConversa = "secretaria" | "direta";
export type ResultadoValidacao<T> = { ok: true; valor: T } | { ok: false; mensagem: string };
export interface UsuarioAutenticado { id: string; papel: PapelChat }   // id em hex minúsculo
export interface UltimaMensagem { texto: string; remetenteId: ObjectId; remetenteTipo: PapelChat; criadoEm: Date }

export interface ConversaDocumento {
    _id: ObjectId;
    chave: string;
    tipo: TipoConversa;
    usuarioId?: ObjectId;
    participantes?: ObjectId[];
    criadoEm: Date;
    ultimaMensagemEm: Date | null;
    ultimaMensagem: UltimaMensagem | null;
    leituras: Record<string, Date>;
}

export interface MensagemDocumento {
    _id: ObjectId;
    conversaId: ObjectId;
    remetenteId: ObjectId;
    remetenteTipo: PapelChat;
    texto: string;
    criadoEm: Date;
}
