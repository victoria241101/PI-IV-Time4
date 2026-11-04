import { Router } from "express";
import { obterBanco } from "../database.js";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";

const router = Router();

// Listar veterinários ativos
router.get(
    "/",
    autenticar,
    permitirFuncoes("USUARIO", "SECRETARIA"),
    async (_req, res) => {
        try {
            const veterinarios = await obterBanco()
                .collection("veterinarios")
                .find({ ativo: true })
                .project({
                    _id: 1,
                    nome: 1,
                    especialidade: 1
                })
                .toArray();

            return res.status(200).json({
                veterinarios
            });

        } catch (erro) {
            console.error("Erro ao listar veterinários:", erro);

            return res.status(500).json({
                mensagem: "Erro ao buscar veterinários."
            });
        }
    }
);

export default router;