import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_care/screens/autenticacao/service/perfil_service.dart';

class SessaoUsuario extends ChangeNotifier {
  SessaoUsuario._();

  static final SessaoUsuario instancia = SessaoUsuario._();

  static const FlutterSecureStorage _armazenamentoSeguro =
  FlutterSecureStorage();

  static const String _chaveToken = 'usuario_token';
  static const String _chaveLogado = 'usuario_logado';
  static const String _chaveNome = 'usuario_nome';
  static const String _chaveEmail = 'usuario_email';
  static const String _chaveEhTutor = 'usuario_eh_tutor';
  static const String _chaveTipoUsuario = 'usuario_tipo';

  bool _estaLogado = false;
  String? _nomeUsuario;
  String? _emailUsuario;
  String? _token;
  bool _ehTutor = false;
  String _tipoUsuario = 'USUARIO';

  bool get estaLogado => _estaLogado;
  String? get nomeUsuario => _nomeUsuario;
  String? get emailUsuario => _emailUsuario;
  String? get token => _token;
  bool get ehTutor => _ehTutor;
  String get tipoUsuario => _tipoUsuario;

  bool get ehVeterinario => _tipoUsuario == 'VETERINARIO';
  bool get ehEnfermeiro => _tipoUsuario == 'ENFERMEIRO';
  bool get ehSecretaria => _tipoUsuario == 'SECRETARIA';

  bool get ehEquipeClinica =>
      ehVeterinario || ehEnfermeiro || ehSecretaria;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _token = await _armazenamentoSeguro.read(key: _chaveToken);

    _estaLogado = _token != null &&
        _token!.isNotEmpty &&
        (prefs.getBool(_chaveLogado) ?? false);

    if (_estaLogado) {
      _nomeUsuario = prefs.getString(_chaveNome);
      _emailUsuario = prefs.getString(_chaveEmail);

      _tipoUsuario =
          (prefs.getString(_chaveTipoUsuario) ?? 'USUARIO').toUpperCase();

      _ehTutor = _tipoUsuario == 'USUARIO' &&
          (prefs.getBool(_chaveEhTutor) ?? false);
    } else {
      _nomeUsuario = null;
      _emailUsuario = null;
      _ehTutor = false;
      _tipoUsuario = 'USUARIO';
    }

    notifyListeners();
  }

  Future<void> entrar({
    required String nome,
    required String email,
    required String token,
    String tipoUsuario = 'USUARIO',
    bool ehTutor = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final tipoNormalizado = tipoUsuario.trim().toUpperCase();

    await _armazenamentoSeguro.write(
      key: _chaveToken,
      value: token,
    );

    await prefs.setBool(_chaveLogado, true);
    await prefs.setString(_chaveNome, nome.trim());
    await prefs.setString(_chaveEmail, email.trim());
    await prefs.setString(_chaveTipoUsuario, tipoNormalizado);

    final tutor = tipoNormalizado == 'USUARIO' && ehTutor;

    await prefs.setBool(_chaveEhTutor, tutor);

    _token = token;
    _estaLogado = true;
    _nomeUsuario = nome.trim();
    _emailUsuario = email.trim();
    _tipoUsuario = tipoNormalizado;
    _ehTutor = tutor;

    notifyListeners();
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String email,
  }) async {
    if (!_estaLogado) {
      throw StateError(
        'Não é possível atualizar um perfil sem sessão ativa.',
      );
    }

    final nomeNormalizado = nome.trim();
    final emailNormalizado = email.trim();

    if (nomeNormalizado.length < 2) {
      throw ArgumentError('Informe um nome válido.');
    }

    final emailValido = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(emailNormalizado);

    if (!emailValido) {
      throw ArgumentError('Informe um e-mail válido.');
    }

    final servico = PerfilService.autenticado(
      baseUrl: 'http://localhost:3000',
    );

    final resposta = await servico.atualizarPerfil(
      nome: nomeNormalizado,
      email: emailNormalizado,
    );

    // A solicitação foi enviada, mas ainda depende da confirmação
    // por e-mail. Não atualizamos os dados locais neste momento.
    debugPrint(resposta['mensagem']?.toString());
  }

  Future<void> tornarTutor() async {
    if (!_estaLogado || _tipoUsuario != 'USUARIO') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_chaveEhTutor, true);

    _ehTutor = true;

    notifyListeners();
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();

    await _armazenamentoSeguro.delete(key: _chaveToken);

    await prefs.remove(_chaveLogado);
    await prefs.remove(_chaveNome);
    await prefs.remove(_chaveEmail);
    await prefs.remove(_chaveEhTutor);
    await prefs.remove(_chaveTipoUsuario);

    _token = null;
    _estaLogado = false;
    _nomeUsuario = null;
    _emailUsuario = null;
    _ehTutor = false;
    _tipoUsuario = 'USUARIO';

    notifyListeners();
  }
}