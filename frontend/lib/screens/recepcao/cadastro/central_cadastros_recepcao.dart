import 'package:flutter/material.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/formulario_administrativo.dart';
import 'package:pet_care/widgets/cartao_opcao_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

class CentralCadastrosRecepcao extends StatefulWidget {
  const CentralCadastrosRecepcao({super.key});
  @override
  State<CentralCadastrosRecepcao> createState() =>
      _CentralCadastrosRecepcaoState();
}

class _CentralCadastrosRecepcaoState extends State<CentralCadastrosRecepcao> {
  final _cadastros = CadastrosRecepcaoLocal.instancia;
  String _tipo(TipoCadastroRecepcao tipo) => switch (tipo) {
    TipoCadastroRecepcao.funcionario => 'Funcionário',
    TipoCadastroRecepcao.tutorPet => 'Tutor e pet',
    TipoCadastroRecepcao.campanha => 'Pet em Doações',
    TipoCadastroRecepcao.banner => 'Banner',
  };
  void _guardar(RegistroRecepcaoLocal registro) {
    setState(() => _cadastros.registros.add(registro));
  }

  Future<void> _abrir(TipoCadastroRecepcao tipo) async {
    if (tipo == TipoCadastroRecepcao.tutorPet) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: CoresApp.background,
            appBar: cabecalhoClinica('Cadastrar tutor e pet'),
            body: CadastroRecepcao(
              somenteCadastro: true,
              onRegistrarConsulta: (_) => false,
              onCadastroConcluido: _guardar,
            ),
          ),
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    final registro = await Navigator.of(context).push<RegistroRecepcaoLocal>(
      MaterialPageRoute(builder: (_) => FormularioAdministrativo(tipo: tipo)),
    );
    if (!mounted || registro == null) return;
    _guardar(registro);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_tipo(tipo)} salvo nesta sessão de revisão.')),
    );
  }

  Future<void> _verRegistro(RegistroRecepcaoLocal registro) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(registro.nome),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tipo(registro.tipo)),
            const SizedBox(height: 12),
            for (final item in registro.dados.entries.where(
              (e) => e.value.isNotEmpty,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_rotulo(item.key)}: ${_valor(item.key, item.value)}',
                ),
              ),
            ..._campanhaVinculadaWidgets(registro),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
  String _rotulo(String chave) =>
      const {
        'cpf': 'CPF',
        'email': 'E-mail',
        'telefone': 'Celular',
        'crmv': 'CRMV',
        'registro': 'Registro',
        'cargo': 'Função',
        'nomeAnimal': 'Animal',
        'urgente': 'Urgente',
        'dataInicio': 'Início',
        'dataFim': 'Término',
        'metaValor': 'Meta (R\$)',
        'imagemCapa': 'Imagem de capa',
        'descricao': 'Descrição',
        'raca': 'Raça',
        'especie': 'Espécie',
        'endereco': 'Endereço',
        'condicoes': 'Condições clínicas',
        'vacinado': 'Vacinação em dia',
        'especialidade': 'Especialidade',
        'status': 'Status',
        'identificacao': 'Identificação',
        'imagem': 'Imagem (URL)',
        'campanhaVinculadaId': 'Campanha vinculada',
        'castrado': 'Castrado(a)',
        'microchip': 'Possui microchip',
        'dataNascimento': 'Data de nascimento',
        'pet': 'Pet',
        'porte': 'Porte',
        'local': 'Cidade / UF',
        'foto': 'Foto (URL)',
        'id': 'ID local',
      }[chave] ??
      '${chave[0].toUpperCase()}${chave.substring(1)}';
  List<Widget> _campanhaVinculadaWidgets(RegistroRecepcaoLocal registro) {
    if (registro.tipo != TipoCadastroRecepcao.banner) return const [];
    final campId = registro.dados['campanhaVinculadaId'];
    if (campId == null || campId.isEmpty) return const [];
    final camp = _cadastros.registros.firstWhere(
      (r) => r.tipo == TipoCadastroRecepcao.campanha && r.dados['id'] == campId,
      orElse: () => RegistroRecepcaoLocal(
        tipo: TipoCadastroRecepcao.campanha,
        nome: campId,
        dados: const {},
      ),
    );
    return [
      const SizedBox(height: 4),
      Text('Campanha vinculada: ${camp.nome}'),
    ];
  }

  String _valor(String chave, String valor) {
    if (chave == 'dataInicio' || chave == 'dataFim') {
      final data = DateTime.tryParse(valor);
      if (data != null) return '${data.day}/${data.month}/${data.year}';
    }
    return valor;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Cadastros', style: TipografiaApp.heading2),
      const SizedBox(height: 8),
      Text('O que você deseja cadastrar?', style: TipografiaApp.bodySmall),
      const SizedBox(height: 20),
      CartaoOpcaoApp(
        icon: Icons.person_add_alt_1_outlined,
        titulo: 'Tutor e pet',
        descricao:
            'Cadastre o responsável e seu pet, sem precisar agendar agora',
        onTap: () => _abrir(TipoCadastroRecepcao.tutorPet),
      ),
      const SizedBox(height: 12),
      CartaoOpcaoApp(
        icon: Icons.badge_outlined,
        titulo: 'Funcionário',
        descricao: 'Enfermeiro, veterinário ou secretária',
        onTap: () => _abrir(TipoCadastroRecepcao.funcionario),
      ),
      const SizedBox(height: 12),
      CartaoOpcaoApp(
        icon: Icons.campaign_outlined,
        titulo: 'Adicionar pet em Doações',
        onTap: () => _abrir(TipoCadastroRecepcao.campanha),
      ),
      const SizedBox(height: 12),
      CartaoOpcaoApp(
        icon: Icons.photo_outlined,
        titulo: 'Banner',
        descricao: 'Imagem exibida no carrossel da página inicial',
        onTap: () => _abrir(TipoCadastroRecepcao.banner),
      ),
      const SizedBox(height: 24),
      Text(
        'Tutor e pet são salvos no sistema. Os demais cadastros ainda são uma prévia local.',
        style: TipografiaApp.caption,
      ),
      if (_cadastros.registros.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(
          'Cadastros realizados nesta sessão',
          style: TipografiaApp.heading3,
        ),
        const SizedBox(height: 8),
        for (final registro in _cadastros.registros.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(registro.nome),
            subtitle: Text(_tipo(registro.tipo)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _verRegistro(registro),
          ),
      ],
    ],
  );
}
