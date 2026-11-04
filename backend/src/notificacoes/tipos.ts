import type { ObjectId } from "mongodb";
import type { ResultadoValidacao } from "../chat/tipos.js";

/**
 * Reexportação do tipo de resultado padronizado no backend.
 */
export type Resultado<T> = ResultadoValidacao<T>;

/**
 * Tipos de notificação suportados pelo sistema PetCare.
 * Todos em texto minúsculo, sem acentos e sem caracteres especiais.
 */
export const TIPOS_NOTIFICACAO = [
    "chegada_paciente",
    "triagem_concluida",
    "tarefa_clinica_criada",
    "dose_prescrita",
    "consulta_agendada",
    "consulta_remarcada",
    "consulta_cancelada",
    "alta_orientacoes",
    "campanha_encerrada",
    "campanha_meta_atingida",
    "lembrete_consulta",
    "lembrete_vacina"
] as const;

export type TipoNotificacao = (typeof TIPOS_NOTIFICACAO)[number];

/**
 * Subconjunto de notificações que geram disparo de e-mail ao tutor.
 */
export const TIPOS_COM_EMAIL: readonly TipoNotificacao[] = [
    "lembrete_consulta",
    "lembrete_vacina"
] as const;

/**
 * Limites de paginação para listagem de notificações.
 */
export const LIMITE_PADRAO = 20;
export const LIMITE_MAXIMO = 50;

/**
 * Limites de tamanho de texto para título e mensagem.
 */
export const LIMITE_TITULO = 100;
export const LIMITE_MENSAGEM = 500;

/**
 * Estados do ciclo de envio de e-mail da notificação.
 */
export type StatusEmail = "pendente" | "enviado" | "falhou";

/**
 * Dados de entrada para criação de uma nova notificação.
 */
export interface NotificacaoNova {
    destinatarioId: ObjectId;
    remetenteId?: ObjectId | null;
    tipo: TipoNotificacao;
    titulo: string;
    mensagem: string;
    petId?: string | null;
    consultaId?: string | null;
    chave?: string | null;
}

/**
 * Estrutura persistida na coleção 'notificacoes'.
 */
export interface NotificacaoDocumento {
    _id: ObjectId;
    destinatarioId: ObjectId;
    remetenteId: ObjectId | null;
    tipo: TipoNotificacao;
    titulo: string;
    mensagem: string;
    petId: string | null;
    consultaId: string | null;
    chave: string | null;
    lidaEm: Date | null;
    criadoEm: Date;
    emailStatus?: StatusEmail;
    emailTentativas?: number;
}
