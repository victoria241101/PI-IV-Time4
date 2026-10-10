import app from "./app.js";
import { conectarBanco } from "./database.js";

const PORTA = 3000;

async function iniciarServidor() {
    try {
        await conectarBanco();

        app.listen(PORTA, () => {
            console.log(
                `Backend do PetCare rodando na porta ${PORTA}`
            );
        });
    } catch (erro) {
        console.error("Erro ao iniciar o backend:", erro);
        process.exit(1);
    }
}

iniciarServidor();