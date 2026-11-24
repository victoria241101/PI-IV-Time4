// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Tipos, resultados e estruturas locais de cadastro, sem persistência de banco/API.
// Armazenamento em memória para revisão do front. Não cria contas nem publica dados.
enum TipoCadastroRecepcao { funcionario, tutorPet, campanha, banner }

class RegistroRecepcaoLocal {
  RegistroRecepcaoLocal({
    required this.tipo,
    required this.nome,
    required this.dados,
    this.tutorDemonstracao = false,
  });
  final bool tutorDemonstracao;
  final TipoCadastroRecepcao tipo;
  final String nome;
  final Map<String, String> dados;
}

class CadastrosRecepcaoLocal {
  CadastrosRecepcaoLocal._();
  static final instancia = CadastrosRecepcaoLocal._();
  // Os dados ficam apenas nesta execução da aplicação.
  final List<RegistroRecepcaoLocal> registros = [];

  // Normaliza a pontuação para comparar CPFs digitados de formas diferentes.
  List<RegistroRecepcaoLocal> petsPorCpf(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'\D'), '');
    return registros
        .where(
          (r) =>
              r.tipo == TipoCadastroRecepcao.tutorPet &&
              r.dados['cpf']?.replaceAll(RegExp(r'\D'), '') == numeros,
        )
        .toList();
  }

  // Pesquisa do registro mais recente ao mais antigo para evitar duplicidades.
  RegistroRecepcaoLocal? tutorPorCpf(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'\D'), '');
    for (final registro in registros.reversed) {
      if (registro.tipo == TipoCadastroRecepcao.tutorPet &&
          registro.dados['cpf']?.replaceAll(RegExp(r'\D'), '') == numeros) {
        return registro;
      }
    }
    return null;
  }

  // Separa campanhas dos demais tipos de cadastro armazenados na lista.
  List<RegistroRecepcaoLocal> get campanhasLocais =>
      registros.where((r) => r.tipo == TipoCadastroRecepcao.campanha).toList();
}
