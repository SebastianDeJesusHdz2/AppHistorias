import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/character.dart';

class CharacterTile extends StatelessWidget {
  final Character character;
  final VoidCallback? onTap;

  const CharacterTile({
    super.key,
    required this.character,
    this.onTap,
  });

  Widget _placeholder() =>
      const Icon(Icons.person, size: 38);

  Widget _buildImage(String? img) {
    if (img == null || img.isEmpty) return _placeholder();

    final looksBase64 =
        img.length > 100 && !img.startsWith('http') && !img.contains(Platform.pathSeparator);

    if (looksBase64) {
      try {
        final bytes = base64Decode(img);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (ctx, e, s) => _placeholder(),
          ),
        );
      } catch (_) {
        return _placeholder();
      }
    }

    if (img.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          img,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, s) => _placeholder(),
        ),
      );
    }

    final file = File(img);
    if (!file.existsSync()) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, s) => _placeholder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildImage(character.imagePath),
      title: Text(character.name),
      subtitle: Text(character.description?.isNotEmpty == true
          ? character.description!
          : 'Sin descripción'),
      onTap: onTap,
    );
  }
}

