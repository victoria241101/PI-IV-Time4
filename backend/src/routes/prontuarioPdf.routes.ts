// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId, type Document, type Filter } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { gerarProntuarioPdf } from "../services/prontuarioPdf.service.js";

const router = Router();

// aceita tanto ids antigos em texto quanto ids novos do mongodb
// também cobre registros cujo id hexadecimal foi salvo como string
function filtroId(id: string): Filter<Document> {
    const idsPossiveis: Array<string | ObjectId> = [id];

    if (ObjectId.isValid(id)) {
        idsPossiveis.push(new ObjectId(id));
    }

    return {
        _id: { $in: idsPossiveis }
    } as Filter<Document>;
}

// gera o pdf do prontuário da consulta
router.get("/:id/prontuario/pdf", autenticar, async (req, res) => {
    try {
        const id = String(req.params.id ?? "").trim();

        if (!id) {
            return res.status(400).json({
                mensagem: "Identificador da consulta não informado."
            });
        }

        // pega o id que a autenticação colocou na resposta
        const usuarioId = String(res.locals.usuarioId ?? "");
        const tipo = String(res.locals.usuarioTipo ?? "").toUpperCase();

        // confere se o id está no formato esperado pelo banco
        if (!ObjectId.isValid(usuarioId)) {
            return res.status(401).json({
                mensagem: "Sessão inválida."
            });
        }

        const banco = obterBanco();

        // busca a consulta usada para montar o prontuário
        const consulta = await banco.collection<Document>("consultas").findOne(
            filtroId(id)
        );

        if (!consulta) {
            return res.status(404).json({
                mensagem: "Consulta não encontrada."
            });
        }

        const petId = String(consulta.petId ?? "");
        // carrega os dados do pet vinculado à consulta
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
            // o tutor precisa ser o responsável pelo pet desta consulta
            const tutorVinculado = await banco.collection<Document>("tutores").findOne({
                ...filtroId(String(pet.tutorId ?? "")),
                usuarioId: contaId
            });

            autorizado = Boolean(tutorVinculado);
        } else if (tipo === "VETERINARIO") {
            // somente o veterinário responsável pela consulta
            const veterinarioVinculado = await banco.collection<Document>("veterinarios").findOne({
                ...filtroId(String(consulta.veterinarioId ?? "")),
                usuarioId: contaId,
                ativo: true
            });

            autorizado = Boolean(veterinarioVinculado);
        } else if (tipo === "ENFERMEIRO") {
            // profissional ativo autorizado à assistência clínica
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

        // os registros clínicos armazenam consultaid como texto
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

        // prepara a resposta para baixar o arquivo pdf
        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `attachment; filename="${nomeArquivo}"`);
        res.setHeader("Cache-Control", "no-store");
        res.setHeader("X-Content-Type-Options", "nosniff");

        // envia os dados do pet e da consulta para montar o pdf
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

        // só envia a mensagem de erro se a resposta ainda não começou
        if (!res.headersSent) {
            return res.status(500).json({
                mensagem: "Erro ao gerar PDF do prontuário."
            });
        }

        // encerra a resposta se deu erro depois que o envio começou
        res.destroy();
    }
});

export default router;
