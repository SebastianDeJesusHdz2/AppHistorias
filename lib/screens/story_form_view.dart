import 'dart:ui';
import 'package:flutter/material.dart';

class StoryFormView extends StatelessWidget {
  final bool isEdit;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;

  const StoryFormView({
    super.key,
    required this.isEdit,
    required this.titleController,
    required this.descriptionController,
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
            title: isEdit ? 'Editar historia' : 'Nueva historia',
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
                        titleController: titleController,
                        descriptionController: descriptionController,
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
      backgroundColor: Colors.black.withOpacity(0.14),
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
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;

  const _FormBody({
    required this.palette,
    required this.titleController,
    required this.descriptionController,
    required this.onSave,
  });

  InputDecoration _deco(BuildContext context, String label) {
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _GlassCard(
          palette: palette,
          child: Column(
            children: [
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, 'Título de la historia'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: TextStyle(color: palette.ink),
                decoration: _deco(context, 'Descripción'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
