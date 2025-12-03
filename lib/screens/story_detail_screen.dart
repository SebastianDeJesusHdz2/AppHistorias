// lib/screens/story_detail_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/models/race.dart';
import 'package:apphistorias/models/character.dart';

import 'package:apphistorias/screens/race_form.dart';
import 'package:apphistorias/screens/character_form.dart';
import 'package:apphistorias/screens/chapter_editor_screen.dart';
import 'package:apphistorias/screens/pdf_preview_screen.dart';

import 'package:apphistorias/widgets/image_selector.dart';

import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/main.dart'; // StoryProvider

class StoryDetailScreen extends StatefulWidget {
  final Story story;
  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  // ========= Utilidades de imagen =========
  String _cacheBuster() => '?t=${DateTime.now().millisecondsSinceEpoch}';

  Future<String?> _persistAnyImage(String? img) async {
    if (img == null || img.isEmpty) return null;
    final looksBase64 =
        img.length > 100 && !img.startsWith('http') && !img.contains(Platform.pathSeparator);
    try {
      if (looksBase64) {
        return await LocalStorageService.saveBase64ToImage(img);
      } else if (img.startsWith('http')) {
        return await LocalStorageService.downloadImageToAppDir(Uri.parse(img));
      } else {
        return await LocalStorageService.copyImageToAppDir(img);
      }
    } catch (_) {
      return null;
    }
  }

  Widget _broken(double w, double h) => Container(
    width: w,
    height: h,
    color: Colors.black12,
    child: Icon(Icons.broken_image, size: h * 0.45, color: Colors.redAccent),
  );

  Widget _buildAnyImage(String? img,
      {double w = 120, double h = 120, BoxFit fit = BoxFit.cover}) {
    if (img == null || img.isEmpty) {
      return Container(
        width: w,
        height: h,
        color: Colors.black12,
        child: Icon(Icons.image, size: h * 0.45, color: Colors.grey.shade400),
      );
    }

    final looksBase64 =
        img.length > 100 && !img.startsWith('http') && !img.contains(Platform.pathSeparator);

    if (looksBase64) {
      try {
        final bytes = base64Decode(img);
        return Image.memory(
          bytes,
          width: w,
          height: h,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _broken(w, h),
        );
      } catch (_) {
        return _broken(w, h);
      }
    }

    if (img.startsWith('http')) {
      final url = img.contains('?t=') ? img : img + _cacheBuster();
      return Image.network(
        url,
        width: w,
        height: h,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _broken(w, h),
      );
    }

    final f = File(img);
    if (!f.existsSync()) return _broken(w, h);

    return Image(
      image: FileImage(f),
      width: w,
      height: h,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _broken(w, h),
    );
  }

  void _showImagePreview(String? img) {
    if (img == null || img.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final looksBase64 =
            img.length > 100 && !img.startsWith('http') && !img.contains(Platform.pathSeparator);

        Widget large;
        if (looksBase64) {
          try {
            large = Image.memory(base64Decode(img), fit: BoxFit.contain, gaplessPlayback: true);
          } catch (_) {
            large = _broken(double.infinity, 220);
          }
        } else if (img.startsWith('http')) {
          final url = img.contains('?t=') ? img : img + _cacheBuster();
          large = Image.network(url, fit: BoxFit.contain, gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _broken(double.infinity, 220));
        } else {
          final f = File(img);
          large = f.existsSync()
              ? Image.file(f, fit: BoxFit.contain, gaplessPlayback: true)
              : _broken(double.infinity, 220);
        }

        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.6),
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(child: InteractiveViewer(minScale: 0.8, maxScale: 4.0, child: large)),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========= Helpers de datos =========
  Race? _raceById(String? id) {
    try {
      return widget.story.races.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistAll() async {
    await Provider.of<StoryProvider>(context, listen: false).saveAll();
  }

  Future<void> _actualizaImagen(String img) async {
    final path = await _persistAnyImage(img);
    setState(() => widget.story.imagePath = path);
    await _persistAll();
  }

  // --- Helpers de normalización de claves ---
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
  }

  List<RaceFieldDef> _normalizeAndUniq(List<RaceFieldDef> src) {
    final seen = <String>{};
    final result = <RaceFieldDef>[];
    for (final f in src) {
      final label = f.label.trim();
      if (label.isEmpty) continue;
      var key = f.key.trim().isEmpty ? _slugify(label) : _slugify(f.key.trim());
      if (key.isEmpty) continue;
      final base = key;
      var i = 1;
      while (seen.contains(key)) {
        key = '${base}_${i++}';
      }
      seen.add(key);
      result.add(RaceFieldDef(key: key, label: label, type: f.type));
    }
    return result;
  }

  // ========= Crear / editar entidades =========
  Future<void> _crearRaza() async {
    final newRace =
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RaceForm()));
    if (newRace is Race) {
      newRace.imagePath = await _persistAnyImage(newRace.imagePath);
      setState(() => widget.story.races.add(newRace));
      await _persistAll();
    }
  }

  Future<void> _editarRaza(Race race) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (ctx) {
        // Controladores ESTABLES (no se recrean en cada build)
        final nameCtrl = TextEditingController(text: race.name);
        final descCtrl = TextEditingController(text: race.description);
        String? tempImage = race.imagePath;
        // Copia mutable local de fields
        final fields = List<RaceFieldDef>.from(race.fields);
        // Mapa de controladores por índice
        final labelCtrls = <int, TextEditingController>{};
        final keyCtrls = <int, TextEditingController>{};
        for (var i = 0; i < fields.length; i++) {
          labelCtrls[i] = TextEditingController(text: fields[i].label);
          keyCtrls[i] = TextEditingController(text: fields[i].key);
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              void addField() {
                setModal(() {
                  fields.add(RaceFieldDef(key: '', label: '', type: RaceFieldType.text));
                  final i = fields.length - 1;
                  labelCtrls[i] = TextEditingController();
                  keyCtrls[i] = TextEditingController();
                });
              }

              void removeField(int i) {
                setModal(() {
                  fields.removeAt(i);
                  labelCtrls.remove(i);
                  keyCtrls.remove(i);
                  // Reindexar controladores para mantener consistencia
                  final newLabel = <int, TextEditingController>{};
                  final newKey = <int, TextEditingController>{};
                  for (var j = 0; j < fields.length; j++) {
                    newLabel[j] = labelCtrls[j] ?? TextEditingController(text: fields[j].label);
                    newKey[j] = keyCtrls[j] ?? TextEditingController(text: fields[j].key);
                  }
                  labelCtrls
                    ..clear()
                    ..addAll(newLabel);
                  keyCtrls
                    ..clear()
                    ..addAll(newKey);
                });
              }

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Editar Raza', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePreview(tempImage),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildAnyImage(tempImage, w: 72, h: 72),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ImageSelector(
                            onImageSelected: (img) => setModal(() => tempImage = img),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Características', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(onPressed: addField, icon: const Icon(Icons.add), label: const Text('Agregar')),
                      ],
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: fields.length,
                      itemBuilder: (_, i) {
                        final f = fields[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: labelCtrls[i],
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                            labelText: 'Etiqueta', border: OutlineInputBorder()),
                                        onChanged: (v) => f.label = v,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: keyCtrls[i],
                                        decoration: const InputDecoration(
                                            labelText: 'Clave (opcional)', border: OutlineInputBorder()),
                                        onChanged: (v) => f.key = v,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Tipo:'),
                                    const SizedBox(width: 10),
                                    DropdownButton<RaceFieldType>(
                                      value: f.type,
                                      onChanged: (v) => v != null ? setModal(() => f.type = v) : null,
                                      items: const [
                                        DropdownMenuItem(value: RaceFieldType.text, child: Text('Texto')),
                                        DropdownMenuItem(value: RaceFieldType.number, child: Text('Número')),
                                        DropdownMenuItem(value: RaceFieldType.boolean, child: Text('Sí/No')),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                        onPressed: () => removeField(i),
                                        icon: const Icon(Icons.delete_forever, color: Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
                            return;
                          }
                          final persisted = await _persistAnyImage(tempImage);
                          final cleaned = _normalizeAndUniq(fields);
                          setState(() {
                            race.name = nameCtrl.text.trim();
                            race.description = descCtrl.text.trim();
                            race.imagePath = persisted;
                            race.fields = cleaned;
                          });
                          await _persistAll();
                          if (context.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _eliminarRaza(Race race) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar raza'),
        content: Text(race.characters.isEmpty
            ? '¿Seguro que quieres eliminar la raza "${race.name}"?'
            : 'La raza "${race.name}" tiene ${race.characters.length} personaje(s). Se eliminarán también.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => widget.story.races.removeWhere((r) => r.id == race.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Raza "${race.name}" eliminada')));
    }
  }

  Future<void> _crearPersonaje(Race race) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CharacterForm(races: widget.story.races, initialRace: race)),
    );
    if (result is Character) {
      result.imagePath = await _persistAnyImage(result.imagePath);
      setState(() => race.characters.add(result));
      await _persistAll();
    }
  }

  Future<void> _editarPersonaje(Race currentRace, Character ch) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: ch.name);
        final descCtrl = TextEditingController(text: ch.description ?? '');
        String? tempImage = ch.imagePath;
        Race selectedRace = _raceById(ch.raceId) ?? currentRace;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Editar Personaje', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showImagePreview(tempImage),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildAnyImage(tempImage, w: 72, h: 72),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: ImageSelector(onImageSelected: (img) => setModal(() => tempImage = img))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Raza', border: OutlineInputBorder()),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Race>(
                          value: selectedRace,
                          items: widget.story.races.map((r) => DropdownMenuItem<Race>(value: r, child: Text(r.name))).toList(),
                          onChanged: (r) => r != null ? setModal(() => selectedRace = r) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
                            return;
                          }
                          final persisted = await _persistAnyImage(tempImage);
                          setState(() {
                            ch.name = name;
                            ch.description = descCtrl.text.trim();
                            ch.imagePath = persisted;
                            if (ch.raceId != selectedRace.id) {
                              final oldRace = _raceById(ch.raceId) ?? currentRace;
                              oldRace.characters.removeWhere((c) => c.id == ch.id);
                              ch.raceId = selectedRace.id;
                              selectedRace.characters.add(ch);
                            }
                          });
                          await _persistAll();
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Personaje actualizado')));
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _eliminarPersonaje(Race race, Character ch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar personaje'),
        content: Text('¿Seguro que quieres eliminar a "${ch.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => race.characters.removeWhere((c) => c.id == ch.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Personaje "${ch.name}" eliminado')));
    }
  }

  // ========= UI =========
  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    final leftColumn = [
      GestureDetector(
        onTap: () => _showImagePreview(widget.story.imagePath),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildAnyImage(widget.story.imagePath, w: double.infinity, h: 180),
        ),
      ),
      const SizedBox(height: 12),
      ImageSelector(onImageSelected: _actualizaImagen),
      const SizedBox(height: 20),
      Row(
        children: [
          Text('Razas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: palette.ink)),
          const Spacer(),
          TextButton.icon(onPressed: _crearRaza, icon: const Icon(Icons.add), label: const Text('Nueva Raza')),
        ],
      ),
      const SizedBox(height: 6),
      if (widget.story.races.isEmpty)
        Text('Aún no hay razas. Agrega la primera.', style: TextStyle(color: palette.inkMuted)),
      ...widget.story.races.map((race) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: palette.paper,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.edge, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: GestureDetector(
              onTap: () => _showImagePreview(race.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAnyImage(race.imagePath, w: 48, h: 48),
              ),
            ),
            title: Text(race.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.ink)),
            subtitle: Text(race.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.inkMuted)),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(tooltip: 'Editar', onPressed: () => _editarRaza(race), icon: const Icon(Icons.edit), color: palette.ink),
                IconButton(
                    tooltip: 'Eliminar raza',
                    onPressed: () => _eliminarRaza(race),
                    icon: const Icon(Icons.delete_forever, color: Colors.red)),
              ],
            ),
          ),
        );
      }),
    ];

    final rightColumn = [
      Text(widget.story.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: palette.ink),
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      Text(widget.story.description, style: TextStyle(fontSize: 17, color: palette.inkMuted)),
      const SizedBox(height: 12),
      Row(
        children: [
          FilledButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChapterEditorScreen(story: widget.story)),
              );
              if (mounted) setState(() {}); // refresca capítulos al volver
              await _persistAll();
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('Escribir'),
            style: FilledButton.styleFrom(backgroundColor: palette.ribbon, foregroundColor: palette.onRibbon),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfPreviewScreen(story: widget.story)),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
            style: OutlinedButton.styleFrom(side: BorderSide(color: palette.edge), foregroundColor: palette.ink),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text('Personajes por raza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: palette.ink)),
      const SizedBox(height: 8),
      if (widget.story.races.isEmpty)
        Text('No hay razas; agrega una para comenzar con personajes.', style: TextStyle(color: palette.inkMuted)),
      ...widget.story.races.map((race) {
        final count = race.characters.length;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: palette.paper,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.edge, width: 1),
          ),
          child: ExpansionTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildAnyImage(race.imagePath, w: 36, h: 36)),
            title: Text(race.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.ink)),
            subtitle: Text('$count personaje${count == 1 ? '' : 's'}', style: TextStyle(color: palette.inkMuted)),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(onPressed: () => _crearPersonaje(race), icon: const Icon(Icons.add), label: const Text('Agregar')),
                IconButton(tooltip: 'Eliminar raza', onPressed: () => _eliminarRaza(race), icon: const Icon(Icons.delete_forever, color: Colors.red)),
              ],
            ),
            children: [
              if (race.characters.isEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Sin personajes en esta raza.', style: TextStyle(color: palette.inkMuted))),
              ...race.characters.map((ch) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: palette.paper,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: palette.edge, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    leading: GestureDetector(
                      onTap: () => _showImagePreview(ch.imagePath),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildAnyImage(ch.imagePath, w: 44, h: 44),
                      ),
                    ),
                    title: Text(ch.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.ink)),
                    subtitle: Text(
                      (ch.description ?? '').isEmpty
                          ? 'Sin descripción'
                          : (ch.description!.length > 80 ? '${ch.description!.substring(0, 80)}...' : ch.description!),
                      style: TextStyle(color: palette.inkMuted),
                    ),
                    onTap: () => _editarPersonaje(race, ch),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(tooltip: 'Editar', onPressed: () => _editarPersonaje(race, ch), icon: const Icon(Icons.edit), color: palette.ink),
                        IconButton(tooltip: 'Eliminar', onPressed: () => _eliminarPersonaje(race, ch), icon: const Icon(Icons.delete_forever, color: Colors.red)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Scaffold(
          // Para que el contenido se acomode al teclado
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Detalles de la Historia'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.appBarGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: isMobile
                    ? ListView(children: [...leftColumn, const SizedBox(height: 24), ...rightColumn])
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 12, child: ListView(children: leftColumn)),
                    const SizedBox(width: 24),
                    Expanded(flex: 18, child: ListView(children: rightColumn)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Paleta solo para estilo
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
