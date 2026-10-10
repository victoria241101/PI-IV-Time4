
import net from "node:net";

interface RespostaJava {
    status: string;
    mensagem: string;
    codigo?: string;
    dados?: {
        hash?: string;
    };
}

export function enviarComandoJava(
    comando: string,
    dados: object
): Promise<RespostaJava> {

    return new Promise((resolve, reject) => {

        const cliente = net.createConnection({
            host: "127.0.0.1",
            port: 5000
        });

        let resposta = "";
        let finalizado = false;

        function concluir(erro?: Error, resultado?: RespostaJava) {
            if (finalizado) return;
            finalizado = true;
            cliente.destroy();

            if (erro) {
                reject(erro);
            } else if (resultado) {
                resolve(resultado);
            }
        }

        cliente.setTimeout(5000);

        cliente.on("connect", () => {
            const requisicao = JSON.stringify({
                comando,
                dados
            });

            cliente.write(requisicao + "\n");
        });

        cliente.on("data", (parte) => {
            resposta += parte.toString("utf8");

            if (resposta.length > 65536) {
                concluir(new Error("Resposta Java muito grande."));
                return;
            }

            const fimLinha = resposta.indexOf("\n");

            if (fimLinha !== -1) {
                try {
                    const resultado = JSON.parse(
                        resposta.slice(0, fimLinha)
                    ) as RespostaJava;

                    concluir(undefined, resultado);
                } catch {
                    concluir(new Error("Resposta JSON inválida do Java."));
                }
            }
        });

        cliente.on("timeout", () => {
            concluir(new Error("Tempo de resposta do Java esgotado."));
        });

        cliente.on("error", (erro) => {
            concluir(erro);
        });

        cliente.on("end", () => {
            if (!finalizado) {
                concluir(new Error("Java encerrou sem enviar resposta."));
            }
        });
    });
}
