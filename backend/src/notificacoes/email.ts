import nodemailer from "nodemailer";
import type { Transporter } from "nodemailer";
/**
 * Interface com os recursos de envio configurados para o serviço de e-mail.
 */
export interface ConfiguracaoEmail {
    transporte: Transporter;
    remetente: string;
}

/**
 * Função de configuração equivalente à utilizada em usuarios.routes.ts.
 * Lê SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS e SMTP_FROM.
 * Define secure = true estritamente quando a porta for 465.
 * Devolve null (sem lançar) se a configuração estiver ausente ou incompleta.
 */
export function configurarEmail(): ConfiguracaoEmail | null {
    const host = process.env.SMTP_HOST;
    const porta = Number(process.env.SMTP_PORT || "587");
    const usuario = process.env.SMTP_USER;
    const senha = process.env.SMTP_PASS;
    const remetente = process.env.SMTP_FROM;

    if (!host || !usuario || !senha || !remetente || !Number.isInteger(porta)) {
        return null;
    }

    return {
        transporte: nodemailer.createTransport({
            host,
            port: porta,
            secure: porta === 465,
            auth: { user: usuario, pass: senha }
        }),
        remetente
    };
}

/**
 * Função PURA: formata o corpo em texto simples para um e-mail de notificação.
 * Monta saudação acolhedora, conteúdo e assinatura padronizada.
 */
export function formatarCorpoEmail(
    titulo: string,
    mensagem: string,
    nomeDestinatario?: string | null
): string {
    const saudacao = nomeDestinatario && nomeDestinatario.trim()
        ? `Olá, ${nomeDestinatario.trim()}!`
        : "Olá!";

    const linhas = [
        saudacao,
        "",
        titulo.trim(),
        mensagem.trim(),
        "",
        "Atenciosamente,",
        "Equipe PetCare"
    ];

    return linhas.join("\n");
}

/**
 * Função PURA: formata o assunto e o corpo completo de um e-mail de lembrete.
 */
export function formatarEmailLembrete(
    titulo: string,
    mensagem: string,
    nomeDestinatario?: string | null
): { assunto: string; texto: string } {
    return {
        assunto: `[PetCare] ${titulo.trim()}`,
        texto: formatarCorpoEmail(titulo, mensagem, nomeDestinatario)
    };
}

/**
 * Envia um e-mail utilizando transporte SMTP via nodemailer.
 * - Retorna false e NUNCA lança exceção em caso de falha ou configuração incompleta.
 * - Nunca registra endereços, senhas ou conteúdos sensíveis no log.
 */
export async function enviarEmail(
    para: string,
    assunto: string,
    texto: string
): Promise<boolean> {
    try {
        if (!para || typeof para !== "string" || !para.trim()) {
            return false;
        }

        const config = configurarEmail();
        if (!config) {
            return false;
        }

        await config.transporte.sendMail({
            from: config.remetente,
            to: para.trim(),
            subject: assunto,
            text: texto
        });

        return true;
    } catch {
        console.error("Erro interno ao enviar e-mail.");
        return false;
    }
}
