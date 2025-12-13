import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/models/race.dart';
import 'package:apphistorias/models/character.dart';
import 'package:apphistorias/models/location.dart';
import 'package:apphistorias/models/place.dart';

import 'package:apphistorias/screens/race_form.dart';
import 'package:apphistorias/screens/character_form.dart';
import 'package:apphistorias/screens/location_form.dart';
import 'package:apphistorias/screens/place_form.dart';

import 'package:apphistorias/screens/chapter_editor_screen.dart';
import 'package:apphistorias/screens/pdf_preview_screen.dart';
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/main.dart';

import 'story_detail_view.dart';

typedef AsyncVoidCallback = Future<void> Function();

class StoryDetailScreen extends StatefulWidget {
  final Story story;
  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  String _cacheBuster() => '?t=${DateTime.now().millisecondsSinceEpoch}';

  Future<String?> _persistAnyImage(String? img) async {
    if (img == null || img.isEmpty) return null;
    final looksBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);
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
    child: Icon(
      Icons.broken_image,
      size: h * 0.45,
      color: Colors.redAccent,
    ),
  );

  Widget _buildAnyImage(
      String? img, {
        double w = 120,
        double h = 120,
        BoxFit fit = BoxFit.cover,
      }) {
    if (img == null || img.isEmpty) {
      return Container(
        width: w,
        height: h,
        color: Colors.black12,
        child: Icon(
          Icons.image,
          size: h * 0.45,
          color: Colors.grey.shade400,
        ),
      );
    }

    final looksBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

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

    ImageProvider? provider;
    final looksBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    if (looksBase64) {
      try {
        provider = MemoryImage(base64Decode(img));
      } catch (_) {
        provider = null;
      }
    } else if (img.startsWith('http')) {
      final url = img.contains('?t=') ? img : img + _cacheBuster();
      provider = NetworkImage(url);
    } else {
      final f = File(img);
      if (f.existsSync()) provider = FileImage(f);
    }

    if (provider == null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (ctx) => Center(child: _broken(220, 220)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.9,
                ),
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(image: provider!, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Race? _raceById(String? id) {
    try {
      return widget.story.races.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Location? _locationById(String? id) {
    try {
      return widget.story.locations.firstWhere((l) => l.id == id);
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

  Future<void> _pickStoryImage() async {
    final picker = ImagePicker();
    final XFile? file =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    await _actualizaImagen(file.path);
  }

  // ===== Razas =====

  String _slugify(String s) {
    var out = s.toLowerCase();
    const repl = {
      'á': 'a','à': 'a','ä': 'a','â': 'a',
      'é': 'e','è': 'e','ë': 'e','ê': 'e',
      'í': 'i','ì': 'i','ï': 'i','î': 'i',
      'ó': 'o','ò': 'o','ö': 'o','ô': 'o',
      'ú': 'u','ù': 'u','ü': 'u','û': 'u',
      'ñ': 'n',
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
        key = '${base}_$i';
        i++;
      }
      seen.add(key);
      result.add(RaceFieldDef(key: key, label: label, type: f.type));
    }
    return result;
  }

  Future<void> _crearRaza() async {
    final newRace = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RaceForm()),
    );
    if (newRace is Race) {
      newRace.imagePath = await _persistAnyImage(newRace.imagePath);
      final cleaned = _normalizeAndUniq(newRace.fields);
      setState(() {
        newRace.fields = cleaned;
        widget.story.races.add(newRace);
      });
      await _persistAll();
    }
  }

  Future<void> _editarRaza(Race race) async {
    final edited = await Navigator.of(context).push<Race>(
      TransparentPageRoute(
        builder: (_) => RaceForm(initialRace: race),
      ),
    );

    if (edited is Race) {
      edited.imagePath = await _persistAnyImage(edited.imagePath);
      final cleaned = _normalizeAndUniq(edited.fields);

      setState(() {
        race.name = edited.name;
        race.description = edited.description;
        race.imagePath = edited.imagePath;
        race.fields = cleaned;

        final allowedKeys = cleaned.map((f) => f.key).toSet();

        for (final ch in race.characters) {
          ch.attributes = ch.attributes ?? <String, dynamic>{};

          final newAttrs = <String, dynamic>{};
          ch.attributes.forEach((k, v) {
            if (allowedKeys.contains(k)) newAttrs[k] = v;
          });

          for (final def in cleaned) {
            newAttrs.putIfAbsent(def.key, () => null);
          }

          ch.attributes = newAttrs;
        }
      });

      await _persistAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Raza actualizada')),
      );
    }
  }

  Future<void> _eliminarRaza(Race race) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar raza'),
        content: Text(
          race.characters.isEmpty
              ? '¿Seguro que quieres eliminar la raza "${race.name}"?'
              : 'La raza "${race.name}" tiene ${race.characters.length} personaje(s). Se eliminarán también.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => widget.story.races.removeWhere((r) => r.id == race.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Raza "${race.name}" eliminada')),
      );
    }
  }

  // ===== Personajes =====

  Future<void> _crearPersonaje(Race race) async {
    final result = await Navigator.push<Character>(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterForm(
          races: widget.story.races,
          initialRace: race,
        ),
      ),
    );

    if (result is Character) {
      result.imagePath = await _persistAnyImage(result.imagePath);
      setState(() {
        final targetRace = _raceById(result.raceId) ?? race;
        targetRace.characters.add(result);
      });
      await _persistAll();
    }
  }

  Future<void> _editarPersonaje(Race currentRace, Character ch) async {
    final edited = await Navigator.of(context).push<Character>(
      TransparentPageRoute(
        builder: (_) => CharacterForm(
          races: widget.story.races,
          initialRace: currentRace,
          initialCharacter: ch,
        ),
      ),
    );

    if (edited is Character) {
      edited.imagePath = await _persistAnyImage(edited.imagePath);

      setState(() {
        final oldRace = _raceById(ch.raceId) ?? currentRace;
        final newRace = _raceById(edited.raceId) ?? oldRace;

        oldRace.characters.removeWhere((c) => c.id == ch.id);

        final idx = newRace.characters.indexWhere((c) => c.id == ch.id);
        if (idx >= 0) {
          newRace.characters[idx] = edited;
        } else {
          newRace.characters.add(edited);
        }
      });

      await _persistAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personaje actualizado')),
      );
    }
  }

  Future<void> _eliminarPersonaje(Race race, Character ch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar personaje'),
        content: Text('¿Seguro que quieres eliminar a "${ch.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => race.characters.removeWhere((c) => c.id == ch.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Personaje "${ch.name}" eliminado')),
      );
    }
  }

  // ===== Ubicaciones (sin atributos) =====

  Future<void> _crearUbicacion() async {
    final newLoc = await Navigator.push<Location>(
      context,
      MaterialPageRoute(builder: (_) => const LocationForm()),
    );

    if (newLoc is Location) {
      newLoc.imagePath = await _persistAnyImage(newLoc.imagePath);
      setState(() => widget.story.locations.add(newLoc));
      await _persistAll();
    }
  }

  Future<void> _editarUbicacion(Location loc) async {
    final edited = await Navigator.of(context).push<Location>(
      TransparentPageRoute(builder: (_) => LocationForm(initialLocation: loc)),
    );

    if (edited is Location) {
      edited.imagePath = await _persistAnyImage(edited.imagePath);

      setState(() {
        loc.name = edited.name;
        loc.description = edited.description;
        loc.imagePath = edited.imagePath;
        // No hay fields/atributos que sincronizar
      });

      await _persistAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación actualizada')),
      );
    }
  }

  Future<void> _eliminarUbicacion(Location loc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ubicación'),
        content: Text(
          loc.places.isEmpty
              ? '¿Seguro que quieres eliminar la ubicación "${loc.name}"?'
              : 'La ubicación "${loc.name}" tiene ${loc.places.length} lugar(es). Se eliminarán también.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => widget.story.locations.removeWhere((l) => l.id == loc.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ubicación "${loc.name}" eliminada')),
      );
    }
  }

  // ===== Lugares (sin atributos) =====

  Future<void> _crearLugar(Location loc) async {
    final result = await Navigator.push<Place>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceForm(
          locations: widget.story.locations,
          initialLocation: loc,
        ),
      ),
    );

    if (result is Place) {
      result.imagePath = await _persistAnyImage(result.imagePath);
      setState(() {
        final target = _locationById(result.locationId) ?? loc;
        target.places.add(result);
      });
      await _persistAll();
    }
  }

  Future<void> _editarLugar(Location currentLoc, Place p) async {
    final edited = await Navigator.of(context).push<Place>(
      TransparentPageRoute(
        builder: (_) => PlaceForm(
          locations: widget.story.locations,
          initialLocation: currentLoc,
          initialPlace: p,
        ),
      ),
    );

    if (edited is Place) {
      edited.imagePath = await _persistAnyImage(edited.imagePath);

      setState(() {
        final oldLoc = _locationById(p.locationId) ?? currentLoc;
        final newLoc = _locationById(edited.locationId) ?? oldLoc;

        oldLoc.places.removeWhere((x) => x.id == p.id);

        final idx = newLoc.places.indexWhere((x) => x.id == p.id);
        if (idx >= 0) {
          newLoc.places[idx] = edited;
        } else {
          newLoc.places.add(edited);
        }
      });

      await _persistAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lugar actualizado')),
      );
    }
  }

  Future<void> _eliminarLugar(Location loc, Place p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Seguro que quieres eliminar "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => loc.places.removeWhere((x) => x.id == p.id));
      await _persistAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lugar "${p.name}" eliminado')),
      );
    }
  }

  Future<void> _openChapters() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(story: widget.story),
      ),
    );
    if (mounted) setState(() {});
    await _persistAll();
  }

  Future<void> _openPdf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(story: widget.story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoryDetailView(
      story: widget.story,
      buildAnyImage: _buildAnyImage,
      onPreviewImage: _showImagePreview,
      onPickStoryImage: _pickStoryImage,

      onOpenChapters: _openChapters,
      onOpenPdf: _openPdf,

      // Razas/Personajes
      onCreateRace: _crearRaza,
      onEditRace: _editarRaza,
      onDeleteRace: _eliminarRaza,
      onCreateCharacter: _crearPersonaje,
      onEditCharacter: _editarPersonaje,
      onDeleteCharacter: _eliminarPersonaje,

      // Ubicaciones/Lugares
      onCreateLocation: _crearUbicacion,
      onEditLocation: _editarUbicacion,
      onDeleteLocation: _eliminarUbicacion,
      onCreatePlace: _crearLugar,
      onEditPlace: _editarLugar,
      onDeletePlace: _eliminarLugar,
    );
  }
}

// ===== Ruta transparente para overlays =====
class TransparentPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  TransparentPageRoute({required this.builder});

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> sec) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curved =
    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
