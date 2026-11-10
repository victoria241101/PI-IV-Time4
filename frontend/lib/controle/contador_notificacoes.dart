import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/notificacoes_service.dart';

/// Controlador singleton responsável pelo polling e estado da contagem de notificações não lidas.
class ContadorNotificacoes extends ChangeNotifier with WidgetsBindingObserver {
  ContadorNotificacoes._({NotificacoesService? servico})
      : _servico = servico ?? NotificacoesService();

  /// Instância singleton global do contador de notificações.
  static final ContadorNotificacoes instancia = ContadorNotificacoes._();

  /// Construtor de fábrica para permitir injeção de dependência em testes.
  @visibleForTesting
  factory ContadorNotificacoes.comServico(NotificacoesService servico) {
    return ContadorNotificacoes._(servico: servico);
  }

  final NotificacoesService _servico;

  int _naoLidas = 0;
  int _contadorUsos = 0;
  Timer? _timer;
  bool _consultando = false;
  bool _bloqueado401 = false;

  /// Quantidade atual de notificações não lidas.
  int get naoLidas => _naoLidas;

  /// Indica se o polling periódico está ativo.
  bool get ativo => _timer != null;

  /// Registra o uso do contador por um widget/tela e inicia o polling periódico.
  void iniciar() {
    _contadorUsos++;
    _bloqueado401 = false;

    if (_contadorUsos == 1) {
      WidgetsBinding.instance.addObserver(this);
      _iniciarTimer();
      atualizar();
    } else if (_timer == null) {
      _iniciarTimer();
      atualizar();
    }
  }

  /// Cancela o registro de uso e interrompe o polling se não houver mais widgets consumidores.
  void parar() {
    if (_contadorUsos > 0) {
      _contadorUsos--;
    }

    if (_contadorUsos == 0) {
      _pararTimer();
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  /// Consulta a contagem de notificações não lidas no backend.
  Future<void> atualizar() async {
    if (_bloqueado401 || _consultando) {
      return;
    }

    if (!SessaoUsuario.instancia.estaLogado) {
      if (_naoLidas != 0) {
        _naoLidas = 0;
        notifyListeners();
      }
      return;
    }

    _consultando = true;

    try {
      final total = await _servico.contagem();
      if (_naoLidas != total) {
        _naoLidas = total;
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _pararTimer();
        _bloqueado401 = true;
        if (_naoLidas != 0) {
          _naoLidas = 0;
          notifyListeners();
        }
      }
      // Outros erros de API (4xx, 5xx): mantém o último valor conhecido
    } catch (_) {
      // Erros de rede, timeout, socket: mantém o último valor conhecido
    } finally {
      _consultando = false;
    }
  }

  /// Ajusta manualmente o número de não lidas (ex: decremento após marcar como lida).
  void definirNaoLidas(int n) {
    final normalizado = n < 0 ? 0 : n;
    if (_naoLidas != normalizado) {
      _naoLidas = normalizado;
      notifyListeners();
    }
  }

  /// Zera o contador de notificações e notifica os ouvintes.
  void limpar() {
    if (_naoLidas != 0) {
      _naoLidas = 0;
      notifyListeners();
    }
  }

  void _iniciarTimer() {
    _pararTimer();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => atualizar(),
    );
  }

  void _pararTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_contadorUsos <= 0) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _bloqueado401 = false;
        atualizar();
        _iniciarTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pararTimer();
        break;
    }
  }

  @override
  void dispose() {
    _pararTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

