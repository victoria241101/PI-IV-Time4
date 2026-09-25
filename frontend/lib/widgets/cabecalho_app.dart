import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Cabeçalho reutilizável com avatar, saudação e ícone de notificações.
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: CoresApp.primary.withAlpha(40),
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TipografiaApp.heading3.copyWith(
                      color: CoresApp.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: TipografiaApp.bodySmall),
                Text(
                  name,
                  style: TipografiaApp.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Notificações',
            button: true,
            child: IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_outlined),
              color: CoresApp.textPrimary,
              iconSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}
