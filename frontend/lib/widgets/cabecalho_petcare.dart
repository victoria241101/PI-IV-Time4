
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class CabecalhoPetCare extends StatelessWidget {
  const CabecalhoPetCare({
    super.key,
    this.nome,
    this.saudacao = 'Olá',
    this.onNotificationTap,
    this.onLoginTap,
  });

  final String? nome;
  final String saudacao;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLoginTap;

  String get _textoSaudacao {
    final nomeCompleto = nome?.trim() ?? '';
    final primeiroNome = nomeCompleto.isEmpty
        ? ''
        : nomeCompleto.split(RegExp(r'\s+')).first;

    final saudacaoLimpa = saudacao
        .trim()
        .replaceAll(RegExp(r'[!,.:\s]+$'), '');

    if (primeiroNome.isEmpty) {
      return '$saudacaoLimpa!';
    }

    return '$saudacaoLimpa, $primeiroNome!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 32,
                      color: CoresApp.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PetCare',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _textoSaudacao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
            if (onNotificationTap != null)
              Positioned(
                right: 0,
                child: Semantics(
                  label: 'Notificações',
                  button: true,
                  child: IconButton(
                    onPressed: onNotificationTap,
                    tooltip: 'Notificações',
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                    ),
                    color: CoresApp.darkBlue,
                    iconSize: 25,
                  ),
                ),
              ),
            if (onLoginTap != null)
              Positioned(
                right: 0,
                child: TextButton(
                  onPressed: onLoginTap,
                  style: TextButton.styleFrom(
                    foregroundColor: CoresApp.darkBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
