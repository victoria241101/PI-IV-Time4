import 'package:flutter/foundation.dart';

class SessaoUsuario extends ChangeNotifier {
  SessaoUsuario._();

  static final SessaoUsuario instancia = SessaoUsuario._();

  bool _estaLogado = false;
  String? _nomeUsuario;
  String? _emailUsuario;

  bool get estaLogado => _estaLogado;
  String? get nomeUsuario => _nomeUsuario;
  String? get emailUsuario => _emailUsuario;

  void entrar({
    required String nome,
    required String email,
  }) {
    _estaLogado = true;
    _nomeUsuario = nome;
    _emailUsuario = email;

    notifyListeners();
  }

  void sair() {
    _estaLogado = false;
    _nomeUsuario = null;
    _emailUsuario = null;

    notifyListeners();
  }
}