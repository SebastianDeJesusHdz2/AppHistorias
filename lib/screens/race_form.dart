import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/race.dart';
import '../widgets/image_selector.dart';

class RaceForm extends StatefulWidget {
  const RaceForm({super.key});

  @override
  _RaceFormState createState() => _RaceFormState();
}

class _RaceFormState extends State<RaceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _imagePath; // puede ser path local o base64

  final List<_FieldRow> _fieldRows = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final fr in _fieldRows) {
      fr.labelCtrl.dispose();
      fr.keyCtrl.dispose();
    }
    super.dispose();
  }

  void _updateImage(String pathOrBase64) {
    setState(() {
      _imagePath = pathOrBase64;
    });
  }

  void _addFieldRow() {
    setState(() {
      _fieldRows.add(
        _FieldRow(
          labelCtrl: TextEditingController(),
          keyCtrl: TextEditingController(),
          type: RaceFieldType.text,
        ),
      );
    });
  }

  void _removeFieldRow(int index) {
    setState(() {
      final fr = _fieldRows.removeAt(index);
      fr.labelCtrl.dispose();
      fr.keyCtrl.dispose();
    });
  }

  Widget _buildRaceImage() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        color: Colors.black12,
        child: const Icon(Icons.image, size: 32),
      );
    }
    // Detecta base64/url/file como en StoryDetailScreen
    final isBase64 = _imagePath!.length > 100 &&
        !_imagePath!.startsWith('http') &&
        !_imagePath!.contains(Platform.pathSeparator);

    if (isBase64) {
      return Image.memory(
        base64Decode(_imagePath!),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => Icon(Icons.broken_image, color: Colors.red),
      );
    } else if (_imagePath!.startsWith('http')) {
      return Image.network(
        _imagePath!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => Icon(Icons.broken_image, color: Colors.red),
      );
    } else {
      return Image.file(
        File(_imagePath!),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => Icon(Icons.broken_image, color: Colors.red),
      );
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la raza es obligatorio.')),
      );
      return;
    }

    final defs = <RaceFieldDef>[];
    for (final fr in _fieldRows) {
      final key = fr.keyCtrl.text.trim();
      final label = fr.labelCtrl.text.trim();
      if (key.isEmpty || label.isEmpty) continue;
      defs.add(RaceFieldDef(key: key, label: label, type: fr.type));
    }

    final race = Race(
      id: const Uuid().v4(),
      name: name,
      description: desc,
      imagePath: _imagePath,
      fields: defs,
    );

    Navigator.pop(context, race);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Raza')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Imagen y selector IA/subida
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildRaceImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ImageSelector(onImageSelected: _updateImage),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la raza',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('Características de la raza',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addFieldRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fieldRows.isEmpty)
              const Text('Aún no has agregado características.'),
            ..._fieldRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final fr = entry.value;
              return _FieldEditorRow(
                index: idx,
                fieldRow: fr,
                onRemove: () => _removeFieldRow(idx),
                onTypeChanged: (t) => setState(() => fr.type = t),
              );
            }),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow {
  final TextEditingController labelCtrl;
  final TextEditingController keyCtrl;
  RaceFieldType type;

  _FieldRow({
    required this.labelCtrl,
    required this.keyCtrl,
    required this.type,
  });
}

class _FieldEditorRow extends StatelessWidget {
  final int index;
  final _FieldRow fieldRow;
  final VoidCallback onRemove;
  final ValueChanged<RaceFieldType> onTypeChanged;

  const _FieldEditorRow({
    required this.index,
    required this.fieldRow,
    required this.onRemove,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fieldRow.labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta visible (ej: Tamaño de orejas)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: fieldRow.keyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Clave interna (ej: tamano_orejas)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Tipo:'),
                const SizedBox(width: 12),
                DropdownButton<RaceFieldType>(
                  value: fieldRow.type,
                  onChanged: (v) {
                    if (v != null) onTypeChanged(v);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: RaceFieldType.text,
                      child: Text('Texto'),
                    ),
                    DropdownMenuItem(
                      value: RaceFieldType.number,
                      child: Text('Número'),
                    ),
                    DropdownMenuItem(
                      value: RaceFieldType.boolean,
                      child: Text('Sí/No'),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_forever),
                  color: Colors.red,
                  tooltip: 'Eliminar característica',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

