import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// Registra a administração de um medicamento
router.post(
    "/",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const {
                prescricaoId,
                doseAdministrada,
                horarioPrevisto,
                observacoes
            } = req.body;

            // Verifica os campos obrigatórios
            if (
                typeof prescricaoId !== "string" ||
                !prescricaoId.trim() ||
                typeof doseAdministrada !== "string" ||
                !doseAdministrada.trim() ||
                typeof horarioPrevisto !== "string" ||
                !horarioPrevisto.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Preencha os campos obrigatórios."
                });
            }

            if (
                observacoes !== undefined &&
                typeof observacoes !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
            }

            // Verifica se o horário informado é válido
            const dataPrevista = new Date(horarioPrevisto);

            if (isNaN(dataPrevista.getTime())) {
                return res.status(400).json({
                    mensagem: "Horário previsto inválido."
                });
            }

            const banco = obterBanco();

            // Identifica o enfermeiro logado
            const enfermeiro = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("enfermeiros").findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!enfermeiro) {
                return res.status(403).json({
                    mensagem: "Enfermeiro não encontrado ou inativo."
                });
            }

            // Procura a prescrição
            const idsPrescricao: (string | ObjectId)[] = [prescricaoId];

            if (ObjectId.isValid(prescricaoId)) {
                idsPrescricao.push(new ObjectId(prescricaoId));
            }

            const prescricao = await banco.collection<{
                _id: string | ObjectId;
                petId: string | ObjectId;
                medicamento: string;
                status: string;
            }>("prescricoes").findOne({
                _id: { $in: idsPrescricao },
                status: "ativa"
            });

            if (!prescricao) {
                return res.status(404).json({
                    mensagem: "Prescrição ativa não encontrada."
                });
            }

            // Confere se essa dose já foi registrada
            const administracoes = banco.collection("administracoes");

            const administracaoExistente = await administracoes.findOne({
                prescricaoId: prescricao._id,
                horarioPrevisto: dataPrevista
            });

            if (administracaoExistente) {
                return res.status(409).json({
                    mensagem: "Esta dose já foi registrada."
                });
            }

            // Registra a administração
            const resultado = await administracoes.insertOne({
                prescricaoId: prescricao._id,
                petId: prescricao.petId,
                enfermeiroId: enfermeiro._id,
                medicamento: prescricao.medicamento,
                doseAdministrada: doseAdministrada.trim(),
                horarioPrevisto: dataPrevista,
                dataAdministracao: new Date(),
                observacoes: observacoes?.trim() ?? "",
                status: "administrado"
            });

            return res.status(201).json({
                mensagem: "Administração registrada com sucesso!",
                administracaoId: resultado.insertedId
            });

        } catch (erro) {

            // O MongoDB usa o código 11000 para índice único duplicado
            if (
                erro instanceof Error &&
                "code" in erro &&
                erro.code === 11000
            ) {
                return res.status(409).json({
                    mensagem: "Esta dose já foi registrada."
                });
            }

            console.error("Erro ao registrar administração:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar administração."
            });
        }
    }
);

// Lista as administrações de medicamentos de um pet
router.get(
    "/pet/:petId",
    autenticar,
    permitirFuncoes("VETERINARIO", "ENFERMEIRO"),
    async (req, res) => {
        try {
            const petId = req.params.petId;

            if (typeof petId !== "string" || !petId.trim()) {
                return res.status(400).json({
                    mensagem: "ID do pet inválido."
                });
            }

            const banco = obterBanco();
            const usuarioId = new ObjectId(res.locals.usuarioId);
            const tipo = res.locals.usuarioTipo;

            // Verifica se o profissional está ativo
            const colecaoProfissionais =
                tipo === "VETERINARIO"
                    ? "veterinarios"
                    : "enfermeiros";

            const profissional = await banco
                .collection(colecaoProfissionais)
                .findOne({
                    usuarioId,
                    ativo: true
                });

            if (!profissional) {
                return res.status(403).json({
                    mensagem: "Profissional não encontrado ou inativo."
                });
            }

            // Aceita IDs antigos e ObjectIds
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Verifica se o pet existe
            const pet = await banco.collection<{
                _id: string | ObjectId;
            }>("pets").findOne({
                _id: { $in: idsPet }
            });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Busca as administrações registradas
            const administracoes = await banco
                .collection("administracoes")
                .find({
                    petId: { $in: idsPet }
                })
                .sort({ dataAdministracao: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Administrações encontradas com sucesso!",
                administracoes
            });

        } catch (erro) {
            console.error("Erro ao consultar administrações:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar administrações."
            });
        }
    }
);


export default router;