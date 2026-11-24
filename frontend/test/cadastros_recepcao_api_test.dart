// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: cadastros, busca CPF, campanha e nomes/IDs da agenda.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
import 'package:pet_care/services/clinica/consulta_clinica_api.dart';
import 'package:pet_care/services/campanhas_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoUsuario.instancia.entrar(
      nome: 'Secretária',
      email: 'sec@example.test',
      token: 'teste',
      tipoUsuario: 'SECRETARIA',
    );
  });
  tearDown(() async => SessaoUsuario.instancia.sair());
  test(
    'Funcionário envia perfil e token para rota exclusiva da secretária',
    () async {
      final api = CadastrosRecepcaoService(baseUrl: 'https://api.example.test');
      await http.runWithClient(
        () async {
          await api.cadastrarFuncionario({
            'nome': 'Teste',
            'email': 'teste@example.test',
            'cargo': 'Veterinário',
            'crmv': 'CRMV-SP-123',
          }, '123456789012345678901234');
        },
        () => MockClient((r) async {
          expect(r.url.path, '/recepcao/funcionarios');
          expect(r.headers['Authorization'], 'Bearer teste');
          final body = jsonDecode(r.body) as Map;
          expect(body['tipo'], 'VETERINARIO');
          expect(body.containsKey('senha'), false);
          return http.Response('{"funcionarioId":"V1"}', 201);
        }),
      );
    },
  );

  test(
    'Cadastro usa rota da recepção e não envia senha nem usuário da secretária',
    () async {
      final servico = CadastrosRecepcaoService(
        baseUrl: 'https://api.example.test',
      );
      final id = CadastrosRecepcaoService.novaSolicitacao();
      expect(id, matches(RegExp(r'^[a-f0-9]{24}$')));
      await http.runWithClient(
        () async {
          final r = await servico.cadastrar({
            'nome': 'Ana',
            'email': 'ana@example.test',
            'cpf': '52998224725',
            'telefone': '11999999999',
            'pet': 'Mel',
            'especie': 'Cachorro',
            'raca': 'SRD',
            'sexo': 'Fêmea',
            'possuiMicrochip': 'true',
            'microchip': '001234567890123',
            'dataNascimento': '2022-05-10T00:00:00.000',
          }, id);
          expect(r['petId'], 'P1');
        },
        () => MockClient((r) async {
          expect(r.url.path, '/recepcao/tutores-pets');
          expect(r.headers['Authorization'], 'Bearer teste');
          final body = jsonDecode(r.body) as Map;
          expect(body['solicitacaoId'], id);
          expect(body.containsKey('senha'), isFalse);
          expect(body.containsKey('usuarioId'), isFalse);
          expect(body['pet'], {
            'nome': 'Mel',
            'especie': 'cachorro',
            'raca': 'SRD',
            'sexo': 'femea',
            'possuiMicrochip': true,
            'microchip': '001234567890123',
            'dataNascimento': '2022-05-10',
          });
          return http.Response(
            '{"tutorId":"T1","petId":"P1","contaCriada":true}',
            201,
          );
        }),
      );
    },
  );
  test('Busca diferencia CPF ausente de serviço indisponível', () async {
    final servico = CadastrosRecepcaoService(
      baseUrl: 'https://api.example.test',
    );
    var falhar = false;
    await http.runWithClient(
      () async {
        expect(await servico.buscarTutor('52998224725'), isNull);
        falhar = true;
        await expectLater(servico.buscarTutor('52998224725'), throwsException);
      },
      () => MockClient(
        (r) async => http.Response('{"mensagem":"Falha"}', falhar ? 503 : 404),
      ),
    );
  });

  test('Cadastro de campanha envia os campos para a API existente', () async {
    final service = CampanhasService.criar(baseUrl: 'https://api.example.test');
    final id = await http.runWithClient(
      () => service.criarCampanha(
        titulo: 'Tratamento da Mel',
        descricao: 'Apoio para o tratamento veterinário.',
        metaValor: 1250.50,
        imagemCapa: null,
        dataInicio: DateTime(2026, 12, 1),
        dataFim: DateTime(2026, 12, 31, 23, 59, 59),
      ),
      () => MockClient((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, '/campanhas');
        expect(r.headers['Authorization'], isNotEmpty);
        expect(jsonDecode(r.body), {
          'titulo': 'Tratamento da Mel',
          'descricao': 'Apoio para o tratamento veterinário.',
          'metaValor': 1250.50,
          'imagemCapa': null,
          'dataInicio': '2026-12-01T00:00:00.000',
          'dataFim': '2026-12-31T23:59:59.000',
        });
        return http.Response('{"campanhaId":"123456789012345678901234"}', 201);
      }),
    );
    expect(id, '123456789012345678901234');
  });

  test('Agenda mantém os nomes recebidos sem substituir os IDs', () {
    final c = ConsultaClinicaApi.fromJson({
      'id': 'C1',
      'petId': 'P1',
      'tutorId': 'T1',
      'veterinarioId': 'V1',
      'dataHora': '2026-11-11T10:00:00',
      'duracaoMinutos': 30,
      'tipo': 'consulta_geral',
      'status': 'agendada',
      'petNome': 'Mel',
      'tutorNome': 'Ana',
      'veterinarioNome': 'Dra. Bia',
      'especie': 'cachorro',
    });
    expect(c.petId, 'P1');
    expect(c.petNome, 'Mel');
    expect(c.tutorNome, 'Ana');
    expect(c.veterinarioNome, 'Dra. Bia');
  });
}
