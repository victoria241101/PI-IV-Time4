import express from "express";

// rotas
import usuariosRoutes from "./routes/usuarios.routes.js";
import petsRoutes from "./routes/pets.routes.js";
import consultasRoutes from "./routes/consultas.routes.js";
import procedimentosRoutes from "./routes/procedimentos.routes.js";
import internacoesRoutes from "./routes/internacoes.routes.js";
import prescricoesRoutes from "./routes/prescricoes.routes.js";
import examesRoutes from "./routes/exames.routes.js";
import administracoesRoutes from "./routes/administracoes.routes.js";
import tarefasClinicasRoutes from "./routes/tarefasClinicas.routes.js";

const app = express();

app.use(express.json());

app.use("/usuarios", usuariosRoutes);
app.use("/pets", petsRoutes);
app.use("/consultas", consultasRoutes);
app.use("/procedimentos", procedimentosRoutes);
app.use("/internacoes", internacoesRoutes);
app.use("/prescricoes", prescricoesRoutes);
app.use("/exames", examesRoutes);
app.use("/administracoes", administracoesRoutes);
app.use("/tarefas-clinicas", tarefasClinicasRoutes);

app.get("/", (req, res) => {
    res.json({
        mensagem: "Backend do PetCare funcionando!"
    });
});

export default app;