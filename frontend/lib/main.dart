import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/autenticacao/cadastro.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/autenticacao/service/perfil_service.dart';
import 'package:pet_care/screens/doacao/doacao.dart';
import 'package:pet_care/screens/gerais/inicio_geral.dart';
import 'package:pet_care/screens/gerais/splash_screen.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/publico/sobre.dart';
import 'package:pet_care/screens/tutor/inicio_tutor.dart';
import 'package:pet_care/services/agendamentos_service.dart';
import 'package:pet_care/services/pets_service.dart';
import 'package:pet_care/services/veterinarios_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AplicativoVeterinaria());
}

class AplicativoVeterinaria extends StatefulWidget {
  const AplicativoVeterinaria({super.key});

  @override
  State<AplicativoVeterinaria> createState() =>
      _AplicativoVeterinariaState();
}

class _AplicativoVeterinariaState extends State<AplicativoVeterinaria> {
  final GlobalKey<NavigatorState> _navigatorKey =
  GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  bool _processandoLink = false;
  bool _inicioPronto = false;
  Uri? _linkPendente;

  @override
  void initState() {
    super.initState();
    _inicializarLinks();
  }

  Future<void> _inicializarLinks() async {
    try {
      // Flutter Web: recebe o link pela URL do navegador.
      if (kIsWeb) {
        final linkInicial = Uri.base;

        if (linkInicial.queryParameters.containsKey('token')) {
          _receberLink(linkInicial);
        }

        return;
      }

      // Android: mantém o recebimento de deep links nativos.
      final linkInicial = await _appLinks.getInitialLink();

      if (linkInicial != null) {
        _receberLink(linkInicial);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        _receberLink,
        onError: (erro) {
          debugPrint('Erro ao receber deep link: $erro');
        },
      );
    } catch (erro) {
      debugPrint('Erro ao inicializar deep links: $erro');
    }
  }

  void _receberLink(Uri uri) {
    final linkNativo = uri.scheme == 'petcare';
    final linkWeb = kIsWeb &&
        uri.queryParameters.containsKey('tipo');

    if (!linkNativo && !linkWeb) return;

    if (!_inicioPronto || _navigatorKey.currentState == null) {
      _linkPendente = uri;
      return;
    }

    _processarLink(uri);
  }

  Future<void> _processarLink(Uri uri) async {
    if (_processandoLink) {
      _linkPendente = uri;
      return;
    }

    final tipo = uri.scheme == 'petcare'
        ? uri.host
        : uri.queryParameters['tipo'];
    final token = uri.queryParameters['token'];

    if (token == null ||
        token.isEmpty ||
        !{
          'confirmar-alteracao',
          'confirmar-alteracao-senha',
        }.contains(tipo)) {
      return;
    }

    final navigator = _navigatorKey.currentState;

    if (navigator == null || !navigator.mounted) {
      _linkPendente = uri;
      return;
    }

    _processandoLink = true;

    bool sucesso = false;
    bool dialogCarregamentoAberto = false;
    String mensagem = '';

    try {
      showDialog<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text('Confirmando sua solicitação...'),
              ),
            ],
          ),
        ),
      );

      dialogCarregamentoAberto = true;

      final sessao = SessaoUsuario.instancia;

      final servico = PerfilService(
        baseUrl: kIsWeb
            ? 'http://localhost:3000'
            : 'http://10.0.2.2:3000',
        token: sessao.token ?? '',
      );

      if (tipo == 'confirmar-alteracao') {
        final resposta =
        await servico.confirmarAlteracaoPerfil(token: token);

        mensagem = resposta['mensagem']?.toString() ??
            'Perfil confirmado com sucesso!';

        if (sessao.estaLogado) {
          await sessao.sincronizarPerfilConfirmado();
        }
      } else {
        final resposta =
        await servico.confirmarAlteracaoSenha(token: token);

        mensagem = resposta['mensagem']?.toString() ??
            'Senha alterada com sucesso!';

        if (sessao.estaLogado) {
          await sessao.sair();
        }
      }

      sucesso = true;
    } catch (erro) {
      mensagem = erro.toString().replaceFirst('Exception: ', '');
    } finally {
      if (dialogCarregamentoAberto && navigator.mounted) {
        Navigator.of(
          navigator.context,
          rootNavigator: true,
        ).pop();
      }

      if (navigator.mounted) {
        await showDialog<void>(
          context: navigator.context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              sucesso ? 'Tudo certo!' : 'Não foi possível confirmar',
            ),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (sucesso && tipo == 'confirmar-alteracao-senha') {
          navigator.pushNamedAndRemoveUntil(
            '/login',
                (route) => false,
          );
        }
      }

      _processandoLink = false;

      final proximoLink = _linkPendente;
      _linkPendente = null;

      if (proximoLink != null && _inicioPronto) {
        _processarLink(proximoLink);
      }
    }
  }

  Future<void> _abrirInicio(BuildContext context) async {
    debugPrint('TESTE 1: entrou em _abrirInicio');

    try {
      debugPrint('TESTE 2: iniciando carregamento da sessão');

      await SessaoUsuario.instancia.carregar();

      debugPrint('TESTE 3: sessão carregada');

      if (!context.mounted) return;

      final sessao = SessaoUsuario.instancia;

      final Widget destino = !sessao.estaLogado
          ? const InicioPublico()
          : sessao.ehTutor
          ? const _InicioTutorComDadosReais()
          : const InicioGeral();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => destino,
        ),
      );

      _inicioPronto = true;

      final linkPendente = _linkPendente;
      _linkPendente = null;

      if (linkPendente != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _processarLink(linkPendente);
        });
      }

      debugPrint('TESTE 4: navegação concluída');
    } catch (erro, stack) {
      debugPrint('ERRO AO CARREGAR SESSÃO: $erro');
      debugPrint('$stack');
    }
  }

  Widget _construirDestinoAutenticado(BuildContext context) {
    return SessaoUsuario.instancia.ehTutor
        ? const _InicioTutorComDadosReais()
        : const InicioGeral();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
        '/inicio-autenticado': (context) =>
            _construirDestinoAutenticado(context),
        '/campanhas': (context) => const Doacao(publica: true),
        '/sobre': (context) => const Sobre(),
      },
    );
  }
}

class _DadosInicioTutor {
  const _DadosInicioTutor({
    required this.pets,
    required this.consultas,
    required this.proxima,
  });

  final List<ResumoPet> pets;
  final List<ResumoConsulta> consultas;
  final ResumoConsulta? proxima;
}

class _InicioTutorComDadosReais extends StatefulWidget {
  const _InicioTutorComDadosReais();

  @override
  State<_InicioTutorComDadosReais> createState() =>
      _InicioTutorComDadosReaisState();
}

class _InicioTutorComDadosReaisState
    extends State<_InicioTutorComDadosReais> {
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

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = SessaoUsuario.instancia.token;

      if (token == null || token.isEmpty) {
        throw StateError('Sessão expirada. Entre novamente.');
      }

      final resultados = await Future.wait<dynamic>([
        PetsService(baseUrl: 'http://localhost:3000').listarPets(),
        AgendamentosService(
          baseUrl: 'http://localhost:3000',
          token: token,
        ).listarAgendamentos(),
        VeterinariosService(
          baseUrl: 'http://localhost:3000',
        ).listarVeterinarios(),
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
        final peso = pesoRaw is num
            ? pesoRaw.toDouble()
            : double.tryParse(_texto(pesoRaw));

        pets.add(
          ResumoPet(
            id: id,
            name: nome,
            species: _texto(item['especie'], 'Não informada'),
            breed: item['raca']?.toString(),
            age: item['idade']?.toString(),
            weight: peso,
            photoUrl: (item['urlFoto'] ?? item['fotoUrl'])?.toString(),
          ),
        );
      }

      final nomesVets = <String, String>{};

      for (final item in vetsApi) {
        if (item is! Map) continue;

        final id = _texto(item['_id'] ?? item['id']);

        if (id.isNotEmpty) {
          nomesVets[id] = _texto(item['nome'], 'Veterinário');
        }
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
          type: _tipoLegivel(
            _texto(item['tipo'], 'consulta_geral'),
          ),
          date: '${dataHora.day.toString().padLeft(2, '0')}/'
              '${dataHora.month.toString().padLeft(2, '0')}/'
              '${dataHora.year}',
          time: '${dataHora.hour.toString().padLeft(2, '0')}:'
              '${dataHora.minute.toString().padLeft(2, '0')}',
          vetName: nomesVets[vetId] ?? 'Veterinário',
          petName: nomesPets[petId] ?? 'Pet',
          status: _statusLegivel(statusApi),
        );

        consultas.add(consulta);

        final encerrada = {
          'cancelada',
          'realizada',
          'concluida',
          'concluída',
        }.contains(statusApi.toLowerCase());

        if (!encerrada && !dataHora.isBefore(agora)) {
          futuras.add((
          quando: dataHora,
          consulta: consulta,
          ));
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

      setState(() {
        _carregando = false;
        _erro = erro.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando && _dados == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null && _dados == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não foi possível carregar a tela inicial.\n$_erro',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _atualizar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
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

        for (final consulta
        in _dados?.consultas ?? <ResumoConsulta>[]) {
          if (consulta.id == consultaId) return consulta;
        }

        throw StateError('Consulta não encontrada no servidor.');
      },
      carregarDetalhesPet: (petId) async {
        throw UnimplementedError(
          'Detalhes do pet ainda não estão conectados ao backend.',
        );
      },
      onNotificacoes: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificações ainda não estão disponíveis.'),
          ),
        );
      },
    );
  }
}
