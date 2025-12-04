import 'package:flutter/material.dart';
import '../models/story.dart';
import 'story_form_view.dart';

class StoryForm extends StatefulWidget {
  const StoryForm({super.key});

  @override
  State<StoryForm> createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void limpiarCampos() {
    titleController.clear();
    descriptionController.clear();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void guardarHistoria() {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          const Text('Completa ambos campos para guardar la historia'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final nuevaHistoria = Story(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      imagePath: null,
      races: [],
    );

    limpiarCampos();
    Navigator.pop(context, nuevaHistoria);
  }

  @override
  Widget build(BuildContext context) {
    return StoryFormView(
      isEdit: false, // este formulario solo crea historias nuevas
      titleController: titleController,
      descriptionController: descriptionController,
      onSave: guardarHistoria,
    );
  }
}
