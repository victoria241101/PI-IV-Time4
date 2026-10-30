
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool _estaLogado = false;
  String? _nomeUsuario;
  String? _emailUsuario;
  String? _token;
  bool _ehTutor = false;

  bool get estaLogado => _estaLogado;
  String? get nomeUsuario => _nomeUsuario;
  String? get emailUsuario => _emailUsuario;
  String? get token => _token;
  bool get ehTutor => _ehTutor;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _token = await _armazenamentoSeguro.read(key: _chaveToken);

    _estaLogado = _token != null &&
        _token!.isNotEmpty &&
        (prefs.getBool(_chaveLogado) ?? false);

    if (_estaLogado) {
      _nomeUsuario = prefs.getString(_chaveNome);
      _emailUsuario = prefs.getString(_chaveEmail);
      _ehTutor = prefs.getBool(_chaveEhTutor) ?? false;
    } else {
      _nomeUsuario = null;
      _emailUsuario = null;
      _ehTutor = false;
    }

    notifyListeners();
  }

  Future<void> entrar({
    required String nome,
    required String email,
    required String token,
    bool ehTutor = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await _armazenamentoSeguro.write(
      key: _chaveToken,
      value: token,
    );

    await prefs.setBool(_chaveLogado, true);
    await prefs.setString(_chaveNome, nome.trim());
    await prefs.setString(_chaveEmail, email.trim());
    await prefs.setBool(_chaveEhTutor, ehTutor);

    _token = token;
    _estaLogado = true;
    _nomeUsuario = nome.trim();
    _emailUsuario = email.trim();
    _ehTutor = ehTutor;

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

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_chaveNome, nomeNormalizado);
    await prefs.setString(_chaveEmail, emailNormalizado);

    _nomeUsuario = nomeNormalizado;
    _emailUsuario = emailNormalizado;

    notifyListeners();
  }

  Future<void> tornarTutor() async {
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

    _token = null;
    _estaLogado = false;
    _nomeUsuario = null;
    _emailUsuario = null;
    _ehTutor = false;

    notifyListeners();
  }
}
