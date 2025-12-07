import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/race.dart';
import '../widgets/image_selector.dart';

class RaceFieldRow {
  final TextEditingController labelCtrl;
  final TextEditingController keyCtrl;
  RaceFieldType type;

  RaceFieldRow({
    required this.labelCtrl,
    required this.keyCtrl,
    required this.type,
  });
}

class RaceFormView extends StatelessWidget {
  final String title;
  final bool isEdit;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  final String? imagePath;
  final List<RaceFieldRow> fieldRows;

  final ValueChanged<String> onChangeImage;
  final VoidCallback onAddField;
  final void Function(int index) onRemoveField;
  final void Function(int index, RaceFieldType type) onChangeFieldType;
  final VoidCallback onSave;

  const RaceFormView({
    super.key,
    required this.title,
    required this.isEdit,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.fieldRows,
    required this.onChangeImage,
    required this.onAddField,
    required this.onRemoveField,
    required this.onChangeFieldType,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;

    final content = SafeArea(
      child: Column(
        children: [
          _PaperTopBar(
            title: title,
            palette: palette,
            showBack: !isEdit,
          ),
          Expanded(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 900
                      ? 880.0
                      : constraints.maxWidth;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _FormBody(
                        palette: palette,
                        nameController: nameController,
                        descriptionController: descriptionController,
                        imagePath: imagePath,
                        fieldRows: fieldRows,
                        onChangeImage: onChangeImage,
                        onAddField: onAddField,
                        onRemoveField: onRemoveField,
                        onChangeFieldType: onChangeFieldType,
                        onSave: onSave,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    if (!isEdit) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _PaperBackground(palette: palette),
            content,
          ],
        ),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black.withOpacity(0.25),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 900,
                maxHeight: size.height * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    _PaperBackground(palette: palette),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final _PaperPalette palette;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? imagePath;
  final List<RaceFieldRow> fieldRows;
  final ValueChanged<String> onChangeImage;
  final VoidCallback onAddField;
  final void Function(int index) onRemoveField;
  final void Function(int index, RaceFieldType type) onChangeFieldType;
  final VoidCallback onSave;

  const _FormBody({
    required this.palette,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.fieldRows,
    required this.onChangeImage,
    required this.onAddField,
    required this.onRemoveField,
    required this.onChangeFieldType,
    required this.onSave,
  });

  InputDecoration _deco(BuildContext context, String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      labelStyle: TextStyle(color: palette.inkMuted),
      helperStyle: TextStyle(color: palette.inkMuted),
      filled: true,
      fillColor: palette.paper.withOpacity(0.78),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.ribbon, width: 2),
      ),
    );
  }

  Widget _buildRaceImage() {
    final placeholder = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.paper.withOpacity(0.9),
        border: Border.all(color: palette.edge),
      ),
      child: Icon(
        Icons.image,
        size: 34,
        color: palette.inkMuted,
      ),
    );

    if (imagePath == null || imagePath!.isEmpty) {
      return placeholder;
    }

    final isBase64 = imagePath!.length > 100 &&
        !imagePath!.startsWith('http') &&
        !imagePath!.contains(Platform.pathSeparator);

    ImageProvider? provider;
    if (isBase64) {
      try {
        provider = MemoryImage(base64Decode(imagePath!));
      } catch (_) {
        provider = null;
      }
    } else if (imagePath!.startsWith('http')) {
      provider = NetworkImage(imagePath!);
    } else {
      final file = File(imagePath!);
      if (file.existsSync()) {
        provider = FileImage(file);
      }
    }

    if (provider == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image(
        image: provider,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _GlassCard(
          palette: palette,
          child: Row(
            children: [
              _buildRaceImage(),
              const SizedBox(width: 14),
              Expanded(
                child: ImageSelector(
                  onImageSelected: onChangeImage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GlassCard(
          palette: palette,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, 'Nombre de la raza'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, 'Descripción'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                'Características de la raza',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.ink,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddField,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        if (fieldRows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Aún no has agregado características.',
              style: TextStyle(color: palette.inkMuted),
            ),
          ),
        ...fieldRows.asMap().entries.map(
              (entry) {
            final index = entry.key;
            final row = entry.value;
            return _FieldEditorRow(
              palette: palette,
              fieldRow: row,
              onRemove: () => onRemoveField(index),
              onTypeChanged: (t) => onChangeFieldType(index, t),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.ribbon,
              foregroundColor: palette.onRibbon,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: palette.edge),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldEditorRow extends StatelessWidget {
  final _PaperPalette palette;
  final RaceFieldRow fieldRow;
  final VoidCallback onRemove;
  final ValueChanged<RaceFieldType> onTypeChanged;

  const _FieldEditorRow({
    required this.palette,
    required this.fieldRow,
    required this.onRemove,
    required this.onTypeChanged,
  });

  InputDecoration _deco(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.inkMuted),
      filled: true,
      fillColor: palette.paper.withOpacity(0.85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.ribbon, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      palette: palette,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fieldRow.labelCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: palette.ink),
                  decoration:
                  _deco(context, 'Etiqueta visible (ej: Tamaño de orejas)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: fieldRow.keyCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: palette.ink),
                  decoration:
                  _deco(context, 'Clave interna (ej: tamano_orejas)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Tipo:',
                style: TextStyle(color: palette.ink),
              ),
              const SizedBox(width: 10),
              DropdownButton<RaceFieldType>(
                value: fieldRow.type,
                dropdownColor: palette.paper,
                onChanged: (v) {
                  if (v != null) onTypeChanged(v);
                },
                items: const [
                  DropdownMenuItem(
                    value: RaceFieldType.text,
                    child: Text('Texto'),
                  ),
                  DropdownMenuItem(
                    value: RaceFieldType.number,
                    child: Text('Número'),
                  ),
                  DropdownMenuItem(
                    value: RaceFieldType.boolean,
                    child: Text('Sí/No'),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_forever),
                color: Colors.red,
                tooltip: 'Eliminar característica',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaperBackground extends StatelessWidget {
  final _PaperPalette palette;

  const _PaperBackground({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.backgroundGradient,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 1.2,
                  colors: [
                    Colors.black.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  final bool showBack;

  const _PaperTopBar({
    required this.title,
    required this.palette,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.appBarGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: palette.edge, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final _PaperPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({
    required this.palette,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.paper.withOpacity(0.9),
                  palette.paper.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PaperPalette {
  final BuildContext context;

  _PaperPalette._(this.context);

  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get paper =>
      isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge =>
      isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink =>
      isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted =>
      isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  Color get ribbon =>
      isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  List<Color> get backgroundGradient => isDark
      ? [
    const Color(0xFF2F2821),
    const Color(0xFF3A3027),
    const Color(0xFF2C261F),
  ]
      : [
    const Color(0xFFF6ECD7),
    const Color(0xFFF0E1C8),
    const Color(0xFFE8D6B8),
  ];

  List<Color> get appBarGradient => isDark
      ? [
    const Color(0xFF3B3229),
    const Color(0xFF362E25),
  ]
      : [
    const Color(0xFFF7EBD5),
    const Color(0xFFF0E1C8),
  ];
}
