import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/race.dart';
import 'race_form_view.dart';

class RaceForm extends StatefulWidget {
  final Race? initialRace;

  const RaceForm({
    super.key,
    this.initialRace,
  });

  @override
  State<RaceForm> createState() => _RaceFormState();
}

class _RaceFormState extends State<RaceForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _imagePath;
  final List<RaceFieldRow> _fieldRows = [];

  bool get _isEdit => widget.initialRace != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRace;
    if (r != null) {
      _nameCtrl.text = r.name;
      _descCtrl.text = r.description;
      _imagePath = r.imagePath;
      for (final f in r.fields) {
        _fieldRows.add(
          RaceFieldRow(
            labelCtrl: TextEditingController(text: f.label),
            keyCtrl: TextEditingController(text: f.key),
            type: f.type,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final fr in _fieldRows) {
      fr.labelCtrl.dispose();
      fr.keyCtrl.dispose();
    }
    super.dispose();
  }

  void _updateImage(String value) {
    setState(() {
      _imagePath = value;
    });
  }

  void _addFieldRow() {
    setState(() {
      _fieldRows.add(
        RaceFieldRow(
          labelCtrl: TextEditingController(),
          keyCtrl: TextEditingController(),
          type: RaceFieldType.text,
        ),
      );
    });
  }

  void _removeFieldRow(int index) {
    setState(() {
      final fr = _fieldRows.removeAt(index);
      fr.labelCtrl.dispose();
      fr.keyCtrl.dispose();
    });
  }

  void _changeFieldType(int index, RaceFieldType type) {
    setState(() {
      _fieldRows[index].type = type;
    });
  }

  String _slugify(String s) {
    var out = s.toLowerCase();
    const repl = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };
    out = out.split('').map((c) => repl[c] ?? c).join();
    out = out.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    out = out.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return out;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de la raza es obligatorio.')),
      );
      return;
    }

    final defs = <RaceFieldDef>[];
    final seen = <String>{};

    for (final fr in _fieldRows) {
      final rawLabel = fr.labelCtrl.text.trim();
      if (rawLabel.isEmpty) continue;

      var key = fr.keyCtrl.text.trim();
      key = key.isEmpty ? _slugify(rawLabel) : _slugify(key);
      if (key.isEmpty) continue;

      var base = key;
      var i = 1;
      while (seen.contains(key)) {
        key = '${base}_${i++}';
      }
      seen.add(key);

      defs.add(
        RaceFieldDef(
          key: key,
          label: rawLabel,
          type: fr.type,
        ),
      );
    }

    final race = Race(
      id: widget.initialRace?.id ?? const Uuid().v4(),
      name: name,
      description: desc,
      imagePath: _imagePath,
      fields: defs,
    );

    Navigator.pop(context, race);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Editar raza' : 'Nueva raza';

    return RaceFormView(
      title: title,
      isEdit: _isEdit, // <- IMPORTANTE
      nameController: _nameCtrl,
      descriptionController: _descCtrl,
      imagePath: _imagePath,
      fieldRows: _fieldRows,
      onChangeImage: _updateImage,
      onAddField: _addFieldRow,
      onRemoveField: _removeFieldRow,
      onChangeFieldType: _changeFieldType,
      onSave: _save,
    );
  }
}
