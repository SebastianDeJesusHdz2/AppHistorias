import 'dart:ui';

import 'package:flutter/material.dart';

class ChapterFormView extends StatelessWidget {
  final bool isEdit;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onSave;

  const ChapterFormView({
    super.key,
    required this.isEdit,
    required this.titleController,
    required this.contentController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
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
                    center: const Alignment(0.0, -0.7),
                    radius: 1.25,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, 1.1),
                    radius: 1.4,
                    colors: [
                      Colors.black.withOpacity(0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _PaperTopBar(
                  title: isEdit ? 'Editar capítulo' : 'Nuevo capítulo',
                  palette: palette,
                  onSave: onSave,
                ),
                Expanded(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16 + viewInsets.bottom,
                      top: 12,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth =
                        constraints.maxWidth >= 960 ? 920.0 : constraints.maxWidth;

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: _FormBody(
                              palette: palette,
                              titleController: titleController,
                              contentController: contentController,
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
          ),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final _PaperPalette palette;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onSave;

  const _FormBody({
    required this.palette,
    required this.titleController,
    required this.contentController,
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _GlassCard(
          palette: palette,
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: palette.ink),
            decoration: _deco('Título del capítulo'),
          ),
        ),
        _GlassCard(
          palette: palette,
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: contentController,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: 10,
            style: TextStyle(color: palette.ink),
            decoration: _deco('Contenido'),
          ),
        ),
        const SizedBox(height: 10),
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

class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  final VoidCallback onSave;

  const _PaperTopBar({
    required this.title,
    required this.palette,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        height: 60,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
            ),
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
            IconButton(
              onPressed: onSave,
              icon: Icon(Icons.save, color: palette.ink),
              tooltip: 'Guardar',
            ),
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
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.paper.withOpacity(0.94),
                  palette.paper.withOpacity(0.78),
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
