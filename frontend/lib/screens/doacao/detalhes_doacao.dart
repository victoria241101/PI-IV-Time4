import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/doacao/doar.dart';

class DetalhesDoacao extends StatelessWidget {
  const DetalhesDoacao({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorArrecadado,
    required this.meta,
    this.urgente = false,
    this.imagemUrl,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorArrecadado;
  final double meta;
  final bool urgente;
  final String? imagemUrl;

  static const Color _laranja = CoresApp.accentOrange;
  static const Color _creme = Color(0xFFFFF2E5);

  double get progresso {
    if (meta <= 0) return 0;
    return (valorArrecadado / meta).clamp(0.0, 1.0);
  }

  int get porcentagem => (progresso * 100).round();

  double get valorRestante {
    if (meta <= valorArrecadado) return 0;
    return meta - valorArrecadado;
  }

  String _formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();

    for (var i = 0; i < inteiro.length; i++) {
      buffer.write(inteiro[i]);
      final restantes = inteiro.length - i - 1;

      if (restantes > 0 && restantes % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  Future<void> _iniciarDoacao(BuildContext context) async {
    Widget criarTelaDoacao() {
      return Doar(
        nomeAnimal: nomeAnimal,
        titulo: titulo,
        meta: meta,
      );
    }

    if (SessaoUsuario.instancia.estaLogado) {
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => criarTelaDoacao(),
        ),
      );

      if (resultado == true && context.mounted) {
        Navigator.of(context).pop(true);
      }

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          destinoAposLogin: criarTelaDoacao,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Column(
          children: [
            _Cabecalho(
              onVoltar: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: EspacamentosApp.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ImagemAnimal(
                      imagemUrl: imagemUrl,
                      urgente: urgente,
                      nomeAnimal: nomeAnimal,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EspacamentosApp.pagePadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: EspacamentosApp.lg),

                          Wrap(
                            spacing: EspacamentosApp.sm,
                            runSpacing: EspacamentosApp.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _Etiqueta(
                                texto: 'Campanha de $nomeAnimal',
                                corFundo: _creme,
                                corTexto: _laranja,
                                icone: Icons.pets_rounded,
                              ),
                              if (urgente)
                                const _Etiqueta(
                                  texto: 'Precisa de ajuda urgente',
                                  corFundo: Color(0xFFFFE6E2),
                                  corTexto: Color(0xFFB93825),
                                  icone: Icons.favorite_rounded,
                                ),
                            ],
                          ),

                          const SizedBox(height: EspacamentosApp.md),

                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 27,
                              height: 1.2,
                              letterSpacing: -0.6,
                              fontWeight: FontWeight.w800,
                              color: CoresApp.darkBlue,
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.sm),

                          Text(
                            'Conheça a campanha e veja como sua '
                                'contribuição pode fazer a diferença.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: CoresApp.textSecondary,
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.xl),

                          _CartaoProgresso(
                            valorArrecadado: valorArrecadado,
                            meta: meta,
                            valorRestante: valorRestante,
                            progresso: progresso,
                            porcentagem: porcentagem,
                            formatarValor: _formatarValor,
                          ),

                          const SizedBox(height: EspacamentosApp.xl),

                          const _TituloSecao(
                            titulo: 'Sobre a campanha',
                            subtitulo: 'Entenda a necessidade de apoio',
                          ),

                          const SizedBox(height: EspacamentosApp.md),

                          _CartaoInformativo(
                            icone: Icons.volunteer_activism_outlined,
                            corIcone: _laranja,
                            titulo: 'Sua ajuda importa',
                            descricao:
                            'Esta campanha busca arrecadar recursos '
                                'para os cuidados veterinários de '
                                '$nomeAnimal. Cada contribuição ajuda '
                                'a aproximar a campanha de sua meta.',
                          ),

                          const SizedBox(height: EspacamentosApp.xl),

                          const _TituloSecao(
                            titulo: 'Transparência',
                            subtitulo: 'Informações sobre a arrecadação',
                          ),

                          const SizedBox(height: EspacamentosApp.md),

                          _CartaoInformativo(
                            icone: Icons.receipt_long_outlined,
                            corIcone: _laranja,
                            titulo: 'Acompanhe a meta',
                            descricao:
                            'O valor arrecadado e a meta desta página '
                                'são exibidos para você acompanhar o '
                                'progresso informado da campanha.',
                          ),

                          const SizedBox(height: EspacamentosApp.sm),

                          _CartaoInformativo(
                            icone: Icons.info_outline_rounded,
                            corIcone: CoresApp.darkBlue,
                            titulo: 'Detalhes do caso',
                            descricao:
                            'As informações sobre o responsável, '
                                'o orçamento detalhado e as atualizações '
                                'do tratamento deverão ser disponibilizadas '
                                'quando esses dados estiverem cadastrados '
                                'e integrados ao aplicativo.',
                          ),

                          const SizedBox(height: EspacamentosApp.xl),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                              EspacamentosApp.lg,
                            ),
                            decoration: BoxDecoration(
                              color: _creme,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _laranja.withAlpha(35),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: _laranja,
                                  size: 25,
                                ),
                                SizedBox(height: EspacamentosApp.sm),
                                Text(
                                  'Faça parte dessa história',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: CoresApp.darkBlue,
                                  ),
                                ),
                                SizedBox(height: EspacamentosApp.xs),
                                Text(
                                  'Escolha o valor com que deseja '
                                      'contribuir e revise os detalhes '
                                      'antes de continuar.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: CoresApp.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.lg),

                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: () => _iniciarDoacao(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CoresApp.darkBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              icon: const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 21,
                              ),
                              label: const Text(
                                'Quero ajudar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.sm),

                          const Center(
                            child: Text(
                              'Você poderá revisar o valor antes de continuar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: CoresApp.textSecondary,
                              ),
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
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.onVoltar,
  });

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.sm,
        EspacamentosApp.xs,
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: onVoltar,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CoresApp.darkBlue,
            ),
          ),
          const SizedBox(width: EspacamentosApp.xs),
          const Expanded(
            child: Text(
              'Detalhes da campanha',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CoresApp.darkBlue,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: CoresApp.accentOrange,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagemAnimal extends StatelessWidget {
  const _ImagemAnimal({
    required this.urgente,
    required this.nomeAnimal,
    this.imagemUrl,
  });

  final bool urgente;
  final String nomeAnimal;
  final String? imagemUrl;

  @override
  Widget build(BuildContext context) {
    final url = imagemUrl?.trim();
    final possuiImagem = url != null && url.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 245,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (possuiImagem)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _placeholderImagem();
              },
            )
          else
            _placeholderImagem(),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x44000000),
                ],
              ),
            ),
          ),

          Positioned(
            left: EspacamentosApp.pagePadding,
            bottom: EspacamentosApp.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(240),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    color: CoresApp.accentOrange,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    nomeAnimal,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CoresApp.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (urgente)
            const Positioned(
              top: EspacamentosApp.md,
              right: EspacamentosApp.pagePadding,
              child: _Etiqueta(
                texto: 'Urgente',
                corFundo: CoresApp.accentOrange,
                corTexto: Colors.white,
                icone: Icons.priority_high_rounded,
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderImagem() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE9D0),
            Color(0xFFFFF5EA),
            Color(0xFFF5E9DA),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            size: 61,
            color: CoresApp.accentOrange,
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.corFundo,
    required this.corTexto,
    required this.icone,
  });

  final String texto;
  final Color corFundo;
  final Color corTexto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            color: corTexto,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: corTexto,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoProgresso extends StatelessWidget {
  const _CartaoProgresso({
    required this.valorArrecadado,
    required this.meta,
    required this.valorRestante,
    required this.progresso,
    required this.porcentagem,
    required this.formatarValor,
  });

  final double valorArrecadado;
  final double meta;
  final double valorRestante;
  final double progresso;
  final int porcentagem;
  final String Function(double) formatarValor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: CoresApp.accentOrange.withAlpha(45),
        ),
        boxShadow: [
          BoxShadow(
            color: CoresApp.accentOrange.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: CoresApp.accentOrange,
                  size: 23,
                ),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              const Expanded(
                child: Text(
                  'Progresso da campanha',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                  color: const Color(0xFFFFF0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$porcentagem%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.accentOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: EspacamentosApp.lg),

          Text(
            formatarValor(valorArrecadado),
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: CoresApp.darkBlue,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'arrecadados de ${formatarValor(meta)}',
            style: const TextStyle(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),

          const SizedBox(height: EspacamentosApp.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 12,
              backgroundColor: const Color(0xFFFFE8D2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CoresApp.accentOrange,
              ),
            ),
          ),

          const SizedBox(height: EspacamentosApp.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.flag_outlined,
                color: CoresApp.accentOrange,
                size: 19,
              ),
              const SizedBox(width: EspacamentosApp.xs),
              Expanded(
                child: Text(
                  valorRestante > 0
                      ? 'Faltam ${formatarValor(valorRestante)} '
                      'para alcançar a meta.'
                      : 'A meta informada foi alcançada!',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.titulo,
    required this.subtitulo,
  });

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: CoresApp.darkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: CoresApp.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CartaoInformativo extends StatelessWidget {
  const _CartaoInformativo({
    required this.icone,
    required this.corIcone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: corIcone.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icone,
              color: corIcone,
              size: 23,
            ),
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}