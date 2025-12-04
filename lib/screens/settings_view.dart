// lib/screens/settings_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';

typedef AsyncBoolCallback = Future<void> Function(bool value);
typedef AsyncVoidCallback = Future<void> Function();

class SettingsView extends StatelessWidget {
  final bool loading;
  final bool showDeleteHint;
  final bool confirmBeforeDelete;

  final AsyncBoolCallback onToggleShowDeleteHint;
  final AsyncBoolCallback onToggleConfirmBeforeDelete;
  final AsyncVoidCallback onClearCachesOnly;
  final AsyncVoidCallback onClearStoriesOnly;
  final VoidCallback onClose;

  const SettingsView({
    super.key,
    required this.loading,
    required this.showDeleteHint,
    required this.confirmBeforeDelete,
    required this.onToggleShowDeleteHint,
    required this.onToggleConfirmBeforeDelete,
    required this.onClearCachesOnly,
    required this.onClearStoriesOnly,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    return Scaffold(
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 1.2,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftGlowPainter(palette),
              ),
            ),
          ),
          Column(
            children: [
              _PaperTopBar(
                title: 'Configuración',
                palette: palette,
                onClose: onClose,
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                      children: [
                        _SectionTitle('Perfil', palette: palette),
                        _GlassCard(
                          palette: palette,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: palette.ink,
                            ),
                            title: Text(
                              'Editar perfil del autor',
                              style: TextStyle(
                                color: palette.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Foto, nombre (de Google) y descripción',
                              style: TextStyle(
                                color: palette.inkMuted,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: palette.inkMuted,
                            ),
                            onTap: () => Navigator.of(context)
                                .pushNamed('/account'),
                          ),
                        ),
                        _SectionTitle('Preferencias', palette: palette),
                        _GlassCard(
                          palette: palette,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              SwitchListTile.adaptive(
                                title: Text(
                                  'Mostrar consejo de borrado',
                                  style: TextStyle(
                                    color: palette.ink,
                                  ),
                                ),
                                value: showDeleteHint,
                                onChanged: (v) =>
                                    onToggleShowDeleteHint(v),
                                subtitle: Text(
                                  '“Desliza hacia la izquierda para eliminar”',
                                  style: TextStyle(
                                    color: palette.inkMuted,
                                  ),
                                ),
                                secondary: Icon(
                                  Icons.swipe_left_alt_rounded,
                                  color: palette.inkMuted,
                                ),
                              ),
                              Divider(
                                height: 0,
                                color: palette.edge.withOpacity(0.6),
                              ),
                              SwitchListTile.adaptive(
                                title: Text(
                                  'Confirmar antes de eliminar',
                                  style: TextStyle(
                                    color: palette.ink,
                                  ),
                                ),
                                value: confirmBeforeDelete,
                                onChanged: (v) =>
                                    onToggleConfirmBeforeDelete(v),
                                subtitle: Text(
                                  'Diálogo de confirmación antes de borrar',
                                  style: TextStyle(
                                    color: palette.inkMuted,
                                  ),
                                ),
                                secondary: Icon(
                                  Icons.warning_amber_rounded,
                                  color: palette.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _SectionTitle('Datos locales', palette: palette),
                        _GlassCard(
                          palette: palette,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.cleaning_services_rounded,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  'Borrar cachés de imágenes',
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'No elimina historias. Limpia las imágenes guardadas localmente.',
                                  style: TextStyle(
                                    color: palette.inkMuted,
                                  ),
                                ),
                                trailing: FilledButton(
                                  onPressed: () => onClearCachesOnly(),
                                  child: const Text('Limpiar'),
                                ),
                              ),
                              Divider(
                                height: 0,
                                color: palette.edge.withOpacity(0.6),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'Borrar todas las historias',
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Acción destructiva. Las historias no se pueden recuperar.',
                                  style: TextStyle(
                                    color: palette.inkMuted,
                                  ),
                                ),
                                trailing: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: palette.waxSeal,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => onClearStoriesOnly(),
                                  child: const Text('Eliminar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  final VoidCallback onClose;

  const _PaperTopBar({
    required this.title,
    required this.palette,
    required this.onClose,
  });

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
        border: Border(
          bottom: BorderSide(color: palette.edge, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
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
                onPressed: onClose,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: palette.ink,
                ),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final _PaperPalette palette;

  const _GlassCard({
    required this.child,
    required this.palette,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(14),
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
                  palette.paper.withOpacity(0.85),
                  palette.paper.withOpacity(0.65),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final _PaperPalette palette;

  const _SectionTitle(
      this.text, {
        required this.palette,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: palette.ink,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SoftGlowPainter extends CustomPainter {
  final _PaperPalette palette;

  _SoftGlowPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.ribbon.withOpacity(0.22),
          Colors.transparent,
        ],
        radius: 0.7,
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.0),
          radius: size.width * 0.7,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.0),
      size.width * 0.7,
      paintTop,
    );

    final paintBottom = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.edge.withOpacity(0.18),
          Colors.transparent,
        ],
        radius: 0.8,
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.9, size.height * 1.0),
          radius: size.width * 0.8,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 1.0),
      size.width * 0.8,
      paintBottom,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftGlowPainter oldDelegate) => false;
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

  Color get waxSeal =>
      isDark ? const Color(0xFF7C2D2D) : const Color(0xFFA93A3A);

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
