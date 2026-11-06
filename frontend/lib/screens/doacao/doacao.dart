import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/publicos/cabecalho_publico.dart';
import 'package:pet_care/widgets/gerais/cabecalho_geral.dart';

import 'package:pet_care/widgets/cartao_campanha.dart';
import 'package:pet_care/services/campanhas_service.dart';

import 'detalhes_doacao.dart';

class Doacao extends StatefulWidget {
  const Doacao({
    super.key,
    this.publica = false,
    this.geral = false,
    this.onDoacaoConcluida,
  }) : assert(
  !(publica && geral),
  'A tela não pode pertencer aos contextos público e geral ao mesmo tempo.',
  );

  final bool publica;
  final bool geral;
  final VoidCallback? onDoacaoConcluida;

  bool get tutor => !publica && !geral;

  @override
  State<Doacao> createState() => _DoacaoState();
}

class _DoacaoState extends State<Doacao> {
  final CampanhasService _campanhasService = CampanhasService.criar(
    baseUrl: 'http://localhost:3000',
  );

  List<Map<String, dynamic>> _campanhas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCampanhas();
  }

  Future<void> _carregarCampanhas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _campanhasService.listarCampanhas();
      if (!mounted) return;

      setState(() {
        _campanhas = resultado
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((campanha) => campanha['status'] == 'ativa')
            .toList();
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  String? _imagem(dynamic valor) {
    if (valor is String && valor.trim().isNotEmpty) return valor;
    return null;
  }

  Widget _listaCampanhas() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Column(
        children: [
          Text(
            'Não foi possível carregar as campanhas. $_erro',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresApp.textSecondary),
          ),
          const SizedBox(height: EspacamentosApp.sm),
          TextButton(
            onPressed: _carregarCampanhas,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_campanhas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma campanha ativa no momento.',
          style: TextStyle(color: CoresApp.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _campanhas.length; i++) ...[
          if (i > 0) const SizedBox(height: EspacamentosApp.lg),
          Builder(builder: (context) {
            final campanha = _campanhas[i];
            final campanhaId = campanha['_id']?.toString() ?? '';
            final nomeAnimal = (campanha['nomeAnimal'] as String?)
                    ?.trim()
                    .isNotEmpty == true
                ? campanha['nomeAnimal'] as String
                : 'Campanha';
            final titulo = campanha['titulo']?.toString() ?? 'Campanha';
            final valorArrecadado = _numero(campanha['valorArrecadado']);
            final meta = _numero(campanha['metaValor']);
            final imagemUrl = _imagem(campanha['imagemCapa']);

            return CartaoCampanha(
              nomeAnimal: nomeAnimal,
              titulo: titulo,
              valorArrecadado: valorArrecadado,
              meta: meta,
              imagemUrl: imagemUrl,
              onTap: () => _abrirCampanha(
                campanhaId: campanhaId,
                nomeAnimal: nomeAnimal,
                titulo: titulo,
                valorArrecadado: valorArrecadado,
                meta: meta,
                imagemUrl: imagemUrl,
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _abrirCampanha({
    required String campanhaId,
    required String nomeAnimal,
    required String titulo,
    required double valorArrecadado,
    required double meta,
    bool urgente = false,
    String? imagemUrl,
  }) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DetalhesDoacao(
          campanhaId: campanhaId,
          nomeAnimal: nomeAnimal,
          titulo: titulo,
          valorArrecadado: valorArrecadado,
          meta: meta,
          urgente: urgente,
          imagemUrl: imagemUrl,
        ),
      ),
    );

    if (!mounted) return;

    await _carregarCampanhas();

    if (resultado == true) {
      widget.onDoacaoConcluida?.call();
    }
  }

  Widget _construirCabecalho() {
    if (widget.publica) {
      return const CabecalhoPublico();
    }

    if (widget.geral) {
      return const CabecalhoGeral();
    }

    return const CabecalhoApp(
      greeting: 'Cuide. Ajude. Transforme.',
      name: '',
    );
  }

  String _formatarMoeda(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      buffer.write(inteiro[i]);

      final restantes = inteiro.length - i - 1;

      if (restantes > 0 && restantes % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: EspacamentosApp.lg,
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirCabecalho(),

              const SizedBox(height: EspacamentosApp.xl),

              // APRESENTAÇÃO

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 15,
                            color: CoresApp.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'CUIDADO QUE TRANSFORMA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: CoresApp.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    const Text(
                      'Campanhas',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.15,
                        color: CoresApp.darkBlue,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.sm),

                    Text(
                      widget.publica
                          ? 'Conheça os animais que precisam de ajuda '
                          'e descubra como fazer a diferença.'
                          : 'Cada contribuição pode ajudar um animal '
                          'a receber os cuidados de que precisa.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // RESUMO DAS CAMPANHAS

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EspacamentosApp.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CoresApp.darkBlue.withAlpha(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _IconeDestaque(),
                      SizedBox(width: EspacamentosApp.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pequenos gestos, grandes mudanças',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: CoresApp.darkBlue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Conheça cada história e escolha '
                                  'como ajudar.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: CoresApp.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // TÍTULO DA SEÇÃO

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Campanhas ativas',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CoresApp.darkBlue.withAlpha(15),
                        ),
                      ),
                      child: Text(
                        '${_campanhas.length} ${_campanhas.length == 1 ? 'campanha' : 'campanhas'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              // LISTA DE CAMPANHAS

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: _listaCampanhas(),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // AVISO INFORMATIVO

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EspacamentosApp.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withAlpha(12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: CoresApp.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: CoresApp.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: EspacamentosApp.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajude com segurança',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: CoresApp.darkBlue,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'As campanhas são públicas. Para realizar '
                                  'uma doação, é necessário estar autenticado.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: CoresApp.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconeDestaque extends StatelessWidget {
  const _IconeDestaque();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.volunteer_activism_outlined,
        size: 25,
        color: CoresApp.primary,
      ),
    );
  }
}