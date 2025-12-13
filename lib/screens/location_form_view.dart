import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LocationFormView extends StatelessWidget {
  final String title;
  final bool isEdit;

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  final String? imagePath;

  final void Function(String value) onChangeImage;
  final VoidCallback onSave;

  const LocationFormView({
    super.key,
    required this.title,
    required this.isEdit,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.onChangeImage,
    required this.onSave,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null) onChangeImage(file.path);
  }

  Widget _preview(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.image, size: 48)),
      );
    }

    if (path.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.broken_image, size: 48)),
          ),
        ),
      );
    }

    final f = File(path);
    if (!f.existsSync()) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.broken_image, size: 48)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        f,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final isMobile = c.maxWidth < 700;
        final maxWidth = isMobile ? double.infinity : 780.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              TextButton(
                onPressed: onSave,
                child: const Text('Guardar'),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _preview(imagePath),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Ruta/URL de imagen (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          controller:
                          TextEditingController(text: imagePath ?? ''),
                          onChanged: onChangeImage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _pickImage(context),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar ubicación'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
