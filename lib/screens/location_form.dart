import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';

class LocationForm extends StatefulWidget {
  final Location? initialLocation;
  const LocationForm({super.key, this.initialLocation});

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  bool get _isEdit => widget.initialLocation != null;

  @override
  void initState() {
    super.initState();
    final l = widget.initialLocation;
    if (l != null) {
      _nameCtrl.text = l.name;
      _descCtrl.text = l.description;
      _imageCtrl.text = l.imagePath ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }

    final loc = Location(
      id: widget.initialLocation?.id ?? const Uuid().v4(),
      name: name,
      description: _descCtrl.text.trim(),
      imagePath: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      places: widget.initialLocation?.places, // conserva lugares al editar
    );

    Navigator.pop(context, loc);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final isMobile = c.maxWidth < 700;
        final maxW = isMobile ? double.infinity : 760.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? 'Editar ubicación' : 'Nueva ubicación'),
            actions: [
              TextButton(onPressed: _save, child: const Text('Guardar')),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ruta/URL de imagen (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
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
