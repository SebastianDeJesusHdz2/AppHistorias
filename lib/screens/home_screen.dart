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

    Widget buildHint({EdgeInsets padding = const EdgeInsets.fromLTRB(22, 12, 22, 6)}) {
      if (!_showDeleteHint || !hasStories) return const SizedBox.shrink();
      final color = Theme.of(context).colorScheme.secondary;
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.swipe_left_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Consejo: desliza hacia la izquierda cualquier historia para eliminarla.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Título dinámico: avatar + nombre (o CronIA)
        title: Consumer<AccountService>(
          builder: (_, acc, __) {
            final hasPhoto = acc.photoBytes != null;
            final title = (acc.displayName?.trim().isNotEmpty ?? false)
                ? acc.displayName!.trim()
                : 'CronIA';
            final avatar = hasPhoto
                ? CircleAvatar(radius: 14, backgroundImage: MemoryImage(acc.photoBytes!))
                : const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16));
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Configuración',
            onPressed: _openSettings,
          ),
          Switch(
            value: widget.isDark,
            onChanged: widget.onThemeToggle,
            activeColor: Theme.of(context).colorScheme.secondary,
            inactiveThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: _loadingPrefs
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
              color: Theme.of(context).colorScheme.secondary,
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
                          errorBuilder: (ctx, e, s) => const Icon(Icons.book_rounded, size: 38),
                        ),
                      );
                    } catch (_) {
                      leadingWidget = const Icon(Icons.book_rounded, size: 38);
                    }
                  } else if (img.startsWith('http')) {
                    leadingWidget = ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        img,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, s) => const Icon(Icons.book_rounded, size: 38),
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
                        errorBuilder: (ctx, e, s) => const Icon(Icons.book_rounded, size: 38),
                      )
                          : const Icon(Icons.book_rounded, size: 38),
                    );
                  }
                } else {
                  leadingWidget = CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    radius: 32,
                    child: const Icon(Icons.book_rounded, size: 38, color: Colors.white),
                  );
                }

                return Dismissible(
                  key: ValueKey(story.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (_) async {
                    if (!_confirmBeforeDelete) return true;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar historia'),
                        content: const Text('Esta acción no se puede deshacer, ¿deseas continuar?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
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
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 22),
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      leading: leadingWidget,
                      title: Text(
                        story.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      subtitle: Text(
                        story.description,
                        style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.secondary),
                      ),
                      trailing: Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 30,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => StoryDetailScreen(story: story),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva historia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final newStory =
          await Navigator.push(context, MaterialPageRoute(builder: (ctx) => StoryForm()));
          if (newStory != null && newStory is Story) {
            await storyProvider.addStory(newStory);
            if (mounted) setState(() {});
          }
        },
      ),
    );
  }
}

