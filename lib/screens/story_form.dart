// lib/screens/story_form.dart
import 'package:flutter/material.dart';
import '../models/story.dart';

class StoryForm extends StatefulWidget {
  @override
  _StoryFormState createState() => _StoryFormState();
}

class _StoryFormState extends State<StoryForm> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Vaciar los campos al regresar
  void limpiarCampos() {
    titleController.clear();
    descriptionController.clear();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void guardarHistoria() {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completa ambos campos para guardar la historia'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    final nuevaHistoria = Story(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      imagePath: null,
      races: [],
    );
    limpiarCampos(); // Si deseas limpiar al guardar
    Navigator.pop(context, nuevaHistoria);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    InputDecoration deco(String label, IconData icon) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.inkMuted),
      filled: true,
      fillColor: palette.paper.withOpacity(0.7),
      prefixIcon: Icon(icon, color: palette.inkMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: palette.edge, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: palette.ribbon, width: 2),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Fondo estilo pergamino
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
          // Viñeta radial sutil
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
              _PaperTopBar(title: 'Nueva Historia', palette: palette),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva Historia',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                          fontSize: 26,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _PaperCard(
                        palette: palette,
                        child: TextField(
                          controller: titleController,
                          style: TextStyle(color: palette.ink, fontSize: 18),
                          decoration: deco('Título', Icons.title),
                          cursorColor: palette.ribbon,
                        ),
                      ),

                      _PaperCard(
                        palette: palette,
                        child: TextField(
                          controller: descriptionController,
                          maxLines: 4,
                          style: TextStyle(color: palette.ink, fontSize: 18),
                          decoration: deco('Descripción', Icons.description),
                          cursorColor: palette.ribbon,
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save_alt_rounded, size: 26),
                          label: const Text(
                            'Guardar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.ribbon,
                            foregroundColor: palette.onRibbon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: palette.edge),
                            ),
                            elevation: 4,
                          ),
                          onPressed: guardarHistoria,
                        ),
                      ),
                      const SizedBox(height: 8),
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
  const _PaperTopBar({required this.title, required this.palette});

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
              const SizedBox(width: 8),
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
