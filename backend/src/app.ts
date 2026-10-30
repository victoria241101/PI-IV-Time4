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

const app = express();

// Configuração de acesso do Flutter Web
app.use(cors({
    origin: "http://localhost:7357",
    methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json());

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

// Rota inicial
app.get("/", (_req, res) => {
    res.json({
        mensagem: "Backend do PetCare funcionando!"
    });
});

export default app;