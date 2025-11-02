import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apphistorias/services/account_service.dart';

/// Título del AppBar: avatar + nombre (o 'CronIA' cuando no hay sesión)
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccountService>();
    final hasPhoto = acc.photoBytes != null;

    final avatar = hasPhoto
        ? CircleAvatar(radius: 14, backgroundImage: MemoryImage(acc.photoBytes!))
        : const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16));

    final title = acc.displayName?.trim().isNotEmpty == true
        ? acc.displayName!.trim()
        : 'CronIA';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }
}

