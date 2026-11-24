// Alinne Monteiro de Melo | RA: 24801649

// Importa o módulo nativo do Node.js responsável
// pela comunicação de rede utilizando sockets TCP.
import net from "node:net";

// Define a estrutura esperada da resposta do Java.
interface RespostaJava {

    // Estado da operação realizada.
    status: string;

    // Mensagem explicando o resultado.
    mensagem: string;

    // Código opcional associado à resposta.
    codigo?: string;

    // Dados opcionais retornados pelo Java.
    dados?: {
        hash?: string;
        valida?: boolean;
        conflito?: boolean;
        sugestoes?: string[];
    };
}

// Função exportada para que outros arquivos
// do backend possam solicitar operações ao Java.
export function enviarComandoJava(
    comando: string,
    dados: object
): Promise<RespostaJava> {

    // Cria uma Promise porque a comunicação
    // com o Java é uma operação assíncrona.
    return new Promise((resolve, reject) => {

        // Cria o socket cliente e inicia a conexão
        // com o servidor Java na porta 5000.
        const cliente = net.createConnection({
            host: "127.0.0.1",
            port: 5000
        });

        // Armazena as partes da resposta recebida.
        let resposta = "";

        // Indica se a comunicação já foi finalizada.
        let finalizado = false;

        // Centraliza a lógica de encerramento
        // da conexão, tanto em sucesso quanto em erro.
        function concluir(
            erro?: Error,
            resultado?: RespostaJava
        ) {

            // Impede que a finalização seja
            // executada mais de uma vez.
            if (finalizado) return;

            // Marca a operação como finalizada.
            finalizado = true;

            // Encerra o socket TCP.
            cliente.destroy();

            // Se ocorreu um erro, rejeita a Promise.
            if (erro) {
                reject(erro);

            // Caso exista um resultado, resolve
            // a Promise com a resposta recebida.
            } else if (resultado) {
                resolve(resultado);
            }
        }

        // Define um limite de inatividade
        // de 5000 milissegundos (5 segundos).
        cliente.setTimeout(5000);

        // Evento executado quando a conexão
        // com o servidor Java é estabelecida.
        cliente.on("connect", () => {

            // Converte o comando e os dados
            // em uma string no formato JSON.
            const requisicao = JSON.stringify({
                comando,
                dados
            });

            // Envia a requisição pelo socket.
            // A quebra de linha delimita a mensagem.
            cliente.write(requisicao + "\n");
        });

        // Evento executado sempre que uma parte
        // da resposta do Java é recebida.
        cliente.on("data", (parte) => {

            // Converte os bytes recebidos em texto
            // e acumula na variável resposta.
            resposta += parte.toString("utf8");

            // Verifica se a resposta ultrapassou
            // o limite de tamanho permitido.
            if (resposta.length > 65536) {

                concluir(
                    new Error("Resposta Java muito grande.")
                );

                // Interrompe a execução deste callback.
                return;
            }

            // Procura a quebra de linha que indica
            // o final da mensagem enviada pelo Java.
            const fimLinha = resposta.indexOf("\n");

            // Se encontrou a quebra de linha,
            // existe uma mensagem para interpretar.
            if (fimLinha !== -1) {

                try {

                    // Extrai o conteúdo antes da quebra
                    // de linha e converte JSON em objeto.
                    const resultado = JSON.parse(
                        resposta.slice(0, fimLinha)
                    ) as RespostaJava;

                    // Finaliza a comunicação com sucesso.
                    concluir(undefined, resultado);

                } catch {

                    // Trata possíveis erros durante
                    // a interpretação da resposta.
                    concluir(
                        new Error(
                            "Resposta JSON inválida do Java."
                        )
                    );
                }
            }
        });

        // Evento executado quando o socket
        // ultrapassa o limite de inatividade.
        cliente.on("timeout", () => {

            concluir(
                new Error(
                    "Tempo de resposta do Java esgotado."
                )
            );
        });

        // Evento executado quando ocorre
        // algum erro relacionado ao socket.
        cliente.on("error", (erro) => {

            // Encaminha o erro original.
            concluir(erro);
        });

        // Evento executado quando o servidor Java
        // encerra seu fluxo de envio de dados.
        cliente.on("end", () => {

            // Verifica se a operação ainda
            // não havia sido finalizada.
            if (!finalizado) {

                concluir(
                    new Error(
                        "Java encerrou sem enviar resposta."
                    )
                );
            }
        });
    });
}