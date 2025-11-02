import 'package:flutter/material.dart';
import '../models/story.dart';

class StoryForm extends StatefulWidget {
  @override
  _StoryFormState createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Vaciar los campos al regresar
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
          content: Text('Completa ambos campos para guardar la historia'),
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
    limpiarCampos(); // Si deseas limpiar al guardar
    Navigator.pop(context, nuevaHistoria);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Historia'),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva Historia',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 27,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 32),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: colorScheme.secondary),
                filled: true,
                fillColor: colorScheme.surface.withOpacity(0.95),
                prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colorScheme.secondary, width: 2),
                ),
              ),
              cursorColor: colorScheme.primary,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 25),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: colorScheme.secondary),
                filled: true,
                fillColor: colorScheme.surface.withOpacity(0.95),
                prefixIcon: Icon(Icons.description, color: colorScheme.primary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colorScheme.secondary, width: 2),
                ),
              ),
              cursorColor: colorScheme.primary,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 42),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: Icon(Icons.save_alt_rounded, size: 26),
                label: Text(
                  'Guardar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                onPressed: guardarHistoria,
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}



