import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/services/account_service.dart';

typedef StoryIndexCallback = Future<void> Function(int index);
typedef StoryCallback = Future<void> Function(Story story);
typedef AsyncVoidCallback = Future<void> Function();

class HomeView extends StatelessWidget {
  final bool isDark;
  final void Function(bool) onThemeToggle;

  final bool loadingPrefs;
  final bool showDeleteHint;
  final bool confirmBeforeDelete;

  final List<Story> stories;

  final AsyncVoidCallback onOpenSettings;
  final AsyncVoidCallback onCreateStory;
  final StoryIndexCallback onDeleteStoryAt;
  final StoryCallback onOpenStory;

  final Widget Function(String? img, {double w, double h, BoxFit fit})
  imageBuilder;
  final void Function(String? imagePath) onPreviewStoryImage;

  const HomeView({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
    required this.loadingPrefs,
    required this.showDeleteHint,
    required this.confirmBeforeDelete,
    required this.stories,
    required this.onOpenSettings,
    required this.onCreateStory,
    required this.onDeleteStoryAt,
    required this.onOpenStory,
    required this.imageBuilder,
    required this.onPreviewStoryImage,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700 && width < 1100;
    final isDesktop = width >= 1100;
    final hasStories = stories.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          _PaperBackground(palette: palette),
          Column(
            children: [
              _PaperAppBar(
                palette: palette,
                isDark: isDark,
                onThemeToggle: onThemeToggle,
                onOpenSettings: onOpenSettings,
              ),
              Expanded(
                child: loadingPrefs
                    ? const Center(child: CircularProgressIndicator())
                    : _HomeBody(
                  palette: palette,
                  stories: stories,
                  hasStories: hasStories,
                  showDeleteHint: showDeleteHint,
                  confirmBeforeDelete: confirmBeforeDelete,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  onDeleteStoryAt: onDeleteStoryAt,
                  onOpenStory: onOpenStory,
                  imageBuilder: imageBuilder,
                  onPreviewStoryImage: onPreviewStoryImage,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _PaperFab(
        palette: palette,
        onPressed: () => onCreateStory(),
      ),
      floatingActionButtonLocation: isDesktop
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HomeBody extends StatelessWidget {
  final _PaperPalette palette;
  final List<Story> stories;
  final bool hasStories;
  final bool showDeleteHint;
  final bool confirmBeforeDelete;
  final bool isTablet;
  final bool isDesktop;
  final StoryIndexCallback onDeleteStoryAt;
  final StoryCallback onOpenStory;

  final Widget Function(String? img, {double w, double h, BoxFit fit})
  imageBuilder;
  final void Function(String? imagePath) onPreviewStoryImage;

  const _HomeBody({
    required this.palette,
    required this.stories,
    required this.hasStories,
    required this.showDeleteHint,
    required this.confirmBeforeDelete,
    required this.isTablet,
    required this.isDesktop,
    required this.onDeleteStoryAt,
    required this.onOpenStory,
    required this.imageBuilder,
    required this.onPreviewStoryImage,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasStories) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Sin historias todavía.\nCrea tu primera historia y empieza a imaginar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 26 : 20,
              color: palette.inkMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    }

    final maxWidth = isDesktop ? 1100.0 : (isTablet ? 760.0 : double.infinity);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDeleteHint)
              _DeleteHintBanner(
                palette: palette,
                topPadding: isTablet || isDesktop ? 18 : 12,
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isTablet || isDesktop ? 32 : 20,
                  12,
                  isTablet || isDesktop ? 32 : 20,
                  isDesktop ? 80 : 32,
                ),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return _StoryCard(
                    palette: palette,
                    story: story,
                    confirmBeforeDelete: confirmBeforeDelete,
                    onDelete: () => onDeleteStoryAt(index),
                    onTap: () => onOpenStory(story),
                    imageBuilder: imageBuilder,
                    onPreviewStoryImage: onPreviewStoryImage,
                  );
                },
              ),
            ),
          ],
        ),
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
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.6, -0.9),
                radius: 1.2,
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
              painter: _LeafCanopyPainter(palette),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteHintBanner extends StatelessWidget {
  final _PaperPalette palette;
  final double topPadding;

  const _DeleteHintBanner({
    required this.palette,
    this.topPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: palette.paper.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.edge.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swipe_left_rounded,
                  size: 18,
                  color: palette.inkMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Desliza hacia la izquierda una historia para eliminarla.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                      height: 1.2,
                    ),
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

class _StoryCard extends StatelessWidget {
  final _PaperPalette palette;
  final Story story;
  final bool confirmBeforeDelete;
  final AsyncVoidCallback onDelete;
  final AsyncVoidCallback onTap;

  final Widget Function(String? img, {double w, double h, BoxFit fit})
  imageBuilder;
  final void Function(String? imagePath) onPreviewStoryImage;

  const _StoryCard({
    required this.palette,
    required this.story,
    required this.confirmBeforeDelete,
    required this.onDelete,
    required this.onTap,
    required this.imageBuilder,
    required this.onPreviewStoryImage,
  });

  Future<bool> _confirmDismiss(BuildContext context) async {
    if (!confirmBeforeDelete) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.paper,
        title: Text(
          'Eliminar historia',
          style: TextStyle(color: palette.ink),
        ),
        content: Text(
          'Esta acción no se puede deshacer, ¿deseas continuar?',
          style: TextStyle(color: palette.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: palette.ink),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.waxSeal,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
        false;
    return ok;
  }

  Widget _buildThumbnail() {
    final img = story.imagePath;

    if (img == null || img.isEmpty) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              palette.ribbon.withOpacity(0.9),
              palette.ribbon.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          Icons.book_rounded,
          size: 40,
          color: palette.onRibbon,
        ),
      );
    }
    return GestureDetector(
      onTap: () => onPreviewStoryImage(img),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageBuilder(
          img,
          w: 92,
          h: 92,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(story.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: palette.waxSeal,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDismiss(context),
      onDismissed: (_) async => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              decoration: BoxDecoration(
                color: palette.paper.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.edge, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        _buildThumbnail(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: palette.ink,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                story.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: palette.inkMuted,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: palette.inkMuted,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeafCanopyPainter extends CustomPainter {
  final _PaperPalette palette;

  _LeafCanopyPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLeafLight = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.paper.withOpacity(0.0),
          palette.edge.withOpacity(0.22),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathTop = Path()
      ..moveTo(0, size.height * 0.05)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.0,
          size.width * 0.7, size.height * 0.08)
      ..quadraticBezierTo(
          size.width * 0.45, size.height * 0.22, 0, size.height * 0.18)
      ..close();
    canvas.drawPath(pathTop, paintLeafLight);

    final paintLeafDark = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.edge.withOpacity(0.3),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathSide = Path()
      ..moveTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.4,
          size.width * 0.6, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.85, size.height * 0.7, size.width, size.height * 0.75)
      ..close();
    canvas.drawPath(pathSide, paintLeafDark);

    final paintBottom = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.paper.withOpacity(0.0),
          palette.edge.withOpacity(0.25),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathBottom = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.88,
          size.width * 0.55, size.height * 0.94)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 1.02, 0, size.height * 0.98)
      ..close();
    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant _LeafCanopyPainter oldDelegate) => false;
}

class _PaperAppBar extends StatelessWidget {
  final _PaperPalette palette;
  final bool isDark;
  final void Function(bool) onThemeToggle;
  final AsyncVoidCallback onOpenSettings;

  const _PaperAppBar({
    required this.palette,
    required this.isDark,
    required this.onThemeToggle,
    required this.onOpenSettings,
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
        border: Border(
          bottom: BorderSide(color: palette.edge, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Consumer<AccountService>(
                  builder: (_, acc, __) {
                    final hasPhoto = acc.photoBytes != null;
                    final title =
                    (acc.displayName?.trim().isNotEmpty ?? false)
                        ? acc.displayName!.trim()
                        : 'Sin sesión';
                    final avatar = hasPhoto
                        ? CircleAvatar(
                      radius: 18,
                      backgroundColor: palette.edge.withOpacity(0.2),
                      child: ClipOval(
                        child: Image.memory(
                          acc.photoBytes!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        : CircleAvatar(
                      radius: 18,
                      backgroundColor: palette.ribbon,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: palette.onRibbon,
                      ),
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        avatar,
                        const SizedBox(width: 10),
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 1,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: palette.ink),
                tooltip: 'Configuración',
                onPressed: () => onOpenSettings(),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Switch(
                  value: isDark,
                  onChanged: onThemeToggle,
                  activeColor: palette.ribbon,
                  inactiveThumbColor: palette.ink,
                  inactiveTrackColor: palette.edge.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperFab extends StatelessWidget {
  final _PaperPalette palette;
  final VoidCallback onPressed;

  const _PaperFab({
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: palette.ribbon,
      foregroundColor: palette.onRibbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.edge, width: 1),
      ),
      icon: const Icon(Icons.add),
      label: const Text(
        'Nueva historia',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
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
