import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/character.dart';
import '../models/race.dart';
import 'character_form_view.dart';

class CharacterForm extends StatefulWidget {
  final List<Race> races;
  final Race? initialRace;
  final Character? initialCharacter;

  const CharacterForm({
    super.key,
    required this.races,
    this.initialRace,
    this.initialCharacter,
  });

  @override
  State<CharacterForm> createState() => _CharacterFormState();
}

class _CharacterFormState extends State<CharacterForm> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String? _imagePath;
  Race? _selectedRace;

  /// Valores de atributos actuales del personaje.
  final Map<String, dynamic> _attrValues = <String, dynamic>{};

  bool get _isEdit => widget.initialCharacter != null;

  @override
  void initState() {
    super.initState();

    if (widget.races.isNotEmpty) {
      _selectedRace = widget.initialRace ?? widget.races.first;
    }

    final ch = widget.initialCharacter;
    if (ch != null) {
      _nameCtrl.text = ch.name;
      _descCtrl.text = ch.description ?? '';
      _imagePath = ch.imagePath;
      _attrValues.addAll(ch.attributes);
      try {
        _selectedRace = widget.races.firstWhere((r) => r.id == ch.raceId);
      } catch (_) {
        _selectedRace = widget.initialRace ?? _selectedRace;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _updateImage(String value) {
    setState(() {
      _imagePath = value;
    });
  }

  void _updateRace(Race race) {
    setState(() {
      _selectedRace = race;
      // No borramos valores existentes: se conservarán
      // para las claves que coincidan.
    });
  }

  void _updateAttribute(String key, dynamic value) {
    setState(() {
      _attrValues[key] = value;
    });
  }

  void _save() {
    final race = _selectedRace;
    if (widget.races.isEmpty || race == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes crear al menos una raza.')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del personaje es obligatorio.')),
      );
      return;
    }

    // Validar que todos los campos de la raza tengan valor
    final missing = <String>[];
    for (final def in race.fields) {
      final v = _attrValues[def.key];
      switch (def.type) {
        case RaceFieldType.text:
          if (v == null || (v is String && v.trim().isEmpty)) {
            missing.add(def.label);
          }
          break;
        case RaceFieldType.number:
          if (v == null || (v is String && v.trim().isEmpty)) {
            missing.add(def.label);
          }
          break;
        case RaceFieldType.boolean:
          if (v == null) {
            missing.add(def.label);
          }
          break;
      }
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completa los atributos: ${missing.join(', ')}',
          ),
        ),
      );
      return;
    }

    // Solo guardamos atributos que existan en la raza actual
    final allowedKeys = race.fields.map((f) => f.key).toSet();
    final cleanAttrs = <String, dynamic>{};
    _attrValues.forEach((k, v) {
      if (allowedKeys.contains(k)) cleanAttrs[k] = v;
    });

    final ch = Character(
      id: widget.initialCharacter?.id ?? const Uuid().v4(),
      name: name,
      description: desc.isEmpty ? null : desc,
      raceId: race.id,
      imagePath: _imagePath,
      attributes: cleanAttrs,
    );

    Navigator.pop(context, ch);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Editar personaje' : 'Nuevo personaje';

    return CharacterFormView(
      title: title,
      isEdit: _isEdit,
      nameController: _nameCtrl,
      descriptionController: _descCtrl,
      imagePath: _imagePath,
      races: widget.races,
      selectedRace: _selectedRace,
      attributes: _attrValues,
      onChangeImage: _updateImage,
      onChangeRace: _updateRace,
      onChangeAttribute: _updateAttribute,
      onSave: _save,
    );
  }
}
