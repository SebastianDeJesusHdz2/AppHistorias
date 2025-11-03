// lib/screens/chapter_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/story.dart';
import '../models/chapter.dart';
import 'chapter_form_screen.dart';
import 'pdf_preview_screen.dart'; // NUEVO: usar la misma ventana de preview

class ChapterEditorScreen extends StatefulWidget {
  final Story story;
  const ChapterEditorScreen({super.key, required this.story});

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  void _addChapter() async {
    final ch = await Navigator.push<Chapter>(
      context,
      MaterialPageRoute(builder: (_) => const ChapterFormScreen()),
    );
    if (ch != null) {
      setState(() => widget.story.chapters.add(ch));
    }
  }

  void _editChapter(int index) async {
    final current = widget.story.chapters[index];
    final ch = await Navigator.push<Chapter>(
      context,
      MaterialPageRoute(builder: (_) => ChapterFormScreen(initial: current)),
    );
    if (ch != null) {
      setState(() => widget.story.chapters[index] = ch);
    }
  }

  void _deleteChapter(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar capítulo'),
        content: const Text('¿Deseas eliminar este capítulo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    ) ?? false;
    if (ok) {
      setState(() => widget.story.chapters.removeAt(index));
    }
  }

  void _previewAllPdf() {
    if (widget.story.chapters.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No hay capítulos que exportar')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(story: widget.story), // todos
      ),
    );
  }

  void _previewOnePdf(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          story: widget.story,
          chapterIndex: index, // solo uno
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.story.chapters;

    // Paleta y fondos tipo “papel”
    final _PaperPalette palette = _PaperPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capítulos'),
        actions: [
          IconButton(
            tooltip: 'Exportar todo a PDF',
            onPressed: _previewAllPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(onPressed: _addChapter, icon: const Icon(Icons.add)),
        ],
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
          // Viñeta radial sutil
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

          // Contenido original con Cards personalizadas
          chapters.isEmpty
              ? const Center(child: Text('Sin capítulos. Agrega el primero.'))
              : ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: chapters.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = chapters.removeAt(oldIndex);
                chapters.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final ch = chapters[index];
              return Card(
                key: ValueKey(ch.id ?? const Uuid().v4()),
                color: palette.paper,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: palette.edge, width: 1),
                ),
                child: ListTile(
                  title: Text(
                    ch.title.isEmpty ? 'Capítulo ${index + 1}' : ch.title,
                    style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    ch.content.length > 80 ? '${ch.content.substring(0, 80)}…' : ch.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.inkMuted),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Vista previa PDF (capítulo)',
                        onPressed: () => _previewOnePdf(index),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        color: palette.ink,
                      ),
                      IconButton(
                        onPressed: () => _editChapter(index),
                        icon: const Icon(Icons.edit),
                        color: palette.ink,
                      ),
                      IconButton(
                        onPressed: () => _deleteChapter(index),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                  onTap: () => _editChapter(index),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Solo estilos (sin lógica)
class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);
  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];
  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
