import { Router } from "express";
import { ObjectId, MongoServerError } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco, obterCliente } from "../database.js";

const router = Router();

// Horário de funcionamento da clínica (configuração provisória)
const INICIO = 8;
const FIM = 18;
const PASSO = 30;
const DURACOES = [30, 60, 90, 120];
const TIPOS = [
    "consulta_geral",
    "vacinacao",
    "dermatologia",
    "odontologia",
    "retorno",
    "exames_laboratoriais"
];

const STATUS_OCUPADOS = [
    "agendada",
    "chegada_confirmada",
    "em_triagem",
    "aguardando_veterinario",
    "em_consulta"
];

type Consulta = {
    _id: string;
    petId: string;
    veterinarioId: string;
    tutorId: string | ObjectId;
    dataHora: string;
    duracaoMinutos: number;
    status: string;
    tipo: string;
    observacoes: string;
    criadoEm: Date;
    atualizadoEm?: Date;
};

type Reserva = {
    veterinarioId: string;
    horario: string;
    consultaId: string;
};

type Pet = {
    _id: string | ObjectId;
    tutorId: string | ObjectId;
    ativo?: boolean;
};

type Tutor = {
    _id: string | ObjectId;
    usuarioId?: ObjectId;
};

type Veterinario = {
    _id: string | ObjectId;
    ativo?: boolean;
};

// Funções auxiliares
function idMongoOuString(id: string): string | ObjectId {
    const ehObjectId = ObjectId.isValid(id) &&
    new ObjectId(id).toHexString() === id.toLowerCase();

    return ehObjectId ? new ObjectId(id) : id;
}

function horaValida(valor: unknown): valor is string {
    if (
    typeof valor !== "string" ||
    !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:00$/.test(valor)
    ) {
        return false;
    }
    const data = new Date(`${valor}Z`);
    return !Number.isNaN(data.getTime()) && data.toISOString().slice(0, 19) === valor;
}

function somarMinutos(dataHora: string, minutos: number): string {
    return new Date(new Date(`${dataHora}Z`).getTime() + minutos * 60000).toISOString().slice(0, 19);
}

function horarioPermitido(dataHora: string, duracao: number): boolean {
    if (!horaValida(dataHora) || !DURACOES.includes(duracao)) {
        return false;
    }
    const h = Number(dataHora.slice(11, 13));
    const m = Number(dataHora.slice(14, 16));
    return m % PASSO === 0 && h >= INICIO && h * 60 + m + duracao <= FIM * 60;
}

function futuro(dataHora: string): boolean {
    // Horários recebidos representam a hora local da clínica (America/Sao_Paulo,
    // atualmente UTC-03). Ajustar esta conversão caso a clínica use outro fuso.
    return new Date(`${dataHora}-03:00`).getTime() > Date.now();
}

function slots(dataHora: string, duracao: number): string[] {
    return Array.from({ length: duracao / PASSO }, (_, i) => somarMinutos(dataHora, i * PASSO));
}

function dadosValidos(body: any): string | null {
    if (!body || typeof body !== "object") {
        return "Envie os dados do agendamento.";
    }
    if (typeof body.petId !== "string" || !body.petId.trim()) {
        return "Informe um petId válido.";
    }
    if (typeof body.veterinarioId !== "string" || !body.veterinarioId.trim()) {
        return "Informe um veterinarioId válido.";
    }
    if (!horaValida(body.dataHora)) {
        return "Informe dataHora no formato AAAA-MM-DDTHH:mm:00, com data real e sem fuso.";
    }
    if (!DURACOES.includes(body.duracaoMinutos)) {
        return "A duração deve ser 30, 60, 90 ou 120 minutos.";
    }
    if (!horarioPermitido(body.dataHora, body.duracaoMinutos)) {
        return "Horário fora do expediente (08h às 18h) ou da grade de 30 minutos.";
    }
    if (!futuro(body.dataHora)) {
        return "O agendamento precisa ser futuro.";
    }
    if (typeof body.tipo !== "string" || !TIPOS.includes(body.tipo)) {
        return `Tipo inválido. Opções: ${TIPOS.join(", ")}.`;
    }
    if (
    body.observacoes !== undefined &&
    (typeof body.observacoes !== "string" || body.observacoes.length > 1000)
    ) {
        return "Observações devem ser texto com até 1000 caracteres.";
    }
    return null;
}

type ResultadoPet =
    | { erro: 403 | 404; mensagem: string; pet?: never }
    | { pet: Pet; erro?: never; mensagem?: never };

async function verificarPermissaoPet(
    petId: string,
    usuarioId: string,
    funcao: string
): Promise<ResultadoPet> {
    const db = obterBanco();
    const pet = await db.collection<Pet>("pets").findOne({
        _id: idMongoOuString(petId),
        ativo: { $ne: false }
    });
    if (!pet) {
        return { erro: 404, mensagem: "Pet não encontrado ou inativo." } as const;
    }
    if (funcao === "USUARIO") {
        const tutor = await db.collection<Tutor>("tutores").findOne({
            _id: pet.tutorId,
            usuarioId: new ObjectId(usuarioId)
        });
        if (!tutor) {
            return {
                erro: 403,
                mensagem: "Você só pode agendar consultas para seus próprios pets."
            } as const;
        }
    }
    return { pet } as const;
}

async function veterinarioAtivo(id: string): Promise<boolean> {
    const vet = await obterBanco().collection<Veterinario>("veterinarios").findOne({
        _id: idMongoOuString(id),
        ativo: true
    });
    return !!vet;
}

// Verifica conflitos diretamente no TypeScript, sem depender do servidor Java.
// Os intervalos são semiabertos: [início, fim). Assim, 14h-14h30
// não conflita com 14h30-15h.
async function conflitoHorario(
    veterinarioId: string,
    dataHora: string,
    duracao: number,
    ignorarId?: string,
    gerarSugestoes = true
): Promise<{ conflito: boolean; sugestoes: string[] }> {
    const db = obterBanco();
    const dia = dataHora.slice(0, 10);

    const consultas = await db.collection<Consulta>("consultas")
        .find({
            veterinarioId,
            status: { $in: STATUS_OCUPADOS },
            dataHora: {
                $gte: `${dia}T00:00:00`,
                $lte: `${dia}T23:59:59`
            },
            ...(ignorarId ? { _id: { $ne: ignorarId } } : {})
        })
        .toArray();

    const intervalos = consultas
        .filter(consulta =>
            horaValida(consulta.dataHora) &&
            Number.isInteger(consulta.duracaoMinutos) &&
            consulta.duracaoMinutos > 0
        )
        .map(consulta => ({
            inicio: consulta.dataHora,
            fim: somarMinutos(consulta.dataHora, consulta.duracaoMinutos)
        }));

    // As reservas também são consideradas: elas protegem os slots
    // durante agendamentos concorrentes e remarcações.
    const reservas = await db.collection<Reserva>("reservasAgenda")
        .find({
            veterinarioId,
            horario: {
                $gte: `${dia}T00:00:00`,
                $lte: `${dia}T23:59:59`
            },
            ...(ignorarId ? { consultaId: { $ne: ignorarId } } : {})
        })
        .toArray();

    const horariosReservados = new Set(reservas.map(reserva => reserva.horario));

    function estaOcupado(inicio: string, minutos: number): boolean {
        const fim = somarMinutos(inicio, minutos);

        const sobrepoeConsulta = intervalos.some(intervalo =>
            inicio < intervalo.fim && intervalo.inicio < fim
        );

        const sobrepoeReserva = slots(inicio, minutos).some(horario =>
            horariosReservados.has(horario)
        );

        return sobrepoeConsulta || sobrepoeReserva;
    }

    const conflito = estaOcupado(dataHora, duracao);

    if (!conflito || !gerarSugestoes) {
        return { conflito, sugestoes: [] };
    }

    const sugestoes: string[] = [];

    for (
        let minuto = INICIO * 60;
        minuto + duracao <= FIM * 60;
        minuto += PASSO
    ) {
        const hora = String(Math.floor(minuto / 60)).padStart(2, "0");
        const minutos = String(minuto % 60).padStart(2, "0");
        const candidato = `${dia}T${hora}:${minutos}:00`;

        if (futuro(candidato) && !estaOcupado(candidato, duracao)) {
            sugestoes.push(candidato);
        }
    }

    // Primeiro os horários mais próximos do solicitado.
    const instanteSolicitado = new Date(`${dataHora}Z`).getTime();

    sugestoes.sort((primeiro, segundo) => {
        const distanciaPrimeiro = Math.abs(
            new Date(`${primeiro}Z`).getTime() - instanteSolicitado
        );
        const distanciaSegundo = Math.abs(
            new Date(`${segundo}Z`).getTime() - instanteSolicitado
        );

        return distanciaPrimeiro - distanciaSegundo || primeiro.localeCompare(segundo);
    });

    return { conflito: true, sugestoes: sugestoes.slice(0, 5) };
}

async function prepararIndice() {
    await obterBanco().collection<Reserva>("reservasAgenda").createIndex(
    { veterinarioId: 1, horario: 1 }, { unique: true, name: "horario_unico_por_veterinario" }
);
}

function conflitoMongo(erro: unknown): boolean {
    return erro instanceof MongoServerError && erro.code === 11000;
}

function erroInterno(res: any, erro: unknown) {
    console.error("Erro no agendamento:", erro);
    if (conflitoMongo(erro)) {
        return res.status(409).json({
            mensagem: "Horário ocupado. Escolha outro horário."
        });
    }
    return res.status(500).json({
        mensagem: "Não foi possível concluir a operação."
    });
}

// Consulta horários disponíveis para um veterinário em uma data.
router.get("/disponibilidade", autenticar, permitirFuncoes("USUARIO", "SECRETARIA"), async (req, res) => {
    try {
        const { veterinarioId, data, duracaoMinutos } = req.query;
        const duracao = Number(duracaoMinutos ?? 30);
        if (
            typeof veterinarioId !== "string" ||
            !veterinarioId.trim() ||
            typeof data !== "string" ||
            !/^\d{4}-\d{2}-\d{2}$/.test(data) ||
            !DURACOES.includes(duracao) ||
            !horaValida(`${data}T12:00:00`)
        ) {
            return res.status(400).json({ mensagem: "Informe veterinarioId, data (AAAA-MM-DD) e duração válida." });
        }
        if (!(await veterinarioAtivo(veterinarioId))) {
            return res.status(404).json({
                mensagem: "Veterinário não encontrado ou inativo."
            });
        }
        const reservas = await obterBanco().collection<Reserva>("reservasAgenda").find({
            veterinarioId,
            horario: {
                $gte: `${data}T00:00:00`,
                $lte: `${data}T23:59:59`
            }
        }).toArray();
        const bloqueados = new Set(reservas.map(r => r.horario));
        const disponiveis: string[] = [];
        for (let minuto = INICIO * 60; minuto + duracao <= FIM * 60; minuto += PASSO) {
            const hora = String(Math.floor(minuto / 60)).padStart(2, "0");
            const min = String(minuto % 60).padStart(2, "0");
            const dataHora = `${data}T${hora}:${min}:00`;
            if (
                !futuro(dataHora) ||
                slots(dataHora, duracao).some(s => bloqueados.has(s))
            ) {
                continue;
            }
            const resultado = await conflitoHorario(veterinarioId, dataHora, duracao, undefined, false);
            if (!resultado.conflito) {
                disponiveis.push(dataHora);
            }
        }
        return res.json({ veterinarioId, data, duracaoMinutos: duracao, horarios: disponiveis });
    } catch (erro) {
        return erroInterno(res, erro);
    }
});

// Listar agendamentos do tutor logado ou todos para secretaria.
router.get("/", autenticar, permitirFuncoes("USUARIO", "SECRETARIA"), async (_req, res) => {
    try {
        const db = obterBanco();
        let filtro: Record<string, unknown> = {};
        if (res.locals.usuarioTipo === "USUARIO") {
            const tutor = await db.collection<Tutor>("tutores").findOne({ usuarioId: new ObjectId(res.locals.usuarioId) });
            if (!tutor) {
                return res.json({ agendamentos: [] });
            }
            const pets = await db.collection<Pet>("pets").find({ tutorId: tutor._id }).toArray();
            filtro = { petId: { $in: pets.map(p => String(p._id)) } };
        }
        const agendamentos = await db.collection<Consulta>("consultas").find(filtro).sort({ dataHora: 1 }).limit(200).toArray();
        return res.json({ agendamentos });
    } catch (erro) {
        return erroInterno(res, erro);
    }
});

// Criar agendamento. A reserva de slots e a consulta são gravadas na mesma transação.
router.post("/", autenticar, permitirFuncoes("USUARIO", "SECRETARIA"), async (req, res) => {
    const erro = dadosValidos(req.body);
    if (erro) {
        return res.status(400).json({ mensagem: erro });
    }
    const { petId, veterinarioId, dataHora, duracaoMinutos, tipo } = req.body;
    const observacoes = (req.body.observacoes ?? "").trim();
    try {
        const acesso = await verificarPermissaoPet(petId, res.locals.usuarioId, res.locals.usuarioTipo);
        if (acesso.erro !== undefined) {
            return res.status(acesso.erro).json({ mensagem: acesso.mensagem });
        }
        if (!(await veterinarioAtivo(veterinarioId))) {
            return res.status(404).json({
                mensagem: "Veterinário não encontrado ou inativo."
            });
        }
        const conflito = await conflitoHorario(veterinarioId, dataHora, duracaoMinutos);
        if (conflito.conflito) {
            return res.status(409).json({
                mensagem: "Horário ocupado.",
                sugestoes: conflito.sugestoes
            });
        }
        await prepararIndice();
        const db = obterBanco();
        const id = new ObjectId().toHexString();
        const consulta: Consulta = {
            _id: id,
            petId,
            veterinarioId,
            tutorId: acesso.pet.tutorId,
            dataHora,
            duracaoMinutos,
            tipo,
            observacoes,
            status: "agendada",
            criadoEm: new Date()
        };
        const session = obterCliente().startSession();
        try {
            await session.withTransaction(async () => {
                await db.collection<Reserva>("reservasAgenda").insertMany(
                    slots(dataHora, duracaoMinutos).map(horario => ({
                        veterinarioId,
                        horario,
                        consultaId: id
                    })),
                    { session }
                );
                await db.collection<Consulta>("consultas").insertOne(consulta, { session });
            });
        } finally {
            await session.endSession();
        }
        return res.status(201).json({ mensagem: "Agendamento confirmado!", consulta });
    } catch (erro) {
        return erroInterno(res, erro);
    }
});

// Verifica o acesso antes de alterar um agendamento.
type ResultadoConsulta =
    | { erro: 403 | 404; mensagem: string; consulta?: never }
    | { consulta: Consulta; erro?: never; mensagem?: never };

async function consultaPermitida(
    id: string,
    usuarioId: string,
    funcao: string
): Promise<ResultadoConsulta> {
    const consulta = await obterBanco()
        .collection<Consulta>("consultas")
        .findOne({ _id: id });
    if (!consulta) {
        return { erro: 404, mensagem: "Consulta não encontrada." } as const;
    }
    const acesso = await verificarPermissaoPet(consulta.petId, usuarioId, funcao);
    if (acesso.erro !== undefined) {
        return acesso;
    }
    return { consulta } as const;
}

// Remarcar somente consultas ainda agendadas.
router.patch("/:id/remarcar", autenticar, permitirFuncoes("USUARIO", "SECRETARIA"), async (req, res) => {
    const parametroId = req.params.id;
    const id = typeof parametroId === "string" ? parametroId : undefined;

    if (!id) {
        return res.status(400).json({ mensagem: "Informe o código da consulta." });
    }
    const { dataHora, duracaoMinutos } = req.body ?? {};
    if (!horarioPermitido(dataHora, duracaoMinutos) || !futuro(dataHora)) {
        return res.status(400).json({ mensagem: "Informe horário futuro válido e duração de 30, 60, 90 ou 120 minutos." });
    }
    try {
        const acesso = await consultaPermitida(id, res.locals.usuarioId, res.locals.usuarioTipo);
        if (acesso.erro !== undefined) {
            return res.status(acesso.erro).json({ mensagem: acesso.mensagem });
        }
        const consulta = acesso.consulta;
        if (consulta.status !== "agendada") {
            return res.status(409).json({
                mensagem: "Apenas consultas agendadas podem ser remarcadas."
            });
        }
        if (!futuro(consulta.dataHora)) {
            return res.status(409).json({
                mensagem: "Não é possível remarcar consulta passada."
            });
        }
        const conflito = await conflitoHorario(consulta.veterinarioId, dataHora, duracaoMinutos, id);
        if (conflito.conflito) {
            return res.status(409).json({
                mensagem: "Horário ocupado.",
                sugestoes: conflito.sugestoes
            });
        }
        await prepararIndice();
        const db = obterBanco();
        const session = obterCliente().startSession();
        let alterou = false;
        try {
            await session.withTransaction(async () => {
                const atualizacao = await db.collection<Consulta>("consultas").updateOne(
                    {
                        _id: id,
                        status: "agendada",
                        dataHora: consulta.dataHora,
                        duracaoMinutos: consulta.duracaoMinutos
                    },
                    { $set: { dataHora, duracaoMinutos, atualizadoEm: new Date() } },
                    { session }
                );

                if (!atualizacao.modifiedCount) {
                    return;
                }
                await db.collection<Reserva>("reservasAgenda").deleteMany({ consultaId: id }, { session });
                await db.collection<Reserva>("reservasAgenda").insertMany(
                    slots(dataHora, duracaoMinutos).map(horario => ({
                        veterinarioId: consulta.veterinarioId,
                        horario,
                        consultaId: id
                    })),
                    { session }
                );
                alterou = true;
            });
        } finally {
            await session.endSession();
        }
        if (!alterou) {
            return res.status(409).json({
                mensagem: "Consulta alterada por outra operação. Tente novamente."
            });
        }
        return res.json({ mensagem: "Consulta remarcada com sucesso!", consultaId: id, dataHora, duracaoMinutos });
    } catch (erro) {
        return erroInterno(res, erro);
    }
});

// Cancelar somente consultas ainda agendadas.
router.patch("/:id/cancelar", autenticar, permitirFuncoes("USUARIO", "SECRETARIA"), async (req, res) => {
    const parametroId = req.params.id;
    const id = typeof parametroId === "string" ? parametroId : undefined;

    if (!id) {
        return res.status(400).json({ mensagem: "Informe o código da consulta." });
    }
    try {
        const acesso = await consultaPermitida(id, res.locals.usuarioId, res.locals.usuarioTipo);
        if (acesso.erro !== undefined) {
            return res.status(acesso.erro).json({ mensagem: acesso.mensagem });
        }
        if (acesso.consulta.status !== "agendada") {
            return res.status(409).json({
                mensagem: "Apenas consultas agendadas podem ser canceladas."
            });
        }
        const db = obterBanco();
        const session = obterCliente().startSession();
        let alterou = false;
        try {
            await session.withTransaction(async () => {
                const resultado = await db.collection<Consulta>("consultas").updateOne(
                    { _id: id, status: "agendada" },
                    { $set: { status: "cancelada", atualizadoEm: new Date() } },
                    { session }
                );

                if (!resultado.modifiedCount) {
                    return;
                }
                await db.collection<Reserva>("reservasAgenda").deleteMany({ consultaId: id }, { session });
                alterou = true;
            });
        } finally {
            await session.endSession();
        }
        if (!alterou) {
            return res.status(409).json({
                mensagem: "Consulta já alterada por outra operação."
            });
        }
        return res.json({ mensagem: "Consulta cancelada com sucesso!" });
    } catch (erro) {
        return erroInterno(res, erro);
    }
});

export default router;
