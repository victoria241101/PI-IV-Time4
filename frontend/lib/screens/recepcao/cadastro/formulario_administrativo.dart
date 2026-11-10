import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

/// Formulários da recepção: apenas prévia local até conectar os serviços.
class FormularioAdministrativo extends StatefulWidget {
  const FormularioAdministrativo({super.key, required this.tipo});
  final TipoCadastroRecepcao tipo;
  @override
  State<FormularioAdministrativo> createState() =>
      _FormularioAdministrativoState();
}

class _FormularioAdministrativoState extends State<FormularioAdministrativo> {
  final _form = GlobalKey<FormState>();
  final _campos = <String, TextEditingController>{};
  String _cargo = 'Enfermeiro';
  DateTime? _inicio;
  DateTime? _fim;
  String? _erroDatas;
  String? _campanhaVinculadaId;
  TextEditingController _campo(String nome) =>
      _campos.putIfAbsent(nome, TextEditingController.new);
  bool get _funcionario => widget.tipo == TipoCadastroRecepcao.funcionario;
  bool get _campanha => widget.tipo == TipoCadastroRecepcao.campanha;
  String get _titulo => _funcionario
      ? 'Cadastrar funcionário'
      : _campanha
      ? 'Adicionar pet em Doações'
      : 'Cadastrar banner';

  @override
  void dispose() {
    for (final controller in _campos.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _obrigatorio(String? texto) =>
      texto == null || texto.trim().isEmpty ? 'Preencha este campo' : null;
  String? _email(String? texto) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texto?.trim() ?? '')
      ? null
      : 'Informe um e-mail válido';
  String? _url(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    final uri = Uri.tryParse(texto.trim());
    return uri != null &&
            ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? null
        : 'Informe um endereço http ou https';
  }

  String? _validarCpf(String? v) {
    final cpf = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return 'Informe os 11 números do CPF';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return 'CPF inválido';
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int r = (soma * 10) % 11;
    if (r == 10 || r == 11) r = 0;
    if (r != int.parse(cpf[9])) return 'CPF inválido';
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    r = (soma * 10) % 11;
    if (r == 10 || r == 11) r = 0;
    if (r != int.parse(cpf[10])) return 'CPF inválido';
    return null;
  }

  Widget _texto(
    String chave,
    String label, {
    int linhas = 1,
    bool obrigatorio = true,
    TextInputType? teclado,
    FormFieldValidator<String>? validar,
    List<TextInputFormatter>? formato,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: CampoFormularioApp(
      controller: _campo(chave),
      label: label,
      maxLines: linhas,
      keyboardType: teclado,
      inputFormatters: formato,
      validator: validar ?? (obrigatorio ? _obrigatorio : null),
    ),
  );
  Widget _opcoes(
    String titulo,
    String valor,
    List<String> opcoes,
    ValueChanged<String> mudar,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
      ),
      items: opcoes
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => mudar(v));
      },
    ),
  );
  String _data(DateTime? valor) => valor == null
      ? 'Selecionar'
      : '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';
  Future<void> _escolherData(bool inicio) async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final data = await showDatePicker(
      context: context,
      initialDate: (inicio ? _inicio : _fim) ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 5),
      helpText: inicio ? 'Início da campanha' : 'Fim da campanha',
    );
    if (data != null && mounted) {
      setState(() {
        if (inicio) {
          _inicio = data;
        } else {
          _fim = data;
        }
        _erroDatas = null;
      });
    }
  }

  void _salvar() {
    final valido = _form.currentState!.validate();
    if (_campanha &&
        (_inicio == null || _fim == null || _fim!.isBefore(_inicio!))) {
      setState(
        () => _erroDatas =
            'Escolha as duas datas; o fim não pode ser anterior ao início.',
      );
      return;
    }
    if (!valido) return;
    final dados = {
      for (final item in _campos.entries) item.key: item.value.text.trim(),
    };
    if (_funcionario) {
      dados['cargo'] = _cargo;
      if (_cargo != 'Veterinário') {
        dados.remove('crmv');
        dados.remove('especialidade');
      }
      if (_cargo != 'Secretária') {
        dados.remove('cpf');
      }
      if (_cargo != 'Enfermeiro') {
        dados.remove('registro');
      }
      final repetido = CadastrosRecepcaoLocal.instancia.registros.any(
        (r) =>
            r.tipo == TipoCadastroRecepcao.funcionario &&
            r.dados['email']?.toLowerCase() == dados['email']?.toLowerCase(),
      );
      if (repetido) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Já existe um funcionário com este e-mail nesta prévia.',
            ),
          ),
        );
        return;
      }
    } else if (_campanha) {
      dados['dataInicio'] = _inicio!.toIso8601String();
      dados['dataFim'] = _fim!.toIso8601String();
      dados['status'] = 'ativa';
      dados['valorArrecadado'] = '0';
      dados['id'] = 'local-${DateTime.now().microsecondsSinceEpoch}';
    } else {
      // banner
      if (_campanhaVinculadaId != null) {
        dados['campanhaVinculadaId'] = _campanhaVinculadaId!;
      }
    }
    Navigator.pop(
      context,
      RegistroRecepcaoLocal(
        tipo: widget.tipo,
        nome: _campanha
            ? dados['titulo']!
            : (widget.tipo == TipoCadastroRecepcao.banner)
            ? dados['identificacao']!
            : dados['nome']!,
        dados: dados,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CoresApp.background,
    appBar: cabecalhoClinica(_titulo),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _funcionario
                      ? 'Dados do profissional'
                      : _campanha
                      ? 'Ajuda financeira para o tratamento do pet'
                      : 'Novo banner',
                  style: TipografiaApp.heading2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Prévia local: os dados ficam disponíveis nesta sessão e não são publicados.',
                  style: TipografiaApp.caption,
                ),
                const SizedBox(height: 24),
                if (_funcionario) ...[
                  _opcoes(
                    'Função',
                    _cargo,
                    ['Enfermeiro', 'Veterinário', 'Secretária'],
                    (v) {
                      _cargo = v;
                      if (v != 'Veterinário') {
                        _campo('crmv').clear();
                        _campo('especialidade').clear();
                      }
                      if (v != 'Enfermeiro') {
                        _campo('registro').clear();
                      }
                      if (v != 'Secretária') {
                        _campo('cpf').clear();
                      }
                    },
                  ),
                  _texto('nome', 'Nome completo'),
                  _texto(
                    'email',
                    'E-mail para acesso',
                    teclado: TextInputType.emailAddress,
                    validar: _email,
                  ),
                  _texto(
                    'telefone',
                    'Celular',
                    teclado: TextInputType.phone,
                    validar: (v) =>
                        (v ?? '').replaceAll(RegExp(r'\D'), '').length >= 10
                        ? null
                        : 'Informe o celular com DDD',
                  ),
                  if (_cargo == 'Veterinário') ...[
                    _texto('crmv', 'CRMV'),
                    _texto(
                      'especialidade',
                      'Especialidade',
                      obrigatorio: false,
                    ),
                  ],
                  if (_cargo == 'Enfermeiro') _texto('registro', 'Registro'),
                  if (_cargo == 'Secretária')
                    _texto(
                      'cpf',
                      'CPF',
                      teclado: TextInputType.number,
                      formato: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validar: _validarCpf,
                    ),
                  Text(
                    'A conta de acesso será criada quando conectarmos este cadastro ao serviço de login.',
                    style: TipografiaApp.caption,
                  ),
                ] else if (_campanha) ...[
                  _texto('titulo', 'Título da campanha'),
                  _texto('descricao', 'Descrição e objetivo', linhas: 4),
                  _texto(
                    'metaValor',
                    'Meta de arrecadação (R\$)',
                    teclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validar: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return n != null && n.isFinite && n > 0
                          ? null
                          : 'Informe um valor maior que zero';
                    },
                  ),
                  _texto(
                    'imagemCapa',
                    'Link da imagem de capa (opcional)',
                    obrigatorio: false,
                    teclado: TextInputType.url,
                    validar: _url,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de início'),
                    subtitle: Text(_data(_inicio)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () => _escolherData(true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data de término'),
                    subtitle: Text(_data(_fim)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () => _escolherData(false),
                  ),
                  if (_erroDatas != null)
                    Text(
                      _erroDatas!,
                      style: const TextStyle(color: CoresApp.danger),
                    ),
                ] else ...[
                  // Banner
                  _texto('identificacao', 'Identificação do banner'),
                  _texto(
                    'imagem',
                    'URL da imagem',
                    teclado: TextInputType.url,
                    validar: (v) => _obrigatorio(v) ?? _url(v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Builder(
                      builder: (context) {
                        final campanhas =
                            CadastrosRecepcaoLocal.instancia.campanhasLocais;
                        if (campanhas.isEmpty) {
                          return const Text(
                            'Nenhuma campanha cadastrada nesta sessão.',
                          );
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: _campanhaVinculadaId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Campanha vinculada (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Nenhuma'),
                            ),
                            ...campanhas.map(
                              (c) => DropdownMenuItem<String>(
                                value: c.dados['id'],
                                child: Text(c.nome),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _campanhaVinculadaId = v),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BotaoClinica(
                  label: 'Salvar cadastro',
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: _salvar,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
