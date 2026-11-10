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
  final List<RegistroRecepcaoLocal> registros = [];

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

  List<RegistroRecepcaoLocal> get campanhasLocais =>
      registros.where((r) => r.tipo == TipoCadastroRecepcao.campanha).toList();
}
