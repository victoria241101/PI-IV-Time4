import 'package:flutter/foundation.dart';

/// Imagem do Banner
class DadosBanner {
  const DadosBanner({required this.imagem, this.aoTocar});

  final String imagem;
  final VoidCallback? aoTocar;

  factory DadosBanner.deMapa(Map<String, Object?> dados) {
    return DadosBanner(imagem: dados['imagem']! as String);
  }
}
