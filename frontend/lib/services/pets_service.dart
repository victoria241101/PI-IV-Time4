// Alinne Monteiro de Melo | RA: 24801649

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/services/api_http.dart';

class PetsService {
  final String baseUrl;

  PetsService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<List<Map<String, dynamic>>> listarPets() async {
    // Usa a sessão normal ou o token temporário de teste.
    final token = SessaoUsuario.instancia.token ??
        const String.fromEnvironment('TOKEN_TESTE');

    if (token.isEmpty) {
      throw StateError(
        'Você precisa estar logado para consultar seus pets.',
      );
    }

    final resposta = await http.get(
      Uri.parse('$baseUrl/pets'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar os pets. '
        'Código: ${resposta.statusCode}',
      );
    }

    final dados = jsonDecode(
      utf8.decode(resposta.bodyBytes),
    ) as Map<String, dynamic>;

    final pets = dados['pets'] as List<dynamic>;

    return pets
        .map((pet) => Map<String, dynamic>.from(pet as Map))
        .toList();
  }

  Future<DetalhesPet> carregarDetalhesPet(String petId) async {
    if (petId.trim().isEmpty) throw ArgumentError('Pet não identificado.');
    final token = SessaoUsuario.instancia.token ??
        const String.fromEnvironment('TOKEN_TESTE');
    if (token.isEmpty) throw StateError('Entre novamente para consultar o pet.');

    final pets = await listarPets().timeout(const Duration(seconds: 20));
    final pet = pets.where((p) => (p['_id'] ?? p['id']) == petId).firstOrNull;
    if (pet == null) throw StateError('Pet não encontrado para este tutor.');
    final resposta = await http.get(
      Uri.parse('$baseUrl/pets/${Uri.encodeComponent(petId)}/historico-clinico'),
      headers: cabecalhosJson(token),
    ).timeout(const Duration(seconds: 20));
    if ((SessaoUsuario.instancia.token ??
        const String.fromEnvironment('TOKEN_TESTE')) != token) {
      throw StateError('A sessão mudou. Abra o pet novamente.');
    }
    final dados = processarRespostaJson(resposta);
    if (dados is! Map || dados['pet'] is! Map ||
        dados['pet']['id'] != petId) {
      throw const FormatException('Histórico do pet inválido.');
    }
    String? texto(dynamic valor) =>
        valor is String && valor.trim().isNotEmpty ? valor.trim() : null;
    DateTime? data(dynamic valor) => DateTime.tryParse(texto(valor) ?? '');
    String dataExibida(dynamic valor) {
      final d = data(valor);
      if (d == null) return 'Não informado';
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    List<Map<String, dynamic>> lista(String chave) {
      final itens = dados[chave];
      if (itens is! List || itens.any((e) => e is! Map)) {
        throw FormatException('Histórico inválido: $chave.');
      }
      return itens.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final nascimento = data(pet['dataNascimento']);
    String? idade;
    if (nascimento != null) {
      final hoje = DateTime.now();
      final inicio = DateTime(nascimento.year, nascimento.month, nascimento.day);
      final fim = DateTime(hoje.year, hoje.month, hoje.day);
      if (!inicio.isAfter(fim)) {
        var meses = (fim.year - inicio.year) * 12 + fim.month - inicio.month;
        if (fim.day < inicio.day) meses--;
        final anos = meses ~/ 12;
        idade = anos > 0
            ? '$anos ${anos == 1 ? 'ano' : 'anos'}'
            : meses > 0
                ? '$meses ${meses == 1 ? 'mês' : 'meses'}'
                : '${fim.difference(inicio).inDays} dias';
      }
    }
    final historico = lista('historico');
    final pesos = <({double peso, DateTime? data})>[];
    final registros = <({RegistroHistoricoPet registro, DateTime? data})>[];
    void adicionar(Map item, CategoriaHistoricoPet categoria, dynamic titulo,
        dynamic quando, List<dynamic> descricao) {
      final id = texto(item['_id']);
      if (id == null) throw const FormatException('Registro sem identificador.');
      registros.add((
        data: data(quando),
        registro: RegistroHistoricoPet(
          id: '${categoria.name}:$id',
          categoria: categoria,
          titulo: texto(titulo) ?? 'Não informado',
          data: dataExibida(quando),
          descricao: descricao.map(texto).whereType<String>().join('\n'),
          status: texto(item['status']),
        ),
      ));
    }
    for (final entrada in historico) {
      final consulta = entrada['consulta'];
      if (consulta is! Map) throw const FormatException('Consulta inválida.');
      final triagem = entrada['triagem'];
      if (triagem is Map) {
        final valor = triagem['peso'];
        final peso = valor is num ? valor.toDouble() : double.tryParse('$valor');
        if (peso != null && peso.isFinite && peso > 0) {
          pesos.add((peso: peso, data: data(triagem['dataHora']) ?? data(consulta['dataHora'])));
        }
      }
      final atendimento = entrada['atendimento'];
      adicionar(consulta, CategoriaHistoricoPet.consulta,
          texto(consulta['motivo']) ?? texto(consulta['tipo']) ?? 'Consulta',
          consulta['dataHora'], [
            if (atendimento is Map) atendimento['diagnostico'],
            if (atendimento is Map) atendimento['tratamento'],
          ]);
    }
    for (final p in lista('prescricoes')) {
      adicionar(p, CategoriaHistoricoPet.medicamento, p['medicamento'],
          p['dataPrescricao'], [
            if (texto(p['dose']) != null) 'Dose: ${p['dose']}',
            if (texto(p['frequencia']) != null) 'Frequência: ${p['frequencia']}',
            if (texto(p['duracao']) != null) 'Duração: ${p['duracao']}',
            p['orientacoes'],
          ]);
    }
    for (final e in lista('exames')) {
      adicionar(e, CategoriaHistoricoPet.exame, e['nome'],
          e['dataSolicitacao'], [e['tipo'], e['justificativa'], e['resultado']]);
    }
    int recentes(DateTime? a, DateTime? b) => a == null
        ? (b == null ? 0 : 1)
        : b == null ? -1 : b.compareTo(a);
    pesos.sort((a, b) => recentes(a.data, b.data));
    registros.sort((a, b) => recentes(a.data, b.data));
    final pesoCadastro = double.tryParse("${pet['peso']}");
    return DetalhesPet(
      pet: ResumoPet(
        id: petId,
        name: texto(pet['nome']) ?? texto(dados['pet']['nome']) ?? 'Não informado',
        species: texto(pet['especie']) ?? texto(dados['pet']['especie']) ?? 'Não informado',
        breed: texto(pet['raca']) ?? texto(dados['pet']['raca']) ?? 'Não informado',
        age: idade ?? texto(pet['idade']),
        weight: pesos.firstOrNull?.peso ??
            (pesoCadastro != null && pesoCadastro.isFinite && pesoCadastro > 0
                ? pesoCadastro : null),
        photoUrl: texto(pet['urlFoto']) ?? texto(pet['fotoUrl']),
      ),
      sexo: texto(pet['sexo']) ?? 'Não informado',
      dataNascimento: dataExibida(pet['dataNascimento']),
      microchip: texto(pet['microchip']) ?? 'Não informado',
      registros: registros.map((r) => r.registro).toList(),
      lembretes: const [],
    );
  }
}
