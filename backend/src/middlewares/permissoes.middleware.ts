// Alinne Monteiro de Melo | RA: 24801649

import type { Request, Response, NextFunction } from "express";

// cria um middleware com as funções permitidas para a rota
export function permitirFuncoes(...funcoesPermitidas: string[]) {
    return (req: Request, res: Response, next: NextFunction) => {
        // lê a função da conta que foi identificada na autenticação
        const tipoUsuario = res.locals.usuarioTipo;

        // bloqueia o acesso se a função estiver ausente ou fora da lista
        if (!tipoUsuario || !funcoesPermitidas.includes(tipoUsuario)) {
            res.status(403).json({
                mensagem: "Você não tem permissão para realizar esta ação."
            });
            return;
        }

        // libera a rota quando a função está na lista
        next();
    };
}