import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart'; // <- mapEquals
import 'package:flutter/material.dart';

import '../models/race.dart';
import '../widgets/image_selector.dart';

class CharacterFormView extends StatefulWidget {
  final String title;
  final bool isEdit;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  final String? imagePath;
  final List<Race> races;
  final Race? selectedRace;

  /// key = RaceFieldDef.key, value dinámico
  final Map<String, dynamic> attributes;

  final ValueChanged<String> onChangeImage;
  final ValueChanged<Race> onChangeRace;
  final void Function(String key, dynamic value) onChangeAttribute;
  final VoidCallback onSave;

  const CharacterFormView({
    super.key,
    required this.title,
    required this.isEdit,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.races,
    required this.selectedRace,
    required this.attributes,
    required this.onChangeImage,
    required this.onChangeRace,
    required this.onChangeAttribute,
    required this.onSave,
  });

  @override
  State<CharacterFormView> createState() => _CharacterFormViewState();
}

class _CharacterFormViewState extends State<CharacterFormView> {
  final Map<String, TextEditingController> _attrControllers = {};

  @override
  void initState() {
    super.initState();
    _syncAttrControllers();
  }

  @override
  void didUpdateWidget(covariant CharacterFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRace != widget.selectedRace ||
        !mapEquals(oldWidget.attributes, widget.attributes)) {
      _syncAttrControllers();
    }
  }

  @override
  void dispose() {
    for (final c in _attrControllers.values) {
      c.dispose();
    }
    _attrControllers.clear();
    super.dispose();
  }

  void _syncAttrControllers() {
    final race = widget.selectedRace;
    final keys = race?.fields.map((f) => f.key).toSet() ?? <String>{};

    final toRemove =
    _attrControllers.keys.where((k) => !keys.contains(k)).toList();
    for (final k in toRemove) {
      _attrControllers[k]?.dispose();
      _attrControllers.remove(k);
    }

    for (final def in race?.fields ?? const <RaceFieldDef>[]) {
      final key = def.key;
      final currentValue = widget.attributes[key];
      final textValue = currentValue?.toString() ?? '';

      final existing = _attrControllers[key];
      if (existing == null) {
        _attrControllers[key] = TextEditingController(text: textValue);
      } else if (existing.text != textValue) {
        existing.value = existing.value.copyWith(
          text: textValue,
          selection: TextSelection.collapsed(offset: textValue.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;

    final content = SafeArea(
      child: Column(
        children: [
          _PaperTopBar(
            title: widget.title,
            palette: palette,
            showBack: !widget.isEdit,
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
                        nameController: widget.nameController,
                        descriptionController: widget.descriptionController,
                        imagePath: widget.imagePath,
                        races: widget.races,
                        selectedRace: widget.selectedRace,
                        attributes: widget.attributes,
                        attrControllers: _attrControllers,
                        onChangeImage: widget.onChangeImage,
                        onChangeRace: widget.onChangeRace,
                        onChangeAttribute: widget.onChangeAttribute,
                        onSave: widget.onSave,
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

    if (!widget.isEdit) {
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
  final List<Race> races;
  final Race? selectedRace;
  final Map<String, dynamic> attributes;
  final Map<String, TextEditingController> attrControllers;
  final ValueChanged<String> onChangeImage;
  final ValueChanged<Race> onChangeRace;
  final void Function(String key, dynamic value) onChangeAttribute;
  final VoidCallback onSave;

  const _FormBody({
    required this.palette,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.races,
    required this.selectedRace,
    required this.attributes,
    required this.attrControllers,
    required this.onChangeImage,
    required this.onChangeRace,
    required this.onChangeAttribute,
    required this.onSave,
  });

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.inkMuted),
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

  Widget _buildCharacterImage() {
    final placeholder = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.paper.withOpacity(0.9),
        border: Border.all(color: palette.edge),
      ),
      child: Icon(
        Icons.person,
        size: 34,
        color: palette.inkMuted,
      ),
    );

    if (imagePath == null || imagePath!.isEmpty) return placeholder;

    ImageProvider? provider;
    if (imagePath!.startsWith('http')) {
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
    final currentRace = selectedRace;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _GlassCard(
          palette: palette,
          child: Row(
            children: [
              _buildCharacterImage(),
              const SizedBox(width: 14),
              Expanded(
                child: ImageSelector(
                  onImageSelected: onChangeImage,
                ),
              ),
            ],
          ),
        ),
        _GlassCard(
          palette: palette,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: palette.ink),
                decoration: _deco('Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                style: TextStyle(color: palette.ink),
                decoration: _deco('Descripción'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: _deco('Raza'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Race>(
                    value: currentRace,
                    items: races
                        .map(
                          (r) => DropdownMenuItem<Race>(
                        value: r,
                        child: Text(r.name),
                      ),
                    )
                        .toList(),
                    onChanged: (r) {
                      if (r != null) onChangeRace(r);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (currentRace != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Atributos de la raza',
              style: TextStyle(
                color: palette.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...currentRace.fields.map(
                (def) => _buildAttributeField(def),
          ),
        ],
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

  Widget _buildAttributeField(RaceFieldDef def) {
    final controller = attrControllers[def.key]!;
    final value = attributes[def.key];

    switch (def.type) {
      case RaceFieldType.text:
        return _GlassCard(
          palette: palette,
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: palette.ink),
            decoration: _deco(def.label),
            onChanged: (v) => onChangeAttribute(def.key, v),
          ),
        );

      case RaceFieldType.number:
        return _GlassCard(
          palette: palette,
          child: TextField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: TextStyle(color: palette.ink),
            decoration: _deco('${def.label} (número)'),
            onChanged: (v) {
              final trimmed = v.trim();
              if (trimmed.isEmpty) {
                onChangeAttribute(def.key, null);
              } else {
                final num? parsed = num.tryParse(trimmed);
                onChangeAttribute(def.key, parsed ?? trimmed);
              }
            },
          ),
        );

      case RaceFieldType.boolean:
        final bool current = value is bool ? value : false;
        return _GlassCard(
          palette: palette,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  def.label,
                  style: TextStyle(color: palette.ink),
                ),
              ),
              Switch(
                value: current,
                onChanged: (v) => onChangeAttribute(def.key, v),
              ),
            ],
          ),
        );
    }
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
