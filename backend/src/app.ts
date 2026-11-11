import { criarRotasCadastrosRecepcao } from './recepcao/cadastros.routes.js';
import { obterBanco, obterCliente } from './database.js';
import { autenticar } from './middlewares/auth.middleware.js';
import { enviarComandoJava } from './javaClient.js';
import express from "express";
import cors from "cors";

// Rotas
import usuariosRoutes from "./routes/usuarios.routes.js";
import petsRoutes from "./routes/pets.routes.js";
import consultasRoutes from "./routes/consultas.routes.js";
import procedimentosRoutes from "./routes/procedimentos.routes.js";
import internacoesRoutes from "./routes/internacoes.routes.js";
import prescricoesRoutes from "./routes/prescricoes.routes.js";
import examesRoutes from "./routes/exames.routes.js";
import administracoesRoutes from "./routes/administracoes.routes.js";
import tarefasClinicasRoutes from "./routes/tarefasClinicas.routes.js";
import planosTratamentoRoutes from "./routes/planosTratamento.routes.js";
import orientacoesAltaRoutes from "./routes/orientacoesAlta.routes.js";
import agendamentosRoutes from "./routes/agendamentos.routes.js";
import prontuarioPdfRoutes from "./routes/prontuarioPdf.routes.js";
import campanhasRoutes from "./routes/campanhas.routes.js";
import doacoesRoutes from "./routes/doacoes.routes.js";
import chatRoutes from "./routes/chat.routes.js";
import notificacoesRoutes from "./routes/notificacoes.routes.js";
import veterinariosRoutes from "./routes/veterinarios.routes.js";


const app = express();

// Configuração de acesso do Flutter Web
app.use(cors({
    origin: [
        "http://localhost:7357",
        "http://localhost:9058",
    ],
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());

// Cadastro administrativo separado das rotas públicas de tutor.
app.use('/recepcao', criarRotasCadastrosRecepcao({
    obterBanco, obterCliente, autenticar,
    gerarHash: async senha => {
        const resposta = await enviarComandoJava('GERAR_HASH_SENHA', { senha });
        if (resposta.status !== 'OK' || !resposta.dados?.hash) {
            throw new Error('Serviço de senha indisponível.');
        }
        return resposta.dados.hash;
    }
}));

// Rotas da API
app.use("/usuarios", usuariosRoutes);
app.use("/pets", petsRoutes);
app.use("/consultas", consultasRoutes);
app.use("/consultas", prontuarioPdfRoutes);
app.use("/procedimentos", procedimentosRoutes);
app.use("/internacoes", internacoesRoutes);
app.use("/prescricoes", prescricoesRoutes);
app.use("/exames", examesRoutes);
app.use("/administracoes", administracoesRoutes);
app.use("/tarefas-clinicas", tarefasClinicasRoutes);
app.use("/planos-tratamento", planosTratamentoRoutes);
app.use("/orientacoes-alta", orientacoesAltaRoutes);
app.use("/agendamentos", agendamentosRoutes);
app.use("/campanhas", campanhasRoutes);
app.use("/doacoes", doacoesRoutes);
app.use("/chat", chatRoutes);
app.use("/notificacoes", notificacoesRoutes);
app.use("/veterinarios", veterinariosRoutes);

// Rota inicial
app.get("/", (_req, res) => {
    res.json({
        mensagem: "Backend do PetCare funcionando!"
    });
});

export default app;