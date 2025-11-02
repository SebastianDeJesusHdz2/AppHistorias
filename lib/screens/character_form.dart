// lib/screens/character_form.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/character.dart';
import '../models/race.dart';
import '../widgets/image_selector.dart';
import '../services/local_storage_service.dart'; // para copiar/guardar imagen en carpeta de la app

class CharacterForm extends StatefulWidget {
  final List<Race> races;      // Razas disponibles
  final Race? initialRace;     // Opcional: raza preseleccionada

  const CharacterForm({super.key, required this.races, this.initialRace});

  @override
  _CharacterFormState createState() => _CharacterFormState();
}

class _CharacterFormState extends State<CharacterForm> {
  final nameController = TextEditingController();
  final physicalTraitsController = TextEditingController();
  final descriptionController = TextEditingController();
  final personalityController = TextEditingController();

  Race? _selectedRace;
  String? _image; // base64, url, path (or null)

  // Para campos dinámicos
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, TextEditingController> _numberCtrls = {};
  final Map<String, bool> _boolValues = {};

  @override
  void initState() {
    super.initState();
    _selectedRace = widget.initialRace ?? (widget.races.isNotEmpty ? widget.races.first : null);
    _buildRaceDynamicState();
  }

  @override
  void dispose() {
    nameController.dispose();
    physicalTraitsController.dispose();
    descriptionController.dispose();
    personalityController.dispose();
    for (final c in _textCtrls.values) c.dispose();
    for (final c in _numberCtrls.values) c.dispose();
    super.dispose();
  }

  void _onImageSelected(String v) {
    // Recibe base64/url/ruta. Persistimos al guardar; aquí solo preview.
    setState(() => _image = v);
  }

  void _onRaceChanged(Race? r) {
    setState(() {
      _selectedRace = r;
      _buildRaceDynamicState();
    });
  }

  void _buildRaceDynamicState() {
    // Limpia controladores antiguos
    _textCtrls.clear();
    _numberCtrls.clear();
    _boolValues.clear();

    if (_selectedRace == null) return;

    for (final f in _selectedRace!.fields) {
      switch (f.type) {
        case RaceFieldType.text:
          _textCtrls[f.key] = TextEditingController();
          break;
        case RaceFieldType.number:
          _numberCtrls[f.key] = TextEditingController();
          break;
        case RaceFieldType.boolean:
          _boolValues[f.key] = false;
          break;
      }
    }
  }

  Widget _buildRaceFields() {
    if (_selectedRace == null) return const Text('No hay razas disponibles.');
    if (_selectedRace!.fields.isEmpty) {
      return const Text('Esta raza no define características adicionales.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _selectedRace!.fields.map((f) {
        switch (f.type) {
          case RaceFieldType.text:
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _textCtrls[f.key],
                decoration: InputDecoration(
                  labelText: f.label,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          case RaceFieldType.number:
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _numberCtrls[f.key],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: f.label,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          case RaceFieldType.boolean:
            return SwitchListTile(
              title: Text(f.label),
              value: _boolValues[f.key] ?? false,
              onChanged: (v) => setState(() => _boolValues[f.key] = v),
            );
        }
      }).toList(),
    );
  }

  Future<String?> _persistImageIfNeeded(String? img) async {
    if (img == null || img.isEmpty) return null;

    // Heurística de base64
    final isBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    try {
      if (isBase64) {
        // Guarda base64 como archivo en carpeta de la app
        return await LocalStorageService.saveBase64ToImage(img);
      } else if (img.startsWith('http')) {
        // Descarga a carpeta de la app
        return await LocalStorageService.downloadImageToAppDir(Uri.parse(img));
      } else {
        // Ruta local: copia a carpeta propia de la app para tener ruta estable
        return await LocalStorageService.copyImageToAppDir(img);
      }
    } catch (_) {
      // Si algo falla, no bloquees el guardado; solo retorna null para usar placeholder
      return null;
    }
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }
    if (_selectedRace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una raza.')),
      );
      return;
    }

    // Construye customFields combinando los tipos
    final Map<String, dynamic> customFields = {};
    _textCtrls.forEach((k, v) => customFields[k] = v.text.trim());
    _numberCtrls.forEach((k, v) {
      final raw = v.text.trim();
      if (raw.isEmpty) {
        customFields[k] = null;
      } else {
        final n = num.tryParse(raw);
        customFields[k] = n ?? raw;
      }
    });
    _boolValues.forEach((k, v) => customFields[k] = v);

    // Persiste imagen a carpeta de la app y guarda la ruta final estable
    final persistedPath = await _persistImageIfNeeded(_image);

    final character = Character(
      id: const Uuid().v4(),
      name: name,
      physicalTraits: physicalTraitsController.text.trim(),
      description: descriptionController.text.trim(),
      personality: personalityController.text.trim(),
      imagePath: persistedPath, // ya es ruta segura o null
      raceId: _selectedRace!.id,
      customFields: customFields,
    );

    if (!mounted) return;
    Navigator.pop(context, character);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Personaje')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _previewImage(_image),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ImageSelector(onImageSelected: _onImageSelected),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: physicalTraitsController,
              decoration: const InputDecoration(
                labelText: 'Características físicas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: personalityController,
              decoration: const InputDecoration(
                labelText: 'Personalidad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<Race>(
              value: _selectedRace != null && widget.races.contains(_selectedRace!)
                  ? _selectedRace
                  : (widget.races.isNotEmpty ? widget.races.first : null),
              items: widget.races
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: _onRaceChanged,
              decoration: const InputDecoration(
                labelText: 'Raza',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            _buildRaceFields(),

            const SizedBox(height: 18),
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

  Widget _previewImage(String? img) {
    if (img == null || img.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        color: Colors.black12,
        child: const Icon(Icons.image, size: 32),
      );
    }

    final isBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    if (isBase64) {
      try {
        final bytes = base64Decode(img);
        return Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover);
      } catch (_) {
        return Container(
          width: 72,
          height: 72,
          color: Colors.black12,
          child: const Icon(Icons.broken_image, size: 32),
        );
      }
    } else if (img.startsWith('http')) {
      return Image.network(img, width: 72, height: 72, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 72,
            height: 72,
            color: Colors.black12,
            child: const Icon(Icons.broken_image, size: 32),
          ));
    } else {
      final file = File(img);
      if (!file.existsSync()) {
        return Container(
          width: 72,
          height: 72,
          color: Colors.black12,
          child: const Icon(Icons.broken_image, size: 32),
        );
      }
      return Image.file(file, width: 72, height: 72, fit: BoxFit.cover);
    }
  }
}

