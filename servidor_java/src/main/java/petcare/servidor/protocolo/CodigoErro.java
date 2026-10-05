package petcare.servidor.protocolo;

/**
 * Códigos de erro padronizados do protocolo TCP do Servidor PetCare.
 * 
 * Utilizados no campo "codigo" das mensagens JSON de resposta de erro
 * enviadas pelo ClienteHandler aos clientes conectados.
 */
public enum CodigoErro {

    /**
     * Linha vazia, nula, malformatada (JsonSyntaxException), raiz que não seja
     * um objeto JSON, tamanho excedendo 64 KB ou timeout de leitura do socket.
     */
    JSON_INVALIDO,

    /**
     * Requisição em JSON válido, porém sem o campo 'comando', com valor nulo,
     * tipo não-string ou string vazia após trim.
     */
    COMANDO_AUSENTE,

    /**
     * Comando enviado não está registrado no roteador do servidor.
     */
    COMANDO_DESCONHECIDO,

    /**
     * Comando previsto na especificação do PetCare, mas que ainda não possui
     * implementação do respectivo serviço de cálculo/processamento.
     */
    COMANDO_NAO_IMPLEMENTADO,

    /**
     * Campo 'dados' ausente, nulo ou que não seja um objeto JSON.
     */
    DADOS_INVALIDOS,

    /**
     * Exceção interna inesperada capturada no servidor durante o atendimento
     * (não expõe stack trace na resposta enviada ao cliente).
     */
    ERRO_INTERNO
}
