import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/models/race.dart';
import 'package:apphistorias/models/character.dart';

// NUEVO
import 'package:apphistorias/models/location.dart';
import 'package:apphistorias/models/place.dart';

typedef ImageBuilderFn = Widget Function(
    String? img, {
    double w,
    double h,
    BoxFit fit,
    });

typedef AsyncVoidCallback = Future<void> Function();

typedef RaceCallback = Future<void> Function(Race race);
typedef CharacterCallback = Future<void> Function(Race race, Character ch);

typedef LocationCallback = Future<void> Function(Location loc);
typedef PlaceCallback = Future<void> Function(Location loc, Place place);

class StoryDetailView extends StatelessWidget {
  final Story story;

  final ImageBuilderFn buildAnyImage;
  final void Function(String? img) onPreviewImage;

  final AsyncVoidCallback onPickStoryImage;
  final AsyncVoidCallback onOpenChapters;
  final AsyncVoidCallback onOpenPdf;

  // Razas / Personajes
  final AsyncVoidCallback onCreateRace;
  final RaceCallback onEditRace;
  final RaceCallback onDeleteRace;

  final Future<void> Function(Race race) onCreateCharacter;
  final CharacterCallback onEditCharacter;
  final CharacterCallback onDeleteCharacter;

  // Ubicaciones / Lugares
  final AsyncVoidCallback onCreateLocation;
  final LocationCallback onEditLocation;
  final LocationCallback onDeleteLocation;

  final Future<void> Function(Location loc) onCreatePlace;
  final PlaceCallback onEditPlace;
  final PlaceCallback onDeletePlace;

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

    required this.onCreateLocation,
    required this.onEditLocation,
    required this.onDeleteLocation,
    required this.onCreatePlace,
    required this.onEditPlace,
    required this.onDeletePlace,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final left = _buildLeftColumn(context, palette);
        final right = _buildRightColumn(context, palette);

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
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SoftShapesPainter(palette)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(palette: palette, title: 'Detalles de la historia'),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isMobile
                            ? ListView(
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            ...left,
                            const SizedBox(height: 22),
                            ...right,
                            const SizedBox(height: 22),
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
                                  ...left,
                                  const SizedBox(height: 22),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 18,
                              child: ListView(
                                keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,
                                children: [
                                  ...right,
                                  const SizedBox(height: 22),
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

  // =========================
  // COLUMNA IZQUIERDA
  // =========================
  List<Widget> _buildLeftColumn(BuildContext context, _PaperPalette palette) {
    return [
      GestureDetector(
        onTap: () => onPreviewImage(story.imagePath),
        child: _GlassCard(
          palette: palette,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: buildAnyImage(
                  story.imagePath,
                  w: 480,
                  h: 320,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _GlassCard(
        palette: palette,
        child: Row(
          children: [
            Icon(Icons.photo_library_outlined, color: palette.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cambiar imagen de la historia',
                style: TextStyle(color: palette.inkMuted),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => onPickStoryImage(),
              icon: const Icon(Icons.upload),
              label: const Text('Subir'),
              style: FilledButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),

      // ===== Razas =====
      Row(
        children: [
          Text(
            'Razas',
            style: TextStyle(
              color: palette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
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
      ...story.races.map((race) {
        return _GlassCard(
          palette: palette,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: GestureDetector(
              onTap: () => onPreviewImage(race.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: buildAnyImage(race.imagePath, w: 48, h: 48),
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
        );
      }),

      const SizedBox(height: 18),

      // ===== Ubicaciones =====
      Row(
        children: [
          Text(
            'Ubicaciones',
            style: TextStyle(
              color: palette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => onCreateLocation(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva ubicación'),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (story.locations.isEmpty)
        Text(
          'Aún no hay ubicaciones. Agrega la primera.',
          style: TextStyle(color: palette.inkMuted),
        ),
      ...story.locations.map((loc) {
        return _GlassCard(
          palette: palette,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: GestureDetector(
              onTap: () => onPreviewImage(loc.imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: buildAnyImage(loc.imagePath, w: 48, h: 48),
              ),
            ),
            title: Text(
              loc.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.ink),
            ),
            subtitle: Text(
              loc.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.inkMuted),
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => onEditLocation(loc),
                  icon: const Icon(Icons.edit),
                  color: palette.ink,
                ),
                IconButton(
                  tooltip: 'Eliminar ubicación',
                  onPressed: () => onDeleteLocation(loc),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  // =========================
  // COLUMNA DERECHA
  // =========================
  List<Widget> _buildRightColumn(BuildContext context, _PaperPalette palette) {
    return [
      Text(
        story.title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 26,
          color: palette.ink,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Text(
        story.description,
        style: TextStyle(fontSize: 16.5, color: palette.inkMuted),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 10,
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

      // ===== Personajes por raza =====
      Text(
        'Personajes por raza',
        style: TextStyle(
          fontWeight: FontWeight.w900,
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
      ...story.races.map((race) {
        final count = race.characters.length;

        return _GlassCard(
          palette: palette,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
            childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              if (race.characters.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sin personajes en esta raza.',
                    style: TextStyle(color: palette.inkMuted),
                  ),
                ),
              ...race.characters.map((ch) {
                final subtitle = (ch.description ?? '').trim();
                final shown = subtitle.isEmpty
                    ? 'Sin descripción'
                    : (subtitle.length > 90 ? '${subtitle.substring(0, 90)}…' : subtitle);

                return _InnerCard(
                  palette: palette,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    leading: GestureDetector(
                      onTap: () => onPreviewImage(ch.imagePath),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildAnyImage(ch.imagePath, w: 44, h: 44),
                      ),
                    ),
                    title: Text(
                      ch.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.ink),
                    ),
                    subtitle: Text(
                      shown,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                          onPressed: () => onDeleteCharacter(race, ch),
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),

      const SizedBox(height: 22),

      // ===== Lugares por ubicación =====
      Text(
        'Lugares por ubicación',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: palette.ink,
        ),
      ),
      const SizedBox(height: 8),
      if (story.locations.isEmpty)
        Text(
          'No hay ubicaciones; agrega una para comenzar con lugares.',
          style: TextStyle(color: palette.inkMuted),
        ),
      ...story.locations.map((loc) {
        final count = loc.places.length;

        return _GlassCard(
          palette: palette,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: buildAnyImage(loc.imagePath, w: 36, h: 36),
            ),
            title: Text(
              loc.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.ink),
            ),
            subtitle: Text(
              '$count lugar${count == 1 ? '' : 'es'}',
              style: TextStyle(color: palette.inkMuted),
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => onCreatePlace(loc),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
                IconButton(
                  tooltip: 'Eliminar ubicación',
                  onPressed: () => onDeleteLocation(loc),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                ),
              ],
            ),
            childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              if (loc.places.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sin lugares en esta ubicación.',
                    style: TextStyle(color: palette.inkMuted),
                  ),
                ),
              ...loc.places.map((p) {
                final subtitle = (p.description ?? '').trim();
                final shown = subtitle.isEmpty
                    ? 'Sin descripción'
                    : (subtitle.length > 90 ? '${subtitle.substring(0, 90)}…' : subtitle);

                return _InnerCard(
                  palette: palette,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    leading: GestureDetector(
                      onTap: () => onPreviewImage(p.imagePath),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildAnyImage(p.imagePath, w: 44, h: 44),
                      ),
                    ),
                    title: Text(
                      p.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.ink),
                    ),
                    subtitle: Text(
                      shown,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.inkMuted),
                    ),
                    onTap: () => onEditPlace(loc, p),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => onEditPlace(loc, p),
                          icon: const Icon(Icons.edit),
                          color: palette.ink,
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => onDeletePlace(loc, p),
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    ];
  }
}

// =========================
// UI helpers (no dependen de tu repo)
// =========================

class _TopBar extends StatelessWidget {
  final _PaperPalette palette;
  final String title;

  const _TopBar({
    required this.palette,
    required this.title,
  });

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
              color: palette.paper.withOpacity(0.86),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _GlassCard extends StatelessWidget {
  final _PaperPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.palette,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(12),
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
              color: palette.paper.withOpacity(0.82),
              border: Border.all(
                color: Colors.white.withOpacity(0.32),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _InnerCard extends StatelessWidget {
  final _PaperPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _InnerCard({
    required this.palette,
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: palette.paper.withOpacity(0.72),
              border: Border.all(color: palette.edge.withOpacity(0.75)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftShapesPainter extends CustomPainter {
  final _PaperPalette palette;
  _SoftShapesPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          palette.edge.withOpacity(0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final top = Path()
      ..moveTo(0, size.height * 0.04)
      ..quadraticBezierTo(
          size.width * 0.35, 0, size.width * 0.78, size.height * 0.10)
      ..quadraticBezierTo(
          size.width * 0.45, size.height * 0.22, 0, size.height * 0.18)
      ..close();

    canvas.drawPath(top, p1);

    final p2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          palette.edge.withOpacity(0.24),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final side = Path()
      ..moveTo(size.width, size.height * 0.46)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.40,
          size.width * 0.62, size.height * 0.58)
      ..quadraticBezierTo(
          size.width * 0.90, size.height * 0.72, size.width, size.height * 0.78)
      ..close();

    canvas.drawPath(side, p2);

    final p3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          palette.edge.withOpacity(0.20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final bottom = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.86,
          size.width * 0.62, size.height * 0.94)
      ..quadraticBezierTo(
          size.width * 0.30, size.height * 1.03, 0, size.height * 0.98)
      ..close();

    canvas.drawPath(bottom, p3);
  }

  @override
  bool shouldRepaint(covariant _SoftShapesPainter oldDelegate) => false;
}

class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);

  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get paper => isDark ? const Color(0xFF3A3229) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);

  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted =>
      isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  List<Color> get backgroundGradient => isDark
      ? const [
    Color(0xFF2F2821),
    Color(0xFF3A3027),
    Color(0xFF2C261F),
  ]
      : const [
    Color(0xFFF6ECD7),
    Color(0xFFF0E1C8),
    Color(0xFFE8D6B8),
  ];
}
