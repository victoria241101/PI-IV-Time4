// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Diálogos clínicos com validação, salvamento e erros.
// Formulário de diálogo compartilhado por consultas e registros de internação.
import 'package:flutter/material.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

class DialogoCamposClinica extends StatefulWidget {
  const DialogoCamposClinica({
    super.key,
    required this.titulo,
    required this.rotulos,
    this.valoresIniciais = const [],
    this.maxLines = 1,
    this.labelAcao = 'Salvar',
    this.onSalvar,
    this.camposObrigatorios = const [],
    this.aviso,
    this.bloquearEdicaoAposEnvio = false,
  });
  final String titulo;
  final List<String> rotulos;
  final List<String> valoresIniciais;
  final int maxLines;
  final String labelAcao;
  final Future<void> Function(List<String>)? onSalvar;
  final List<int> camposObrigatorios;
  final String? aviso;
  final bool bloquearEdicaoAposEnvio;
  @override
  State<DialogoCamposClinica> createState() => _DialogoCamposClinicaState();
}

class _DialogoCamposClinicaState extends State<DialogoCamposClinica> {
  late final List<TextEditingController> _controllers;
  // Estados separados evitam duplicar o envio e controlar novas tentativas.
  bool _salvando = false, _enviado = false;
  String? _erro;

  Future<void> _salvar() async {
    // Bloqueia nova ação enquanto a operação anterior ainda está em andamento.
    if (_salvando) return;
    final valores = _controllers.map((c) => c.text.trim()).toList();
    // Campos marcados são validados antes da primeira chamada assíncrona.
    if (widget.camposObrigatorios.any((i) => valores[i].isEmpty)) {
      setState(() => _erro = 'Preencha os campos obrigatórios.');
      return;
    }
    setState(() {
      _salvando = true;
      _enviado = true;
      _erro = null;
    });
    try {
      await widget.onSalvar?.call(valores);
      if (mounted) Navigator.pop(context, valores);
    // Mostra o erro da API e mantém os valores digitados no diálogo.
    } catch (erro) {
      if (mounted) {
        setState(() => _erro = erro.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.rotulos.length,
      (index) => TextEditingController(
        text: index < widget.valoresIniciais.length
            ? widget.valoresIniciais[index]
            : '',
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Impede fechar durante o salvamento para não perder ou duplicar a ação.
    canPop: !_salvando,
    child: AlertDialog(
      title: Text(widget.titulo, style: TipografiaApp.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.aviso != null)
              Text(widget.aviso!, style: TipografiaApp.caption),
            for (var i = 0; i < widget.rotulos.length; i++) ...[
              if (i > 0) const SizedBox(height: EspacamentosApp.sm),
              CampoFormularioApp(
                controller: _controllers[i],
                label: widget.rotulos[i],
                maxLines: widget.maxLines,
                enabled:
                    !_salvando && !(widget.bloquearEdicaoAposEnvio && _enviado),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            if (_erro != null) Text(_erro!, style: TipografiaApp.caption),
            if (_erro != null && widget.bloquearEdicaoAposEnvio)
              const Text(
                'Tente novamente para confirmar a mesma prescrição. Os dados foram mantidos para evitar duplicação.',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BotaoClinica(
          label: _salvando ? 'Salvando...' : widget.labelAcao,
          onPressed: _salvando ? null : _salvar,
        ),
      ],
    ),
  );
}
