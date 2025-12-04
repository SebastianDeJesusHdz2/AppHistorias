import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/models/race.dart';
import 'package:apphistorias/models/character.dart';

typedef ImageBuilderFn = Widget Function(
    String? img, {
    double w,
    double h,
    BoxFit fit,
    });

typedef AsyncVoidCallback = Future<void> Function();
typedef RaceCallback = Future<void> Function(Race race);
typedef CharacterCallback = Future<void> Function(Race race, Character ch);

class StoryDetailView extends StatelessWidget {
  final Story story;

  final ImageBuilderFn buildAnyImage;
  final void Function(String? img) onPreviewImage;

  final AsyncVoidCallback onPickStoryImage;

  final AsyncVoidCallback onOpenChapters;
  final AsyncVoidCallback onOpenPdf;

  final AsyncVoidCallback onCreateRace;
  final RaceCallback onEditRace;
  final RaceCallback onDeleteRace;

  final RaceCallback onCreateCharacter;
  final CharacterCallback onEditCharacter;
  final CharacterCallback onDeleteCharacter;

  const StoryDetailView({
    super.key,
    required this.story,
    required this.buildAnyImage,
    required this.onPreviewImage,
    required this.onPickStoryImage,
    required this.onOpenChapters,
    required this.onOpenPdf,
    required this.onCreateRace,
    required this.onEditRace,
    required this.onDeleteRace,
    required this.onCreateCharacter,
    required this.onEditCharacter,
    required this.onDeleteCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final leftColumn = _buildLeftColumn(context, palette);
        final rightColumn = _buildRightColumn(context, palette);

        return Scaffold(
          resizeToAvoidBottomInset: true,
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
                      center: const Alignment(0.0, -0.7),
                      radius: 1.3,
                      colors: [
                        Colors.white.withOpacity(0.14),
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
                    painter: _SoftLeavesPainter(palette),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(palette: palette),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isMobile
                            ? ListView(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            ...leftColumn,
                            const SizedBox(height: 24),
                            ...rightColumn,
                            const SizedBox(height: 24),
                          ],
                        )
                            : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 13,
                              child: ListView(
                                keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,
                                children: [
                                  ...leftColumn,
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 18,
                              child: ListView(
                                keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,
                                children: [
                                  ...rightColumn,
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildLeftColumn(
      BuildContext context,
      _PaperPalette palette,
      ) {
    return [
      GestureDetector(
        onTap: () => onPreviewImage(story.imagePath),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _GlassWrapper(
            palette: palette,
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: buildAnyImage(
                  story.imagePath,
                  w: 400,
                  h: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _GlassWrapper(
        palette: palette,
        child: _StoryImageSelector(
          palette: palette,
          onPickStoryImage: onPickStoryImage,
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Text(
            'Razas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: palette.ink,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => onCreateRace(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva raza'),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (story.races.isEmpty)
        Text(
          'Aún no hay razas. Agrega la primera.',
          style: TextStyle(color: palette.inkMuted),
        ),
      ...story.races.map(
            (race) => _GlassWrapper(
          palette: palette,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: GestureDetector(
              onTap: () => onPreviewImage(race.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildAnyImage(
                  race.imagePath,
                  w: 48,
                  h: 48,
                ),
              ),
            ),
            title: Text(
              race.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.ink),
            ),
            subtitle: Text(
              race.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.inkMuted),
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => onEditRace(race),
                  icon: const Icon(Icons.edit),
                  color: palette.ink,
                ),
                IconButton(
                  tooltip: 'Eliminar raza',
                  onPressed: () => onDeleteRace(race),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRightColumn(
      BuildContext context,
      _PaperPalette palette,
      ) {
    return [
      Text(
        story.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: palette.ink,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Text(
        story.description,
        style: TextStyle(
          fontSize: 17,
          color: palette.inkMuted,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          FilledButton.icon(
            onPressed: () => onOpenChapters(),
            icon: const Icon(Icons.edit_note),
            label: const Text('Escribir'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.ribbon,
              foregroundColor: palette.onRibbon,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => onOpenPdf(),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.edge),
              foregroundColor: palette.ink,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        'Personajes por raza',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: palette.ink,
        ),
      ),
      const SizedBox(height: 8),
      if (story.races.isEmpty)
        Text(
          'No hay razas; agrega una para comenzar con personajes.',
          style: TextStyle(color: palette.inkMuted),
        ),
      ...story.races.map(
            (race) {
          final count = race.characters.length;
          return _GlassWrapper(
            palette: palette,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildAnyImage(race.imagePath, w: 36, h: 36),
              ),
              title: Text(
                race.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.ink),
              ),
              subtitle: Text(
                '$count personaje${count == 1 ? '' : 's'}',
                style: TextStyle(color: palette.inkMuted),
              ),
              childrenPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => onCreateCharacter(race),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                  IconButton(
                    tooltip: 'Eliminar raza',
                    onPressed: () => onDeleteRace(race),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                ],
              ),
              children: [
                if (race.characters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Sin personajes en esta raza.',
                      style: TextStyle(color: palette.inkMuted),
                    ),
                  ),
                ...race.characters.map(
                      (ch) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.transparent,
                    elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: palette.paper.withOpacity(0.86),
                            border: Border.all(color: palette.edge, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            leading: GestureDetector(
                              onTap: () => onPreviewImage(ch.imagePath),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: buildAnyImage(
                                  ch.imagePath,
                                  w: 44,
                                  h: 44,
                                ),
                              ),
                            ),
                            title: Text(
                              ch.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: palette.ink),
                            ),
                            subtitle: Text(
                              (ch.description ?? '').isEmpty
                                  ? 'Sin descripción'
                                  : (ch.description!.length > 80
                                  ? '${ch.description!.substring(0, 80)}...'
                                  : ch.description!),
                              style: TextStyle(color: palette.inkMuted),
                            ),
                            onTap: () => onEditCharacter(race, ch),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => onEditCharacter(race, ch),
                                  icon: const Icon(Icons.edit),
                                  color: palette.ink,
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () =>
                                      onDeleteCharacter(race, ch),
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  final _PaperPalette palette;

  const _TopBar({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  palette.paper.withOpacity(0.9),
                  palette.paper.withOpacity(0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
                ),
                const SizedBox(width: 4),
                Text(
                  'Detalles de la historia',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryImageSelector extends StatelessWidget {
  final _PaperPalette palette;
  final AsyncVoidCallback onPickStoryImage;

  const _StoryImageSelector({
    required this.palette,
    required this.onPickStoryImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.photo_library_outlined, color: palette.inkMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cambiar imagen de la historia',
            style: TextStyle(color: palette.inkMuted),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => onPickStoryImage(),
          icon: const Icon(Icons.upload),
          label: const Text('Subir'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _GlassWrapper extends StatelessWidget {
  final Widget child;
  final _PaperPalette palette;
  final EdgeInsetsGeometry? margin;

  const _GlassWrapper({
    required this.child,
    required this.palette,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftLeavesPainter extends CustomPainter {
  final _PaperPalette palette;

  _SoftLeavesPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.edge.withOpacity(0.22),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathTop = Path()
      ..moveTo(0, size.height * 0.03)
      ..quadraticBezierTo(size.width * 0.35, 0, size.width * 0.7,
          size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.18, 0,
          size.height * 0.14)
      ..close();
    canvas.drawPath(pathTop, paintTop);

    final paintSide = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.edge.withOpacity(0.26),
          Colors.transparent,
        ],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathSide = Path()
      ..moveTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.4,
          size.width * 0.62, size.height * 0.56)
      ..quadraticBezierTo(
          size.width * 0.86, size.height * 0.7, size.width, size.height * 0.76)
      ..close();
    canvas.drawPath(pathSide, paintSide);

    final paintBottom = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.paper.withOpacity(0.0),
          palette.edge.withOpacity(0.22),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathBottom = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.87,
          size.width * 0.6, size.height * 0.93)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 1.02, 0, size.height * 0.98)
      ..close();
    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant _SoftLeavesPainter oldDelegate) => false;
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
