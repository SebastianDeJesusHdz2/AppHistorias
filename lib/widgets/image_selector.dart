import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_api_service.dart';
import '../services/local_storage_service.dart'; // Si guardas tu key en local

class ImageSelector extends StatefulWidget {
  final Function(String) onImageSelected;
  const ImageSelector({required this.onImageSelected});

  @override
  _ImageSelectorState createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  String? _displayedImage; // Puede ser path local o base64
  bool _imageIsBase64 = false;

  Future<void> pickFromDevice() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _displayedImage = image.path;
        _imageIsBase64 = false;
      });
      widget.onImageSelected(image.path);
    }
  }

  Future<void> generateFromAI() async {
    final controller = TextEditingController();
    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Generar imagen por IA'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "Describe la imagen a generar"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Generar'),
          ),
        ],
      ),
    );
    if (prompt != null && prompt.trim().isNotEmpty) {
      // Recupera la key desde LocalStorageService o pásala directamente según tu integración.
      final apiKey = await LocalStorageService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Primero ingresa tu API Key en Configuración.')),
        );
        return;
      }
      final base64img = await ImageApiService.generateImage(prompt.trim());
      if (base64img != null) {
        setState(() {
          _displayedImage = base64img;
          _imageIsBase64 = true;
        });
        widget.onImageSelected(base64img);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la imagen.\nIntenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imgWidget = Icon(Icons.image, size: 58, color: Colors.grey);
    if (_displayedImage != null && _displayedImage!.isNotEmpty) {
      if (_imageIsBase64) {
        imgWidget = Image.memory(
          base64Decode(_displayedImage!),
          width: 58, height: 58, fit: BoxFit.cover,
          errorBuilder: (ctx, err, s) => Icon(Icons.image, color: Colors.red, size: 58),
        );
      } else {
        imgWidget = Image.file(
          File(_displayedImage!),
          width: 58, height: 58, fit: BoxFit.cover,
          errorBuilder: (ctx, err, s) => Icon(Icons.image, color: Colors.red, size: 58),
        );
      }
    }
    return Row(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: imgWidget),
        SizedBox(width: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.upload),
          label: Text("Subir"),
          onPressed: pickFromDevice,
        ),
        SizedBox(width: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.auto_awesome),
          label: Text("IA"),
          onPressed: generateFromAI,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        )
      ],
    );
  }
}

