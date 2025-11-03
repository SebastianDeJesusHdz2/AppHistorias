// lib/screens/home_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apphistorias/models/story.dart';
import 'package:apphistorias/main.dart'; // StoryProvider
import 'package:apphistorias/screens/story_detail_screen.dart';
import 'package:apphistorias/screens/story_form.dart';
import 'package:apphistorias/screens/settings_screen.dart';
import 'package:apphistorias/services/local_storage_service.dart';

// Para mostrar nombre y foto en el AppBar
import 'package:apphistorias/services/account_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool) onThemeToggle;
  final bool isDark;
  const HomeScreen({super.key, required this.onThemeToggle, required this.isDark});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDeleteHint = true;
  bool _confirmBeforeDelete = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final hint = await LocalStorageService.getPrefBool('showDeleteHint') ?? true;
    final confirm = await LocalStorageService.getPrefBool('confirmBeforeDelete') ?? true;
    if (!mounted) return;
    setState(() {
      _showDeleteHint = hint;
      _confirmBeforeDelete = confirm;
      _loadingPrefs = false;
    });
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (changed == true) {
      await _loadPrefs();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final hasStories = storyProvider.stories.isNotEmpty;

    final palette = _PaperPalette.of(context);

    Widget buildHint({EdgeInsets padding = const EdgeInsets.fromLTRB(22, 12, 22, 6)}) {
      if (!_showDeleteHint || !hasStories) return const SizedBox.shrink();
      return Padding(
        padding: padding,
        child: Container(
          decoration: BoxDecoration(
            color: palette.paper.withOpacity(0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.edge.withOpacity(0.35)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.swipe_left_rounded, size: 18, color: palette.inkMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Consejo: desliza hacia la izquierda cualquier historia para eliminarla.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // Fondo tipo papel
      body: Stack(
        children: [
          // Capa base pergamino
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
          // Contenido
          Column(
            children: [
              // AppBar “papel”
              _PaperAppBar(
                palette: palette,
                isDark: widget.isDark,
                onThemeToggle: widget.onThemeToggle,
              ),
              Expanded(
                child: _loadingPrefs
                    ? const Center(child: CircularProgressIndicator())
                    : (!hasStories
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      'Sin historias todavía.\n¡Crea tu primera historia y empieza a imaginar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: palette.inkMuted,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHint(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                        itemCount: storyProvider.stories.length,
                        itemBuilder: (context, index) {
                          final story = storyProvider.stories[index];
                          Widget leadingWidget;
                          final img = story.imagePath;

                          if (img != null && img.isNotEmpty) {
                            final isBase64 = img.length > 100 &&
                                !img.startsWith('http') &&
                                !img.contains(Platform.pathSeparator);
                            if (isBase64) {
                              try {
                                leadingWidget = ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    base64Decode(img),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, e, s) =>
                                        Icon(Icons.book_rounded, size: 38, color: palette.inkMuted),
                                  ),
                                );
                              } catch (_) {
                                leadingWidget = Icon(Icons.book_rounded, size: 38, color: palette.inkMuted);
                              }
                            } else if (img.startsWith('http')) {
                              leadingWidget = ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  img,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, e, s) =>
                                      Icon(Icons.book_rounded, size: 38, color: palette.inkMuted),
                                ),
                              );
                            } else {
                              final f = File(img);
                              leadingWidget = ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: f.existsSync()
                                    ? Image.file(
                                  f,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, e, s) => Icon(Icons.book_rounded,
                                      size: 38, color: palette.inkMuted),
                                )
                                    : Icon(Icons.book_rounded, size: 38, color: palette.inkMuted),
                              );
                            }
                          } else {
                            leadingWidget = CircleAvatar(
                              backgroundColor: palette.ribbon,
                              radius: 32,
                              child: Icon(Icons.book_rounded, size: 38, color: palette.onRibbon),
                            );
                          }

                          return Dismissible(
                            key: ValueKey(story.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: palette.waxSeal,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (_) async {
                              if (!_confirmBeforeDelete) return true;
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: palette.paper,
                                  title: Text('Eliminar historia',
                                      style: TextStyle(color: palette.ink)),
                                  content: Text('Esta acción no se puede deshacer, ¿deseas continuar?',
                                      style: TextStyle(color: palette.inkMuted)),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('Cancelar', style: TextStyle(color: palette.ink))),
                                    FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: palette.waxSeal),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Eliminar')),
                                  ],
                                ),
                              );
                              return ok ?? false;
                            },
                            onDismissed: (_) async {
                              await storyProvider.removeStoryAt(index);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Historia eliminada')),
                                );
                                setState(() {}); // por si desaparece el hint
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 22),
                              decoration: BoxDecoration(
                                color: palette.paper,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: palette.edge, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 20),
                                leading: leadingWidget,
                                title: Text(
                                  story.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                    color: palette.ink,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                subtitle: Text(
                                  story.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: palette.inkMuted,
                                    height: 1.25,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: palette.inkMuted,
                                  size: 30,
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) =>
                                          StoryDetailScreen(story: story),
                                    ),
                                  );
                                  if (mounted) setState(() {}); // refleja cambios al volver
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _PaperFab(palette: palette, onPressed: () async {
        final newStory = await Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => StoryForm()),
        );
        if (newStory != null && newStory is Story) {
          await storyProvider.addStory(newStory);
          if (mounted) setState(() {});
        }
      }),
    );
  }
}

// ------ Widgets de estilo papel ------

class _PaperAppBar extends StatelessWidget {
  final _PaperPalette palette;
  final bool isDark;
  final void Function(bool) onThemeToggle;
  const _PaperAppBar({
    required this.palette,
    required this.isDark,
    required this.onThemeToggle,
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
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
              const SizedBox(width: 12),
              // Título dinámico: avatar + nombre (o CronIA)
              Expanded(
                child: Consumer<AccountService>(
                  builder: (_, acc, __) {
                    final hasPhoto = acc.photoBytes != null;
                    final title = (acc.displayName?.trim().isNotEmpty ?? false)
                        ? acc.displayName!.trim()
                        : 'CronIA';
                    final avatar = hasPhoto
                        ? CircleAvatar(
                      radius: 16,
                      backgroundColor: palette.edge.withOpacity(0.2),
                      child: ClipOval(
                        child: Image.memory(acc.photoBytes!, width: 30, height: 30, fit: BoxFit.cover),
                      ),
                    )
                        : CircleAvatar(
                      radius: 16,
                      backgroundColor: palette.ribbon,
                      child: Icon(Icons.person, size: 18, color: palette.onRibbon),
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
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  if (changed == true && context.mounted) {
                    // rebuild se maneja en HomeScreen al volver
                  }
                },
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
  const _PaperFab({required this.palette, required this.onPressed});

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
      label: const Text('Nueva historia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}

// ------ Paleta pergamino ------

class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);

  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Colores principales
  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge  => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink   => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  // Cinta / botón (FAB)
  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  // “Sello de cera” para eliminar
  Color get waxSeal => isDark ? const Color(0xFF7C2D2D) : const Color(0xFFA93A3A);

  // Gradientes base
  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];

  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
