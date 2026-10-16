import { Router } from "express";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco, obterCliente } from "../database.js";
import { ObjectId } from "mongodb";

const router = Router();


router.post("/", autenticar, async (req, res) => {
    const { nome, especie, raca, sexo } = req.body;

    // Validar os dados do pet
    if (
        typeof nome !== "string" || !nome.trim() ||
        typeof especie !== "string" || !especie.trim() ||
        typeof raca !== "string" || !raca.trim() ||
        typeof sexo !== "string" || !sexo.trim()
    ) {
        return res.status(400).json({
            mensagem: "Preencha todos os campos do pet."
        });
    }

    const usuarioId = new ObjectId(res.locals.usuarioId);

    const cliente = obterCliente();
    const sessao = cliente.startSession();

    try {
        const banco = obterBanco();
        const tutores = banco.collection("tutores");
        const pets = banco.collection("pets");

        let petId: ObjectId | undefined;

        await sessao.withTransaction(async () => {
            // Procurar tutor existente
            let tutor = await tutores.findOne(
                { usuarioId },
                { session: sessao }
            );

            // Criar tutor se ainda não existir
            if (!tutor) {
                const novoTutor = {
                    _id: new ObjectId(),
                    usuarioId
                };

                await tutores.insertOne(novoTutor, {
                    session: sessao
                });

                tutor = novoTutor;
            }

            // Criar pet vinculado ao tutor
            petId = new ObjectId();

            await pets.insertOne(
                {
                    _id: petId,
                    tutorId: tutor._id,
                    nome: nome.trim(),
                    especie: especie.trim(),
                    raca: raca.trim(),
                    sexo: sexo.trim(),
                    ativo: true
                },
                { session: sessao }
            );
        });

        return res.status(201).json({
            mensagem: "Pet cadastrado com sucesso!",
            petId: petId?.toString()
        });

    } catch (erro) {
        console.error("Erro ao cadastrar pet:", erro);

        return res.status(503).json({
            mensagem: "Não foi possível cadastrar o pet."
        });

    } finally {
        await sessao.endSession();
    }
});


router.get("/", autenticar, async (req, res) => {
    try {
        // Identifica o usuário autenticado pelo JWT
        const usuarioId = new ObjectId(res.locals.usuarioId);

        const banco = obterBanco();

        // Procura o tutor vinculado ao usuário
        const tutor = await banco.collection("tutores").findOne({
            usuarioId
        });

        // Se não possui tutor, ainda não possui pets
        if (!tutor) {
            return res.status(200).json({
                mensagem: "Nenhum pet cadastrado.",
                pets: []
            });
        }

        // Busca apenas os pets ativos desse tutor
        const pets = await banco.collection("pets")
            .find({
                tutorId: tutor._id,
                ativo: true
            })
            .toArray();

        return res.status(200).json({
            mensagem: "Pets encontrados com sucesso!",
            pets
        });

    } catch (erro) {
        console.error("Erro ao listar pets:", erro);

        return res.status(500).json({
            mensagem: "Erro ao buscar pets do usuário."
        });
    }
});


router.put("/:id", autenticar, async (req, res) => {
    const { nome, especie, raca, sexo } = req.body;

    // Validar os dados recebidos
    if (
        typeof nome !== "string" || !nome.trim() ||
        typeof especie !== "string" || !especie.trim() ||
        typeof raca !== "string" || !raca.trim() ||
        typeof sexo !== "string" || !sexo.trim()
    ) {
        return res.status(400).json({
            mensagem: "Preencha todos os campos do pet."
        });
    }

    // Validar o ID do pet
    const petId = req.params.id;

    if (typeof petId !== "string" || !ObjectId.isValid(petId)) {
    return res.status(400).json({
        mensagem: "ID do pet inválido."
    });
}

    try {
        const banco = obterBanco();

        // Identificar o tutor autenticado
        const usuarioId = new ObjectId(res.locals.usuarioId);

        const tutor = await banco.collection("tutores").findOne({
            usuarioId
        });

        if (!tutor) {
            return res.status(404).json({
                mensagem: "Pet não encontrado."
            });
        }

        // Atualizar somente se o pet pertencer ao tutor
        const resultado = await banco.collection("pets").updateOne(
            {
                _id: new ObjectId(petId),
                tutorId: tutor._id,
                ativo: true
            },
            {
                $set: {
                    nome: nome.trim(),
                    especie: especie.trim(),
                    raca: raca.trim(),
                    sexo: sexo.trim()
                }
            }
        );

        if (resultado.matchedCount === 0) {
            return res.status(404).json({
                mensagem: "Pet não encontrado."
            });
        }

        return res.status(200).json({
            mensagem: "Pet atualizado com sucesso!"
        });

    } catch (erro) {
        console.error("Erro ao atualizar pet:", erro);

        return res.status(500).json({
            mensagem: "Erro ao atualizar pet."
        });
    }
});


router.delete("/:id", autenticar, async (req, res) => {
    const petId = req.params.id;

    // Validar o ID recebido
    if (typeof petId !== "string" || !ObjectId.isValid(petId)) {
    return res.status(400).json({
        mensagem: "ID do pet inválido."
    });
}

    try {
        const banco = obterBanco();

        // Identificar o usuário autenticado
        const usuarioId = new ObjectId(res.locals.usuarioId);

        // Encontrar o tutor desse usuário
        const tutor = await banco.collection("tutores").findOne({
            usuarioId
        });

        if (!tutor) {
            return res.status(404).json({
                mensagem: "Pet não encontrado."
            });
        }

        // Desativar somente um pet pertencente ao tutor
        const resultado = await banco.collection("pets").updateOne(
            {
                _id: new ObjectId(petId),
                tutorId: tutor._id,
                ativo: true
            },
            {
                $set: {
                    ativo: false
                }
            }
        );

        if (resultado.matchedCount === 0) {
            return res.status(404).json({
                mensagem: "Pet não encontrado."
            });
        }

        return res.status(200).json({
            mensagem: "Pet excluído com sucesso!"
        });

    } catch (erro) {
        console.error("Erro ao excluir pet:", erro);

        return res.status(500).json({
            mensagem: "Erro ao excluir pet."
        });
    }
});

router.get("/:id/historico-clinico", autenticar, async (req, res) => {
    try {
        const petId = req.params.id;

        if (typeof petId !== "string" || !petId.trim()) {
            return res.status(400).json({
                mensagem: "ID do pet inválido."
            });
        }

        const banco = obterBanco();
        const usuarioId = new ObjectId(res.locals.usuarioId);

        // Nosso banco possui IDs antigos em texto e novos ObjectIds
        const idsPossiveis: (string | ObjectId)[] = [petId];

        if (ObjectId.isValid(petId)) {
            idsPossiveis.push(new ObjectId(petId));
        }

        const pet = await banco.collection<{ _id: string | ObjectId; tutorId: string | ObjectId; nome: string; especie: string; raca: string }>("pets").findOne({
            _id: { $in: idsPossiveis }
        });

        if (!pet) {
            return res.status(404).json({
                mensagem: "Pet não encontrado."
            });
        }

        // Verifica se o usuário é tutor desse pet
        const tutor = await banco.collection<{
            _id: string | ObjectId;
            usuarioId: ObjectId;
        }>("tutores").findOne({
            _id: pet.tutorId,
            usuarioId
        });

        // Verifica se é um veterinário ativo
        const veterinario = await banco.collection("veterinarios").findOne({
            usuarioId,
            ativo: true
        });

        if (!tutor && !veterinario) {
            return res.status(403).json({
                mensagem: "Você não tem permissão para consultar este histórico."
            });
        }

        // Busca todas as consultas do pet
        const consultas = await banco.collection("consultas")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataHora: -1 })
            .toArray();
        
        
        // Busca os procedimentos realizados no pet
        const procedimentos = await banco.collection("procedimentos")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataHora: -1 })
            .toArray();


        // Busca as internações do pet
        const internacoes = await banco.collection("internacoes")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataEntrada: -1 })
            .toArray();    
        
        // Busca as prescrições veterinárias do pet
        const prescricoes = await banco.collection("prescricoes")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataPrescricao: -1 })
            .toArray();
        
        // Busca os exames solicitados para o pet
        const exames = await banco.collection("exames")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataSolicitacao: -1 })
            .toArray();

        // Busca os medicamentos administrados ao pet
        const administracoes = await banco.collection("administracoes")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataAdministracao: -1 })
            .toArray();

        // Busca as tarefas clínicas do pet
        const tarefasClinicas = await banco
            .collection("tarefasClinicas")
            .find({
                petId: { $in: idsPossiveis }
            })
            .sort({ dataCriacao: -1 })
            .toArray();  
            
        const historico = await Promise.all(
            consultas.map(async (consulta) => {

                const triagem = await banco.collection("triagens")
                    .findOne({ consultaId: consulta._id });

                const atendimento = await banco.collection("atendimentos")
                    .findOne({ consultaId: consulta._id });

                return {
                    consulta,
                    triagem,
                    atendimento
                };
            })
        );

        return res.status(200).json({
            mensagem: "Histórico clínico encontrado com sucesso!",
            pet: {
                id: pet._id,
                nome: pet.nome,
                especie: pet.especie,
                raca: pet.raca
            },
            historico,
            procedimentos,
            internacoes,
            prescricoes,
            exames,
            administracoes,
            tarefasClinicas
        });

    } catch (erro) {
        console.error("Erro ao consultar histórico clínico:", erro);

        return res.status(500).json({
            mensagem: "Erro ao consultar histórico clínico."
        });
    }
});

export default router;



