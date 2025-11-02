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
        final nameCtrl = TextEditingController(text: race.name);
        final descCtrl = TextEditingController(text: race.description);
        String? tempImage = race.imagePath;
        final fields = List<RaceFieldDef>.from(race.fields);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              void addField() =>
                  setModal(() => fields.add(RaceFieldDef(key: '', label: '', type: RaceFieldType.text)));
              void removeField(int i) => setModal(() => fields.removeAt(i));

              return SingleChildScrollView(
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
                      decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration:
                      const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Características', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(onPressed: addField, icon: const Icon(Icons.add), label: const Text('Agregar')),
                      ],
                    ),
                    ...fields.asMap().entries.map((e) {
                      final i = e.key;
                      final f = e.value;
                      final keyCtrl = TextEditingController(text: f.key);
                      final labelCtrl = TextEditingController(text: f.label);
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
                                      controller: labelCtrl,
                                      decoration: const InputDecoration(
                                          labelText: 'Etiqueta', border: OutlineInputBorder()),
                                      onChanged: (v) => f.label = v,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: keyCtrl,
                                      decoration:
                                      const InputDecoration(labelText: 'Clave', border: OutlineInputBorder()),
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
                    }),
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
                          setState(() {
                            race.name = nameCtrl.text.trim();
                            race.description = descCtrl.text.trim();
                            race.imagePath = persisted;
                            race.fields = fields
                                .where((f) => f.key.trim().isNotEmpty && f.label.trim().isNotEmpty)
                                .toList();
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
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
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
          const Text('Razas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          TextButton.icon(onPressed: _crearRaza, icon: const Icon(Icons.add), label: const Text('Nueva Raza')),
        ],
      ),
      const SizedBox(height: 6),
      if (widget.story.races.isEmpty) const Text('Aún no hay razas. Agrega la primera.'),
      ...widget.story.races.map((race) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: GestureDetector(
              onTap: () => _showImagePreview(race.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAnyImage(race.imagePath, w: 48, h: 48),
              ),
            ),
            title: Text(race.name, overflow: TextOverflow.ellipsis),
            subtitle: Text(race.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(tooltip: 'Editar', onPressed: () => _editarRaza(race), icon: const Icon(Icons.edit)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      Text(widget.story.description, style: TextStyle(fontSize: 17, color: Colors.grey[700])),
      const SizedBox(height: 12),

      // Botones de escritura y PDF
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
          ),
        ],
      ),

      const SizedBox(height: 20),
      const Text('Personajes por raza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      const SizedBox(height: 8),
      if (widget.story.races.isEmpty) const Text('No hay razas; agrega una para comenzar con personajes.'),
      ...widget.story.races.map((race) {
        final count = race.characters.length;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading:
            ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildAnyImage(race.imagePath, w: 36, h: 36)),
            title: Text(race.name, overflow: TextOverflow.ellipsis),
            subtitle: Text('$count personaje${count == 1 ? '' : 's'}'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(onPressed: () => _crearPersonaje(race), icon: const Icon(Icons.add), label: const Text('Agregar')),
                IconButton(
                    tooltip: 'Eliminar raza',
                    onPressed: () => _eliminarRaza(race),
                    icon: const Icon(Icons.delete_forever, color: Colors.red)),
              ],
            ),
            children: [
              if (race.characters.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Sin personajes en esta raza.')),
              ...race.characters.map((ch) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    leading: GestureDetector(
                      onTap: () => _showImagePreview(ch.imagePath),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildAnyImage(ch.imagePath, w: 44, h: 44),
                      ),
                    ),
                    title: Text(ch.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      (ch.description ?? '').isEmpty
                          ? 'Sin descripción'
                          : (ch.description!.length > 80 ? '${ch.description!.substring(0, 80)}...' : ch.description!),
                    ),
                    onTap: () => _editarPersonaje(race, ch),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(tooltip: 'Editar', onPressed: () => _editarPersonaje(race, ch), icon: const Icon(Icons.edit)),
                        IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => _eliminarPersonaje(race, ch),
                            icon: const Icon(Icons.delete_forever, color: Colors.red)),
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
          appBar: AppBar(title: const Text('Detalles de la Historia')),
          body: Padding(
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
        );
      },
    );
  }
}

