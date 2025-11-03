// lib/screens/chapter_form_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chapter.dart';

class ChapterFormScreen extends StatefulWidget {
  final Chapter? initial;
  const ChapterFormScreen({super.key, this.initial});

  @override
  State<ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<ChapterFormScreen> {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      titleCtrl.text = widget.initial!.title;
      contentCtrl.text = widget.initial!.content;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = titleCtrl.text.trim();
    final content = contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe el contenido o un título.')));
      return;
    }
    final ch = Chapter(
      id: widget.initial?.id ?? const Uuid().v4(),
      title: title.isEmpty ? 'Capítulo' : title,
      content: content,
    );
    Navigator.pop(context, ch);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final palette = _PaperPalette.of(context);

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.inkMuted),
      filled: true,
      fillColor: palette.paper.withOpacity(0.7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.ribbon, width: 2),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fondo pergamino
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
          // Viñeta radial
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.6),
                    radius: 1.2,
                    colors: [Colors.black.withOpacity(0.06), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              _PaperTopBar(title: isEdit ? 'Editar capítulo' : 'Nuevo capítulo', palette: palette, onSave: _save),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _PaperCard(
                        palette: palette,
                        child: TextField(
                          controller: titleCtrl,
                          style: TextStyle(color: palette.ink),
                          decoration: deco('Título del capítulo'),
                        ),
                      ),
                      _PaperCard(
                        palette: palette,
                        child: TextField(
                          controller: contentCtrl,
                          maxLines: 18,
                          style: TextStyle(color: palette.ink),
                          decoration: deco('Contenido'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.ribbon,
                            foregroundColor: palette.onRibbon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: palette.edge),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets y paleta “papel” ----------
class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  final VoidCallback onSave;
  const _PaperTopBar({required this.title, required this.palette, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.appBarGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: palette.edge, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
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
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Widget child;
  final _PaperPalette palette;
  const _PaperCard({required this.child, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);
  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Colores principales
  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  // Cinta / primario
  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  // Gradientes
  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];

  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
