/// Exceção padronizada para erros de comunicação com a API do PetCare.
class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  const ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => 'ApiException($statusCode): $mensagem';
}

