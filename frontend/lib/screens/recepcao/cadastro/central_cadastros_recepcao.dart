// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Menu de cadastros de tutor/pet, funcionário e campanha.
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/formulario_administrativo.dart';
import 'package:pet_care/widgets/cartao_opcao_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

class CentralCadastrosRecepcao extends StatefulWidget {
  const CentralCadastrosRecepcao({super.key, this.cadastrosService});
  final CadastrosRecepcaoService? cadastrosService;
  @override
  State<CentralCadastrosRecepcao> createState() =>
      _CentralCadastrosRecepcaoState();
}

class _CentralCadastrosRecepcaoState extends State<CentralCadastrosRecepcao> {
  Future<void> _selecionarTutorPet() async {
    final novoTutor = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tutor e pet', style: TipografiaApp.heading3),
              const SizedBox(height: 12),
              CartaoOpcaoApp(
                icon: Icons.person_add_alt_1_outlined,
                titulo: 'Novo tutor',
                descricao: 'Cadastre o responsável e o primeiro pet',
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 12),
              CartaoOpcaoApp(
                icon: Icons.person_search_outlined,
                titulo: 'Tutor existente',
                descricao: 'Localize pelo CPF e cadastre outro pet',
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || novoTutor == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: CoresApp.background,
          appBar: cabecalhoClinica(
            novoTutor ? 'Cadastrar tutor e pet' : 'Cadastrar pet',
          ),
          body: CadastroRecepcao(
            somenteCadastro: novoTutor,
            somentePet: !novoTutor,
            onRegistrarConsulta: (_) => false,
            cadastrosService: widget.cadastrosService,
          ),
        ),
      ),
    );
  }

  Future<void> _abrir(TipoCadastroRecepcao tipo) async {
    if (tipo != TipoCadastroRecepcao.tutorPet &&
        tipo != TipoCadastroRecepcao.funcionario &&
        tipo != TipoCadastroRecepcao.campanha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cadastro ainda não está disponível.'),
        ),
      );
      return;
    }
    if (tipo == TipoCadastroRecepcao.tutorPet) return _selecionarTutorPet();
    final registro = await Navigator.of(context).push<RegistroRecepcaoLocal>(
      MaterialPageRoute(
        builder: (_) => FormularioAdministrativo(
          tipo: tipo,
          cadastrosService: widget.cadastrosService,
        ),
      ),
    );
    if (!mounted || registro == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tipo == TipoCadastroRecepcao.funcionario
              ? 'Funcionário cadastrado. Primeiro acesso pelo Esqueci a senha.'
              : 'Campanha cadastrada e publicada.',
        ),
      ),
    );
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
        descricao: 'Cadastre um novo tutor ou adicione pet a tutor existente',
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
    ],
  );
}
