import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessaoUsuario extends ChangeNotifier {
  SessaoUsuario._();

  static final SessaoUsuario instancia = SessaoUsuario._();

  static const String _chaveLogado = 'usuario_logado';
  static const String _chaveNome = 'usuario_nome';
  static const String _chaveEmail = 'usuario_email';
  static const String _chaveEhTutor = 'usuario_eh_tutor';

  bool _estaLogado = false;
  String? _nomeUsuario;
  String? _emailUsuario;
  bool _ehTutor = false;

  bool get estaLogado => _estaLogado;
  String? get nomeUsuario => _nomeUsuario;
  String? get emailUsuario => _emailUsuario;
  bool get ehTutor => _ehTutor;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    _estaLogado = prefs.getBool(_chaveLogado) ?? false;
    _nomeUsuario = prefs.getString(_chaveNome);
    _emailUsuario = prefs.getString(_chaveEmail);
    _ehTutor = prefs.getBool(_chaveEhTutor) ?? false;

    notifyListeners();
  }

  Future<void> entrar({
    required String nome,
    required String email,
  }) async {
    _estaLogado = true;
    _nomeUsuario = nome;
    _emailUsuario = email;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_chaveLogado, true);
    await prefs.setString(_chaveNome, nome);
    await prefs.setString(_chaveEmail, email);

    notifyListeners();
  }

  Future<void> tornarTutor() async {
    _ehTutor = true;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_chaveEhTutor, true);

    notifyListeners();
  }

  Future<void> sair() async {
    _estaLogado = false;
    _nomeUsuario = null;
    _emailUsuario = null;
    _ehTutor = false;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_chaveLogado);
    await prefs.remove(_chaveNome);
    await prefs.remove(_chaveEmail);
    await prefs.remove(_chaveEhTutor);

    notifyListeners();
  }
}