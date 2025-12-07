import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter.dart';
import 'chapter_form_view.dart';

class ChapterFormScreen extends StatefulWidget {
  final Chapter? initial;
  const ChapterFormScreen({super.key, this.initial});

  @override
  State<ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<ChapterFormScreen> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController contentCtrl = TextEditingController();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      titleCtrl.text = initial.title;
      contentCtrl.text = initial.content;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe el contenido o un título.'),
        ),
      );
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
    return ChapterFormView(
      isEdit: _isEdit,
      titleController: titleCtrl,
      contentController: contentCtrl,
      onSave: _save,
    );
  }
}
