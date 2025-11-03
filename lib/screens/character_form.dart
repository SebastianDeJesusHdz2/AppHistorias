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
    final palette = _PaperPalette.of(context);
    if (_selectedRace == null) return Text('No hay razas disponibles.', style: TextStyle(color: palette.inkMuted));
    if (_selectedRace!.fields.isEmpty) {
      return Text('Esta raza no define características adicionales.', style: TextStyle(color: palette.inkMuted));
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
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, f.label),
              ),
            );
          case RaceFieldType.number:
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _numberCtrls[f.key],
                keyboardType: TextInputType.number,
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, f.label),
              ),
            );
          case RaceFieldType.boolean:
            return SwitchListTile.adaptive(
              title: Text(f.label, style: TextStyle(color: palette.ink)),
              value: _boolValues[f.key] ?? false,
              onChanged: (v) => setState(() => _boolValues[f.key] = v),
              activeColor: palette.ribbon,
              secondary: Icon(
                (_boolValues[f.key] ?? false) ? Icons.check_circle : Icons.radio_button_unchecked,
                color: palette.inkMuted,
              ),
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
    final palette = _PaperPalette.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo pergamino
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.backgroundGradient,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Viñeta radial suave
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.6),
                    radius: 1.2,
                    colors: [Colors.black.withOpacity(0.06), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              _PaperTopBar(title: 'Nuevo Personaje', palette: palette),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _PaperCard(
                        palette: palette,
                        child: Row(
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
                      ),
                      _PaperCard(
                        palette: palette,
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: palette.ink),
                              decoration: _deco(context, 'Nombre'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: physicalTraitsController,
                              style: TextStyle(color: palette.ink),
                              decoration: _deco(context, 'Características físicas'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descriptionController,
                              maxLines: 3,
                              style: TextStyle(color: palette.ink),
                              decoration: _deco(context, 'Descripción'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: personalityController,
                              style: TextStyle(color: palette.ink),
                              decoration: _deco(context, 'Personalidad'),
                            ),
                          ],
                        ),
                      ),
                      _PaperCard(
                        palette: palette,
                        child: DropdownButtonFormField<Race>(
                          value: _selectedRace != null && widget.races.contains(_selectedRace!)
                              ? _selectedRace
                              : (widget.races.isNotEmpty ? widget.races.first : null),
                          items: widget.races.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                          onChanged: _onRaceChanged,
                          decoration: _deco(context, 'Raza'),
                          dropdownColor: palette.paper,
                        ),
                      ),

                      _PaperCard(
                        palette: palette,
                        child: _buildRaceFields(),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.ribbon,
                            foregroundColor: palette.onRibbon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: palette.edge),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(BuildContext context, String label) {
    final palette = _PaperPalette.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.inkMuted),
      filled: true,
      fillColor: palette.paper.withOpacity(0.7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.ribbon, width: 2),
      ),
    );
  }

  Widget _previewImage(String? img) {
    final palette = _PaperPalette.of(context);
    if (img == null || img.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        color: palette.paper,
        child: Icon(Icons.image, size: 32, color: palette.inkMuted),
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
          color: palette.paper,
          child: Icon(Icons.broken_image, size: 32, color: palette.inkMuted),
        );
      }
    } else if (img.startsWith('http')) {
      return Image.network(
        img,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: palette.paper,
          child: Icon(Icons.broken_image, size: 32, color: palette.inkMuted),
        ),
      );
    } else {
      final file = File(img);
      if (!file.existsSync()) {
        return Container(
          width: 72,
          height: 72,
          color: palette.paper,
          child: Icon(Icons.broken_image, size: 32, color: palette.inkMuted),
        );
      }
      return Image.file(file, width: 72, height: 72, fit: BoxFit.cover);
    }
  }
}

// ---------- Widgets y paleta “papel” ----------
class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  const _PaperTopBar({required this.title, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.appBarGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: palette.edge, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Widget child;
  final _PaperPalette palette;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  const _PaperCard({
    required this.child,
    required this.palette,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);
  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Colores principales
  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  // Cinta / primario
  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  // Gradientes
  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];

  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
