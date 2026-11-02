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
  });
  final String titulo;
  final List<String> rotulos;
  final List<String> valoresIniciais;
  final int maxLines;
  final String labelAcao;
  @override
  State<DialogoCamposClinica> createState() => _DialogoCamposClinicaState();
}

class _DialogoCamposClinicaState extends State<DialogoCamposClinica> {
  late final List<TextEditingController> _controllers;
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.titulo, style: TipografiaApp.heading3),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.rotulos.length; i++) ...[
            if (i > 0) const SizedBox(height: EspacamentosApp.sm),
            CampoFormularioApp(
              controller: _controllers[i],
              label: widget.rotulos[i],
              maxLines: widget.maxLines,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      BotaoClinica(
        label: widget.labelAcao,
        onPressed: () => Navigator.pop(
          context,
          _controllers.map((controller) => controller.text.trim()).toList(),
        ),
      ),
    ],
  );
}
