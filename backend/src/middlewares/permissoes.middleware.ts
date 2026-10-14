import type { Request, Response, NextFunction } from "express";

export function permitirFuncoes(...funcoesPermitidas: string[]) {
    return (req: Request, res: Response, next: NextFunction) => {
        const tipoUsuario = res.locals.usuarioTipo;

        if (!tipoUsuario || !funcoesPermitidas.includes(tipoUsuario)) {
            res.status(403).json({
                mensagem: "Você não tem permissão para realizar esta ação."
            });
            return;
        }

        next();
    };
}