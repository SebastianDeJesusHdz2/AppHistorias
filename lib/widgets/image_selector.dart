import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelector extends StatefulWidget {
  final Function(String) onImageSelected;
  const ImageSelector({super.key, required this.onImageSelected});

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  String? _displayedImage;

  Future<void> pickFromDevice() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _displayedImage = image.path;
      });
      widget.onImageSelected(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imgWidget = const Icon(Icons.image, size: 58, color: Colors.grey);

    if (_displayedImage != null && _displayedImage!.isNotEmpty) {
      imgWidget = Image.file(
        File(_displayedImage!),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, s) =>
        const Icon(Icons.image, color: Colors.red, size: 58),
      );
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imgWidget,
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('Subir'),
          onPressed: pickFromDevice,
        ),
      ],
    );
  }
}
