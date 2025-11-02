import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apphistorias/models/race.dart';

class RaceTile extends StatelessWidget {
  final Race race;
  final VoidCallback? onTap;

  const RaceTile({required this.race, this.onTap, super.key});

  Widget _buildRaceImage() {
    final img = race.imagePath;
    if (img == null || img.isEmpty) {
      return const Icon(Icons.group_work, size: 36);
    }
    final isBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    if (isBase64) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(img),
          width: 39,
          height: 39,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, s) => const Icon(Icons.group_work, size: 36),
        ),
      );
    } else if (img.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          img,
          width: 39,
          height: 39,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, s) => const Icon(Icons.group_work, size: 36),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(img),
          width: 39,
          height: 39,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, s) => const Icon(Icons.group_work, size: 36),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsSummary = race.fields.isEmpty
        ? 'Sin características'
        : race.fields.map((f) => f.label).take(3).join(' • ');

    return ListTile(
      leading: _buildRaceImage(),
      title: Text(race.name),
      subtitle: Text('${race.description}\n$fieldsSummary'),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}



