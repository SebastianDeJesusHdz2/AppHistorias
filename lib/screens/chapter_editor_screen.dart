import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/story.dart';
import '../models/chapter.dart';
import 'chapter_form_screen.dart';
import 'pdf_preview_screen.dart';
import 'chapter_editor_view.dart';

class ChapterEditorScreen extends StatefulWidget {
  final Story story;
  const ChapterEditorScreen({super.key, required this.story});

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  List<Chapter> get _chapters => widget.story.chapters;

  Future<void> _addChapter() async {
    final ch = await Navigator.push<Chapter>(
      context,
      MaterialPageRoute(builder: (_) => const ChapterFormScreen()),
    );
    if (ch != null) {
      setState(() => _chapters.add(ch));
    }
  }

  Future<void> _editChapter(int index) async {
    final current = _chapters[index];
    final ch = await Navigator.push<Chapter>(
      context,
      MaterialPageRoute(builder: (_) => ChapterFormScreen(initial: current)),
    );
    if (ch != null) {
      setState(() => _chapters[index] = ch);
    }
  }

  Future<void> _deleteChapter(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar capítulo'),
        content: const Text('¿Deseas eliminar este capítulo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
        false;
    if (ok) {
      setState(() => _chapters.removeAt(index));
    }
  }

  void _reorderChapters(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _chapters.removeAt(oldIndex);
      _chapters.insert(newIndex, item);
    });
  }

  void _previewAllPdf() {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay capítulos que exportar')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(story: widget.story),
      ),
    );
  }

  void _previewOnePdf(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          story: widget.story,
          chapterIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChapterEditorView(
      chapters: _chapters,
      onAddChapter: _addChapter,
      onEditChapter: _editChapter,
      onDeleteChapter: _deleteChapter,
      onReorderChapters: _reorderChapters,
      onPreviewAllPdf: _previewAllPdf,
      onPreviewOnePdf: _previewOnePdf,
    );
  }
}
