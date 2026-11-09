// inicializacao e rotas principais do aplicativo
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/autenticacao/cadastro.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/revisao_fluxos_temporaria.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';


import 'package:pet_care/screens/publico/sobre.dart';
import 'package:pet_care/screens/tutor/inicio_tutor.dart';
import 'package:pet_care/services/agendamentos_service.dart';
import 'package:pet_care/services/pets_service.dart';
import 'package:pet_care/services/veterinarios_service.dart';

void main() => runApp(const AplicativoVeterinaria());

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({super.key, required this.home});

  Future<void> _abrirInicio(BuildContext context) async {
    await SessaoUsuario.instancia.carregar();
    if (!context.mounted) return;
    final sessao = SessaoUsuario.instancia;
    final Widget destino = !sessao.estaLogado
        ? const InicioPublico()
        : sessao.ehTutor
            ? const _InicioTutorComDadosReais()
            : const InicioGeral();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destino),
    );
  }

  Widget _construirDestinoAutenticado(BuildContext context) {
    return SessaoUsuario.instancia.ehTutor
        ? const _InicioTutorComDadosReais()
        : const InicioGeral();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ComportamentoRolagemApp(),
      theme: TemaApp.light,
      home: Builder(
        builder: (context) => SplashScreen(
          onConcluida: () => _abrirInicio(context),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/inicio-publico': (context) => const InicioPublico(),
        '/inicio-geral': (context) => const InicioGeral(),
        '/inicio-autenticado': (context) => _construirDestinoAutenticado(context),
        '/campanhas': (context) => const Doacao(publica: true),
        '/sobre': (context) => const Sobre(),
        '/recepcao': (context) => const InicioRecepcao(),
        '/veterinario': (context) => const InicioVeterinario(),
        '/enfermeiro': (context) => const InicioEnfermeiro(),
      },
    );
  }
}

class _DadosInicioTutor {
  const _DadosInicioTutor({required this.pets, required this.consultas, required this.proxima});
  final List<ResumoPet> pets;
  final List<ResumoConsulta> consultas;
  final ResumoConsulta? proxima;
}

class _InicioTutorComDadosReais extends StatefulWidget {
  const _InicioTutorComDadosReais();

  @override
  State<_InicioTutorComDadosReais> createState() => _InicioTutorComDadosReaisState();
}

class _InicioTutorComDadosReaisState extends State<_InicioTutorComDadosReais> {
  _DadosInicioTutor? _dados;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  String _texto(dynamic valor, [String padrao = '']) =>
      valor == null ? padrao : valor.toString();

  String _tipoLegivel(String tipo) {
    const nomes = {
      'consulta_geral': 'Consulta geral',
      'vacinacao': 'Vacinação',
      'dermatologia': 'Dermatologia',
      'odontologia': 'Odontologia',
      'retorno': 'Retorno',
      'exames_laboratoriais': 'Exames laboratoriais',
    };
    return nomes[tipo] ?? tipo;
  }

  String _statusLegivel(String status) {
    const nomes = {
      'agendada': 'Confirmada',
      'chegada_confirmada': 'Chegada confirmada',
      'em_triagem': 'Em triagem',
      'aguardando_veterinario': 'Aguardando veterinário',
      'em_consulta': 'Em consulta',
      'realizada': 'Realizada',
      'concluida': 'Concluída',
      'cancelada': 'Cancelada',
    };
    return nomes[status.toLowerCase()] ?? status;
  }

  DateTime? _lerDataHora(String texto) {
    // O backend usa o horário local da clínica: AAAA-MM-DDTHH:mm:ss.
    // Não convertemos para UTC para não deslocar a hora exibida.
    if (texto.length < 16) return null;
    return DateTime.tryParse(texto.substring(0, 16));
  }

  Future<void> _atualizar() async {
    if (!mounted) return;
    setState(() { _carregando = true; _erro = null; });
    try {
      final token = SessaoUsuario.instancia.token;
      if (token == null || token.isEmpty) {
        throw StateError('Sessão expirada. Entre novamente.');
      }
      final resultados = await Future.wait<dynamic>([
        PetsService(baseUrl: 'http://localhost:3000').listarPets(),
        AgendamentosService(baseUrl: 'http://localhost:3000', token: token)
            .listarAgendamentos(),
        VeterinariosService(baseUrl: 'http://localhost:3000')
            .listarVeterinarios(),
      ]);
      final petsApi = resultados[0] as List;
      final agendamentosApi = resultados[1] as List;
      final vetsApi = resultados[2] as List;

      final pets = <ResumoPet>[];
      final nomesPets = <String, String>{};
      for (final item in petsApi) {
        if (item is! Map) continue;
        final id = _texto(item['_id'] ?? item['id']);
        final nome = _texto(item['nome'], 'Pet');
        if (id.isEmpty) continue;
        nomesPets[id] = nome;
        final pesoRaw = item['peso'];
        final peso = pesoRaw is num ? pesoRaw.toDouble() : double.tryParse(_texto(pesoRaw));
        pets.add(ResumoPet(
          id: id,
          name: nome,
          species: _texto(item['especie'], 'Não informada'),
          breed: item['raca']?.toString(),
          age: item['idade']?.toString(),
          weight: peso,
          photoUrl: (item['urlFoto'] ?? item['fotoUrl'])?.toString(),
        ));
      }

      final nomesVets = <String, String>{};
      for (final item in vetsApi) {
        if (item is! Map) continue;
        final id = _texto(item['_id'] ?? item['id']);
        if (id.isNotEmpty) nomesVets[id] = _texto(item['nome'], 'Veterinário');
      }

      final consultas = <ResumoConsulta>[];
      final futuras = <({DateTime quando, ResumoConsulta consulta})>[];
      final agora = DateTime.now();
      for (final item in agendamentosApi) {
        if (item is! Map) continue;
        final id = _texto(item['_id'] ?? item['id']);
        final dataHora = _lerDataHora(_texto(item['dataHora']));
        if (id.isEmpty || dataHora == null) continue;
        final statusApi = _texto(item['status'], 'agendada');
        final petId = _texto(item['petId']);
        final vetId = _texto(item['veterinarioId']);
        final consulta = ResumoConsulta(
          id: id,
          type: _tipoLegivel(_texto(item['tipo'], 'consulta_geral')),
          date: '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}',
          time: '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}',
          vetName: nomesVets[vetId] ?? 'Veterinário',
          petName: nomesPets[petId] ?? 'Pet',
          status: _statusLegivel(statusApi),
        );
        consultas.add(consulta);
        final encerrada = {'cancelada', 'realizada', 'concluida', 'concluída'}
            .contains(statusApi.toLowerCase());
        if (!encerrada && !dataHora.isBefore(agora)) {
          futuras.add((quando: dataHora, consulta: consulta));
        }
      }
      futuras.sort((a, b) => a.quando.compareTo(b.quando));
      if (!mounted) return;
      setState(() {
        _dados = _DadosInicioTutor(
          pets: pets,
          consultas: consultas,
          proxima: futuras.isEmpty ? null : futuras.first.consulta,
        );
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() { _carregando = false; _erro = erro.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando && _dados == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_erro != null && _dados == null) {
      return Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Não foi possível carregar a tela inicial.\n$_erro', textAlign: TextAlign.center),
            TextButton(onPressed: _atualizar, child: const Text('Tentar novamente')),
          ],
        )),
      );
    }
    final dados = _dados!;
    return InicioTutor(
      saudacao: 'Olá,',
      nomeTutor: SessaoUsuario.instancia.nomeUsuario ?? 'Tutor',
      pets: dados.pets,
      proximaConsulta: dados.proxima,
      consultas: dados.consultas,
      banners: const [],
      onAgendamentoConfirmado: (_) => _atualizar(),
      onReagendamentoConfirmado: (_, __) => _atualizar(),
      onConfirmarConsulta: (consultaId) async {
        // Não confirmar artificialmente: recarrega o registro real.
        await _atualizar();
        for (final consulta in _dados?.consultas ?? <ResumoConsulta>[]) {
          if (consulta.id == consultaId) return consulta;
        }
        throw StateError('Consulta não encontrada no servidor.');
      },
      carregarDetalhesPet: (petId) async {
        throw UnimplementedError('Detalhes do pet ainda não estão conectados ao backend.');
      },
      onNotificacoes: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificações ainda não estão disponíveis.')),
        );
      },
    );
  }
}
