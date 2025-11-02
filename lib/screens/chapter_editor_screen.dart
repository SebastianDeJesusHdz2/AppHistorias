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
    ) ??
        false;
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
      ),
      body: chapters.isEmpty
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
            child: ListTile(
              title: Text(ch.title.isEmpty ? 'Capítulo ${index + 1}' : ch.title),
              subtitle: Text(
                ch.content.length > 80 ? '${ch.content.substring(0, 80)}…' : ch.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Vista previa PDF (capítulo)',
                    onPressed: () => _previewOnePdf(index),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                  IconButton(
                    onPressed: () => _editChapter(index),
                    icon: const Icon(Icons.edit),
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
    );
  }
}
