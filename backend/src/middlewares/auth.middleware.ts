// Alinne Monteiro de Melo | RA: 24801649

import type { Request, Response, NextFunction } from "express";
import { verificarToken } from "../jwtService.js";
import { obterBanco } from "../database.js";
import { ObjectId, type Filter } from "mongodb";

// confere o token e se a conta ainda está ativa
export async function autenticar(
    req: Request,
    res: Response,
    next: NextFunction
) {
    // pega o cabeçalho de autorização da requisição
    const autorizacao = req.headers.authorization;

    // exige o formato bearer seguido do token
    if (!autorizacao || !autorizacao.startsWith("Bearer ")) {
        res.status(401).json({
            mensagem: "Token de autenticação não informado."
        });
        return;
    }

    // remove o prefixo bearer para ficar só com o token
    const token = autorizacao.slice(7);

    if (!token) {
        res.status(401).json({
            mensagem: "Token de autenticação não informado."
        });
        return;
    }

    
    let usuarioId: string;

    try {
        // valida o token e lê o id do usuário
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

    // usa o id no formato do mongodb quando possível e aceita id em texto
    const filtro: Filter<UsuarioDocumento> = {
        _id: ObjectId.isValid(usuarioId)
            ? new ObjectId(usuarioId)
            : usuarioId
    };

    // consulta a conta para conferir se ela continua ativa
    const usuario = await usuarios.findOne(filtro);


        if (!usuario || usuario.ativo !== true) {
            return res.status(401).json({
                mensagem: "Usuário não encontrado ou inativo."
            });
        }

        // guarda o id e o tipo da conta para os próximos middlewares
        res.locals.usuarioId = usuarioId;
        res.locals.usuarioTipo = usuario.tipo;

        

    } catch (erro) {
        // registra a falha na consulta e devolve erro de serviço indisponível
        console.error("Erro ao consultar usuário autenticado:", erro);

        return res.status(503).json({
            mensagem: "Serviço de autenticação temporariamente indisponível."
        });
    }
    
    // segue para a próxima etapa depois de validar a conta
    next();

}

// aceita visitantes e valida o usuário quando ele envia um token
export async function autenticarOpcional(
    req: Request,
    res: Response,
    next: NextFunction
) {
    const autorizacao = req.headers.authorization;

    // visitante sem token pode continuar
    if (!autorizacao) {
        next();
        return;
    }

    // se enviou autenticação, precisa ser válida
    if (!autorizacao.startsWith("Bearer ")) {
        res.status(401).json({
            mensagem: "Formato de autenticação inválido."
        });
        return;
    }

    // pega a parte do cabeçalho que deve conter o token
    const token = autorizacao.slice(7);

    if (!token) {
        res.status(401).json({
            mensagem: "Token de autenticação não informado."
        });
        return;
    }

    // reaproveita a autenticação existente
    await autenticar(req, res, next);
}
