import app from "./app.js";

const PORTA = 3000;

app.listen(PORTA, () => {
    console.log(`Backend do PetCare rodando na porta ${PORTA}`);
});