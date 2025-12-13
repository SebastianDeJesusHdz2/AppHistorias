import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';
import '../models/place.dart';

class PlaceForm extends StatefulWidget {
  final List<Location> locations;
  final Location? initialLocation;
  final Place? initialPlace;

  const PlaceForm({
    super.key,
    required this.locations,
    this.initialLocation,
    this.initialPlace,
  });

  @override
  State<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  Location? _selectedLocation;

  bool get _isEdit => widget.initialPlace != null;

  @override
  void initState() {
    super.initState();

    _selectedLocation = widget.initialLocation ??
        (widget.locations.isNotEmpty ? widget.locations.first : null);

    final p = widget.initialPlace;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _imageCtrl.text = p.imagePath ?? '';

      try {
        _selectedLocation =
            widget.locations.firstWhere((l) => l.id == p.locationId);
      } catch (_) {}
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
    final loc = _selectedLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una ubicación.')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del lugar es obligatorio.')),
      );
      return;
    }

    final place = Place(
      id: widget.initialPlace?.id ?? const Uuid().v4(),
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      locationId: loc.id,
      imagePath: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
    );

    Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final isMobile = c.maxWidth < 700;
        final maxW = isMobile ? double.infinity : 760.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEdit ? 'Editar lugar' : 'Nuevo lugar'),
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
                  DropdownButtonFormField<Location>(
                    value: _selectedLocation,
                    items: widget.locations
                        .map((l) => DropdownMenuItem(
                      value: l,
                      child:
                      Text(l.name, overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (l) => setState(() => _selectedLocation = l),
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      labelText: 'Nombre del lugar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar lugar'),
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
