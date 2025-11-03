// lib/screens/race_form.dart
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

  String _slugify(String s) {
    var out = s.toLowerCase();
    const repl = {
      'á': 'a','à':'a','ä':'a','â':'a',
      'é': 'e','è':'e','ë':'e','ê':'e',
      'í': 'i','ì':'i','ï':'i','î':'i',
      'ó': 'o','ò':'o','ö':'o','ô':'o',
      'ú': 'u','ù':'u','ü':'u','û':'u',
      'ñ': 'n'
    };
    out = out.split('').map((c) => repl[c] ?? c).join();
    out = out.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    out = out.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return out;
  } // [web:72][web:73]

  Widget _buildRaceImage() {
    final palette = _PaperPalette.of(context);
    final placeholder = Container(
      width: 72,
      height: 72,
      color: palette.paper,
      child: Icon(Icons.image, size: 32, color: palette.inkMuted),
    );

    if (_imagePath == null || _imagePath!.isEmpty) {
      return placeholder;
    }
    final isBase64 = _imagePath!.length > 100 &&
        !_imagePath!.startsWith('http') &&
        !_imagePath!.contains(Platform.pathSeparator);

    if (isBase64) {
      return Image.memory(
        base64Decode(_imagePath!),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => const Icon(Icons.broken_image, color: Colors.red),
      );
    } else if (_imagePath!.startsWith('http')) {
      return Image.network(
        _imagePath!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => const Icon(Icons.broken_image, color: Colors.red),
      );
    } else {
      return Image.file(
        File(_imagePath!),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) => const Icon(Icons.broken_image, color: Colors.red),
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
    final seen = <String>{};

    for (final fr in _fieldRows) {
      final rawLabel = fr.labelCtrl.text.trim();
      if (rawLabel.isEmpty) continue;
      var key = fr.keyCtrl.text.trim();
      key = key.isEmpty ? _slugify(rawLabel) : _slugify(key);
      if (key.isEmpty) continue;
      var base = key;
      var i = 1;
      while (seen.contains(key)) {
        key = '${base}_${i++}';
      }
      seen.add(key);
      defs.add(RaceFieldDef(key: key, label: rawLabel, type: fr.type));
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
    final palette = _PaperPalette.of(context);

    InputDecoration deco(String label, {String? helper}) => InputDecoration(
      labelText: label,
      helperText: helper,
      labelStyle: TextStyle(color: palette.inkMuted),
      helperStyle: TextStyle(color: palette.inkMuted),
      prefixIconColor: palette.inkMuted,
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
          // Viñeta radial
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
              _PaperTopBar(title: 'Nueva Raza', palette: palette),
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
                              child: _buildRaceImage(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: ImageSelector(onImageSelected: _updateImage)),
                          ],
                        ),
                      ),
                      _PaperCard(
                        palette: palette,
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              style: TextStyle(color: palette.ink),
                              decoration: deco('Nombre de la raza'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descCtrl,
                              maxLines: 3,
                              style: TextStyle(color: palette.ink),
                              decoration: deco('Descripción'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('Características de la raza',
                                style: TextStyle(fontWeight: FontWeight.bold, color: palette.ink)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _addFieldRow,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ),
                      if (_fieldRows.isEmpty)
                        Text('Aún no has agregado características.', style: TextStyle(color: palette.inkMuted)),
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
                      const SizedBox(height: 8),
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
    final palette = _PaperPalette.of(context);

    InputDecoration deco(String label) => InputDecoration(
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

    return _PaperCard(
      palette: palette,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fieldRow.labelCtrl,
                  style: TextStyle(color: palette.ink),
                  decoration: deco('Etiqueta visible (ej: Tamaño de orejas)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: fieldRow.keyCtrl,
                  style: TextStyle(color: palette.ink),
                  decoration: deco('Clave interna (ej: tamano_orejas)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Tipo:', style: TextStyle(color: palette.ink)),
              const SizedBox(width: 12),
              DropdownButton<RaceFieldType>(
                value: fieldRow.type,
                dropdownColor: palette.paper,
                onChanged: (v) {
                  if (v != null) onTypeChanged(v);
                },
                items: const [
                  DropdownMenuItem(value: RaceFieldType.text, child: Text('Texto')),
                  DropdownMenuItem(value: RaceFieldType.number, child: Text('Número')),
                  DropdownMenuItem(value: RaceFieldType.boolean, child: Text('Sí/No')),
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
    );
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
      padding: padding,
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

  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);
  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];
  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
