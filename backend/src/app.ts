import express from "express";

// rotas
import usuariosRoutes from "./routes/usuarios.routes.js";
import petsRoutes from "./routes/pets.routes.js";


const app = express();

app.use(express.json());

app.use("/usuarios", usuariosRoutes);
app.use("/pets", petsRoutes);

app.get("/", (req, res) => {
    res.json({
        mensagem: "Backend do PetCare funcionando!"
    });
});

export default app;