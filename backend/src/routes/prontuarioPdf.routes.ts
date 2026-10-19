import { Router } from "express";
import { ObjectId, type Document, type Filter } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { gerarProntuarioPdf } from "../services/prontuarioPdf.service.js";

const router = Router();

// Aceita tanto IDs antigos em texto quanto IDs novos do MongoDB.
// Também cobre registros cujo ID hexadecimal foi salvo como string.
function filtroId(id: string): Filter<Document> {
    const idsPossiveis: Array<string | ObjectId> = [id];

    if (ObjectId.isValid(id)) {
        idsPossiveis.push(new ObjectId(id));
    }

    return {
        _id: { $in: idsPossiveis }
    } as Filter<Document>;
}

router.get("/:id/prontuario/pdf", autenticar, async (req, res) => {
    try {
        const id = String(req.params.id ?? "").trim();

        if (!id) {
            return res.status(400).json({
                mensagem: "Identificador da consulta não informado."
            });
        }

        const usuarioId = String(res.locals.usuarioId ?? "");
        const tipo = String(res.locals.usuarioTipo ?? "").toUpperCase();

        if (!ObjectId.isValid(usuarioId)) {
            return res.status(401).json({
                mensagem: "Sessão inválida."
            });
        }

        const banco = obterBanco();

        const consulta = await banco.collection<Document>("consultas").findOne(
            filtroId(id)
        );

        if (!consulta) {
            return res.status(404).json({
                mensagem: "Consulta não encontrada."
            });
        }

        const petId = String(consulta.petId ?? "");
        const pet = await banco.collection<Document>("pets").findOne(
            filtroId(petId)
        );

        if (!pet) {
            return res.status(404).json({
                mensagem: "Pet da consulta não encontrado."
            });
        }

        const contaId = new ObjectId(usuarioId);
        let autorizado = false;

        if (tipo === "USUARIO") {
            // O tutor precisa ser o responsável pelo pet desta consulta.
            const tutorVinculado = await banco.collection<Document>("tutores").findOne({
                ...filtroId(String(pet.tutorId ?? "")),
                usuarioId: contaId
            });

            autorizado = Boolean(tutorVinculado);
        } else if (tipo === "VETERINARIO") {
            // Somente o veterinário responsável pela consulta.
            const veterinarioVinculado = await banco.collection<Document>("veterinarios").findOne({
                ...filtroId(String(consulta.veterinarioId ?? "")),
                usuarioId: contaId,
                ativo: true
            });

            autorizado = Boolean(veterinarioVinculado);
        } else if (tipo === "ENFERMEIRO") {
            // Profissional ativo autorizado à assistência clínica.
            const enfermeiro = await banco.collection<Document>("enfermeiros").findOne({
                usuarioId: contaId,
                ativo: true
            });

            autorizado = Boolean(enfermeiro);
        }

        if (!autorizado) {
            return res.status(403).json({
                mensagem: "Acesso negado ao prontuário desta consulta."
            });
        }

        // Os registros clínicos armazenam consultaId como texto.
        const consultaIdTexto = String(consulta._id);

        const [triagem, atendimento, tutor, veterinario] = await Promise.all([
            banco.collection<Document>("triagens").findOne({
                consultaId: consultaIdTexto
            }),
            banco.collection<Document>("atendimentos").findOne({
                consultaId: consultaIdTexto
            }),
            banco.collection<Document>("tutores").findOne(
                filtroId(String(pet.tutorId ?? ""))
            ),
            banco.collection<Document>("veterinarios").findOne(
                filtroId(String(consulta.veterinarioId ?? ""))
            )
        ]);

        if (consulta.status !== "finalizada" || !atendimento) {
            return res.status(409).json({
                mensagem: "O prontuário em PDF estará disponível após o atendimento ser registrado e a consulta finalizada."
            });
        }

        const nomeArquivo = `prontuario-${consultaIdTexto.replace(/[^a-zA-Z0-9_-]/g, "")}.pdf`;

        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `attachment; filename="${nomeArquivo}"`);
        res.setHeader("Cache-Control", "no-store");
        res.setHeader("X-Content-Type-Options", "nosniff");

        gerarProntuarioPdf(res, {
            consultaId: consultaIdTexto,
            dataConsulta: consulta.dataHora,
            status: String(consulta.status),
            pet: {
                nome: String(pet.nome ?? "Não informado"),
                especie: pet.especie,
                raca: pet.raca,
                sexo: pet.sexo
            },
            tutorNome: tutor?.nome,
            veterinarioNome: veterinario?.nome,
            triagem: triagem ? {
                peso: triagem.peso,
                temperatura: triagem.temperatura,
                sintomas: triagem.sintomas,
                observacoes: triagem.observacoes,
                dataHora: triagem.dataHora
            } : null,
            atendimento: {
                anamnese: atendimento.anamnese,
                exameFisico: atendimento.exameFisico,
                diagnostico: atendimento.diagnostico,
                prognostico: atendimento.prognostico,
                codigoICDVet: atendimento.codigoICDVet,
                tratamento: atendimento.tratamento,
                observacoes: atendimento.observacoes,
                dataHora: atendimento.dataHora
            }
        });
    } catch (erro) {
        console.error("Erro ao gerar PDF do prontuário:", erro);

        if (!res.headersSent) {
            return res.status(500).json({
                mensagem: "Erro ao gerar PDF do prontuário."
            });
        }

        res.destroy();
    }
});

export default router;
