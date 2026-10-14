
import type { Request, Response, NextFunction } from "express";
import { verificarToken } from "../jwtService.js";
import { obterBanco } from "../database.js";
import { ObjectId, type Filter } from "mongodb";

export async function autenticar(
    req: Request,
    res: Response,
    next: NextFunction
) {
    const autorizacao = req.headers.authorization;

    if (!autorizacao || !autorizacao.startsWith("Bearer ")) {
        res.status(401).json({
            mensagem: "Token de autenticação não informado."
        });
        return;
    }

    const token = autorizacao.slice(7);

    if (!token) {
        res.status(401).json({
            mensagem: "Token de autenticação não informado."
        });
        return;
    }

    
    let usuarioId: string;

    try {
        usuarioId = await verificarToken(token);
    } catch {
        return res.status(401).json({
            mensagem: "Token inválido ou expirado."
        });
    }

    try {
        const banco = obterBanco();

        
    type UsuarioDocumento = {
        _id: ObjectId | string;
        ativo?: boolean;
        tipo?: string;
    };

    const usuarios = banco.collection<UsuarioDocumento>("usuarios");

    const filtro: Filter<UsuarioDocumento> = {
        _id: ObjectId.isValid(usuarioId)
            ? new ObjectId(usuarioId)
            : usuarioId
    };

    const usuario = await usuarios.findOne(filtro);


        if (!usuario || usuario.ativo !== true) {
            return res.status(401).json({
                mensagem: "Usuário não encontrado ou inativo."
            });
        }

        res.locals.usuarioId = usuarioId;
        res.locals.usuarioTipo = usuario.tipo;

        

    } catch (erro) {
        console.error("Erro ao consultar usuário autenticado:", erro);

        return res.status(503).json({
            mensagem: "Serviço de autenticação temporariamente indisponível."
        });
    }
    
    next();

}
