// lib/screens/chapter_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/story.dart';
import '../models/chapter.dart';
import 'chapter_form_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capítulos'),
        actions: [
          IconButton(onPressed: _addChapter, icon: const Icon(Icons.add)),
        ],
      ),
      body: widget.story.chapters.isEmpty
          ? const Center(child: Text('Sin capítulos. Agrega el primero.'))
          : ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: widget.story.chapters.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = widget.story.chapters.removeAt(oldIndex);
            widget.story.chapters.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final ch = widget.story.chapters[index];
          return Card(
            key: ValueKey(ch.id),
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
                  IconButton(onPressed: () => _editChapter(index), icon: const Icon(Icons.edit)),
                  IconButton(
                      onPressed: () => _deleteChapter(index),
                      icon: const Icon(Icons.delete_forever, color: Colors.red)),
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
