// lib/screens/chapter_form_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter.dart';

class ChapterFormScreen extends StatefulWidget {
  final Chapter? initial;
  const ChapterFormScreen({super.key, this.initial});

  @override
  State<ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<ChapterFormScreen> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      titleCtrl.text = widget.initial!.title;
      contentCtrl.text = widget.initial!.content;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = titleCtrl.text.trim();
    final content = contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe el contenido o un título.')));
      return;
    }
    final ch = Chapter(
      id: widget.initial?.id ?? const Uuid().v4(),
      title: title.isEmpty ? 'Capítulo' : title,
      content: content,
    );
    Navigator.pop(context, ch);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar capítulo' : 'Nuevo capítulo'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Título del capítulo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
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
}

