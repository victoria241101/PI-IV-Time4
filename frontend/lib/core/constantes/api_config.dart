import 'package:flutter/foundation.dart';

/// Configuração central da URL base da API do PetCare.
///
/// Orientações para execução:
/// - Emulador Android: não precisa de nada, o padrão 10.0.2.2 já funciona.
/// - Celular físico: passar --dart-define=API_URL=http://<IP do computador na rede>:3000
/// - Nunca gravar o IP real no código.
class ApiConfig {
  ApiConfig._();

  static const String _urlDefinida = String.fromEnvironment('API_URL');

  /// Retorna a URL base do backend de acordo com a plataforma ou variável de ambiente.
  static String get baseUrl {
    if (_urlDefinida.isNotEmpty) {
      // Remove barra no final caso tenha sido informada
      return _urlDefinida.endsWith('/')
          ? _urlDefinida.substring(0, _urlDefinida.length - 1)
          : _urlDefinida;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}

