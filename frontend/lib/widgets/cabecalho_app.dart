
import 'package:flutter/material.dart';

import 'package:pet_care/widgets/cabecalho_petcare.dart';

class CabecalhoApp extends StatelessWidget {
  const CabecalhoApp({
    super.key,
    required this.greeting,
    required this.name,
    this.avatarUrl,
    this.onNotificationTap,
  });

  final String greeting;
  final String name;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return CabecalhoPetCare(
      nome: name,
      saudacao: greeting,
      onNotificationTap: onNotificationTap,
    );
  }
}
