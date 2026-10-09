import express from "express";

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
    res.json({
        mensagem: "Backend do PetCare funcionando!"
    });
});

export default app;