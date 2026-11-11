import { Router, type RequestHandler } from 'express';
import { randomBytes } from 'node:crypto';
import { ObjectId, MongoServerError, type Db, type MongoClient, type Document } from 'mongodb';
import { permitirFuncoes } from '../middlewares/permissoes.middleware.js';

const referencias = (id: unknown) => {
    if (id == null) return [];
    const texto = String(id);
    return ObjectId.isValid(texto) ? [texto, new ObjectId(texto)] : [texto];
};
const cpfValido = (cpf: string) => {
    if (!/^\d{11}$/.test(cpf) || /^(\d)\1{10}$/.test(cpf)) return false;
    for (const n of [9, 10]) {
        let soma = 0;
        for (let i = 0; i < n; i++) soma += Number(cpf[i]) * (n + 1 - i);
        const digito = (soma * 10) % 11;
        if ((digito === 10 ? 0 : digito) !== Number(cpf[n])) return false;
    }
    return true;
};
class CadastroInvalido extends Error {
    readonly status: number;
    constructor(status: number, mensagem: string) { super(mensagem); this.status = status; }
}

export function criarRotasCadastrosRecepcao(deps: {
    obterBanco: () => Db; obterCliente: () => MongoClient;
    autenticar: RequestHandler; gerarHash: (senha: string) => Promise<string>;
}) {
    const router = Router();
    router.use(deps.autenticar, permitirFuncoes('SECRETARIA'));

    // Cadastro atual guarda nome/CPF no usuário; registros antigos também têm esses dados no tutor.
    router.get('/tutores', async (req, res) => {
        const cpf = typeof req.query.cpf === 'string' ? req.query.cpf.replace(/\D/g, '') : '';
        if (!cpfValido(cpf)) return res.status(400).json({ mensagem: 'CPF inválido.' });
        try {
            const banco = deps.obterBanco();
            const usuario = await banco.collection('usuarios').findOne({ cpf },
                { projection: { nome: 1, email: 1, cpf: 1, tipo: 1, ativo: 1 } });
            if (usuario && (!['USUARIO', 'TUTOR'].includes(String(usuario.tipo).toUpperCase()) || usuario.ativo !== true)) {
                return res.status(409).json({ mensagem: 'Este CPF não pertence a uma conta ativa de tutor.' });
            }
            const tutor = await banco.collection('tutores').findOne({ $or: [
                { cpf }, ...(usuario ? [{ usuarioId: { $in: referencias(usuario._id) } }] : [])
            ] });
            if (!tutor && !usuario) return res.status(404).json({ mensagem: 'Tutor não encontrado.' });
            const pets = tutor ? await banco.collection('pets').find(
                { tutorId: { $in: referencias(tutor._id) }, ativo: { $ne: false } },
                { projection: { nome: 1, especie: 1, raca: 1, sexo: 1, dataNascimento: 1 } }
            ).toArray() : [];
            return res.json({ tutor: { id: tutor ? String(tutor._id) : null, cpf,
                nome: usuario?.nome ?? tutor?.nome ?? '', email: usuario?.email ?? '',
                telefone: tutor?.telefone ?? '' },
                pets: pets.map(p => ({ id: String(p._id), nome: p.nome, especie: p.especie,
                    raca: p.raca, sexo: p.sexo, dataNascimento: p.dataNascimento ?? null })) });
        } catch { return res.status(503).json({ mensagem: 'Não foi possível consultar o tutor.' }); }
    });

    router.post('/tutores-pets', async (req, res) => {
        const { nome, email, cpf: cpfRecebido, telefone, pet, solicitacaoId } = req.body ?? {};
        const cpf = typeof cpfRecebido === 'string' ? cpfRecebido.replace(/\D/g, '') : '';
        const emailNormalizado = typeof email === 'string' ? email.trim().toLowerCase() : '';
        if (typeof nome !== 'string' || !nome.trim() || !cpfValido(cpf) ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailNormalizado) ||
            typeof telefone !== 'string' || !/^\d{10,11}$/.test(telefone.replace(/\D/g, '')) ||
            typeof solicitacaoId !== 'string' || !/^[a-f\d]{24}$/.test(solicitacaoId) ||
            !pet || ['nome','especie','raca','sexo'].some(c => typeof pet[c] !== 'string' || !pet[c].trim())) {
            return res.status(400).json({ mensagem: 'Preencha nome, CPF, e-mail, telefone e os dados do pet.' });
        }
        if (pet.dataNascimento != null && (typeof pet.dataNascimento !== 'string' ||
            !/^\d{4}-\d{2}-\d{2}$/.test(pet.dataNascimento) ||
            !Number.isFinite(Date.parse(pet.dataNascimento)) ||
            new Date(pet.dataNascimento).toISOString().slice(0,10) !== pet.dataNascimento ||
            pet.dataNascimento > new Date().toISOString().slice(0,10))) {
            return res.status(400).json({ mensagem: 'Data de nascimento inválida.' });
        }
        const banco = deps.obterBanco();
        const sessao = deps.obterCliente().startSession();
        try {
            let resultado: Document | undefined;
            await sessao.withTransaction(async () => {
                const opcoes = { session: sessao };
                const usuarios = banco.collection('usuarios');
                const contas = await usuarios.find({ $or: [{ cpf }, { email: emailNormalizado }] }, opcoes).limit(2).toArray();
                let usuario = contas[0];
                if (contas.length > 1 || (usuario && (usuario.cpf !== cpf || usuario.email !== emailNormalizado ||
                    !['USUARIO','TUTOR'].includes(String(usuario.tipo).toUpperCase()) || usuario.ativo !== true))) {
                    throw new CadastroInvalido(409, 'CPF ou e-mail já pertence a outro cadastro. Confira os dados.');
                }
                const tutores = banco.collection('tutores');
                const candidatos = await tutores.find({ $or: [{ cpf },
                    ...(usuario ? [{ usuarioId: { $in: referencias(usuario._id) } }] : [])] }, opcoes).limit(2).toArray();
                let tutor = candidatos[0];
                if (candidatos.length > 1 || (tutor?.usuarioId != null &&
                    (!usuario || String(tutor.usuarioId) !== String(usuario._id)))) {
                    throw new CadastroInvalido(409, 'O tutor possui um vínculo diferente. Confira o cadastro existente.');
                }
                const contaCriada = !usuario;
                if (!usuario) {
                    // Senha aleatória não é exibida nem enviada. O tutor usa a recuperação existente.
                    const senhaHash = await deps.gerarHash(randomBytes(32).toString('hex'));
                    usuario = { _id: new ObjectId(), nome: nome.trim(), email: emailNormalizado,
                        cpf, senhaHash, tipo: 'USUARIO', ativo: true };
                    await usuarios.insertOne(usuario, opcoes);
                }
                if (!tutor) {
                    tutor = { _id: new ObjectId(), usuarioId: usuario._id, nome: usuario.nome,
                        cpf, telefone: telefone.replace(/\D/g, '') };
                    await tutores.insertOne(tutor, opcoes);
                } else if (tutor.usuarioId == null) {
                    await tutores.updateOne({ _id: tutor._id }, { $set: { usuarioId: usuario._id } }, opcoes);
                }
                const petId = new ObjectId(solicitacaoId);
                const documentoPet = { _id: petId, tutorId: tutor._id, nome: pet.nome.trim(),
                    especie: pet.especie.trim(), raca: pet.raca.trim(), sexo: pet.sexo.trim(),
                    ...(pet.dataNascimento ? { dataNascimento: pet.dataNascimento } : {}), ativo: true };
                const existente = await banco.collection('pets').findOne({ _id: petId }, opcoes);
                if (existente) {
                    if (String(existente.tutorId) !== String(tutor._id) ||
                        ['nome','especie','raca','sexo','dataNascimento'].some(c => existente[c] !== (documentoPet as Document)[c])) {
                        throw new CadastroInvalido(409, 'Esta solicitação já foi usada para outro cadastro.');
                    }
                } else { await banco.collection('pets').insertOne(documentoPet, opcoes); }
                resultado = { tutorId: String(tutor._id), petId: String(petId), contaCriada,
                    nome: usuario.nome, email: usuario.email };
            });
            return res.status(201).json({ mensagem: 'Tutor e pet cadastrados.', ...resultado });
        } catch (erro) {
            if (erro instanceof CadastroInvalido) return res.status(erro.status).json({ mensagem: erro.message });
            if (erro instanceof MongoServerError && erro.code === 11000) {
                return res.status(409).json({ mensagem: 'Cadastro já existente. Consulte o tutor pelo CPF.' });
            }
            return res.status(503).json({ mensagem: 'Não foi possível salvar o cadastro. Tente novamente.' });
        } finally { await sessao.endSession(); }
    });
    return router;
}
