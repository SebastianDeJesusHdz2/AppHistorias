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

import 'home_view.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool) onThemeToggle;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDark,
  });

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
    final hint =
        await LocalStorageService.getPrefBool('showDeleteHint') ?? true;
    final confirm =
        await LocalStorageService.getPrefBool('confirmBeforeDelete') ?? true;
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

  Future<void> _createStory(StoryProvider storyProvider) async {
    final newStory = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => StoryForm()),
    );
    if (newStory != null && newStory is Story) {
      await storyProvider.addStory(newStory);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteStoryAt(StoryProvider storyProvider, int index) async {
    await storyProvider.removeStoryAt(index);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historia eliminada')),
    );
    setState(() {});
  }

  Future<void> _openStory(Story story) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StoryDetailScreen(story: story),
      ),
    );
    if (mounted) setState(() {});
  }

  // ========= Lógica de imágenes para la lista =========

  String _cacheBuster() => '?t=${DateTime.now().millisecondsSinceEpoch}';

  Widget _broken(double w, double h) => Container(
    width: w,
    height: h,
    color: Colors.black12,
    child: Icon(
      Icons.broken_image,
      size: h * 0.45,
      color: Colors.redAccent,
    ),
  );

  Widget _buildAnyImage(
      String? img, {
        double w = 92,
        double h = 92,
        BoxFit fit = BoxFit.cover,
      }) {
    if (img == null || img.isEmpty) {
      return Container(
        width: w,
        height: h,
        color: Colors.black12,
        child: Icon(
          Icons.image,
          size: h * 0.45,
          color: Colors.grey.shade400,
        ),
      );
    }

    final looksBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    if (looksBase64) {
      try {
        final bytes = base64Decode(img);
        return Image.memory(
          bytes,
          width: w,
          height: h,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _broken(w, h),
        );
      } catch (_) {
        return _broken(w, h);
      }
    }

    if (img.startsWith('http')) {
      final url = img.contains('?t=') ? img : img + _cacheBuster();
      return Image.network(
        url,
        width: w,
        height: h,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _broken(w, h),
      );
    }

    final f = File(img);
    if (!f.existsSync()) return _broken(w, h);

    return Image(
      image: FileImage(f),
      width: w,
      height: h,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _broken(w, h),
    );
  }

  void _showImagePreview(String? img) {
    if (img == null || img.isEmpty) return;

    ImageProvider? provider;
    final looksBase64 = img.length > 100 &&
        !img.startsWith('http') &&
        !img.contains(Platform.pathSeparator);

    if (looksBase64) {
      try {
        provider = MemoryImage(base64Decode(img));
      } catch (_) {
        provider = null;
      }
    } else if (img.startsWith('http')) {
      final url = img.contains('?t=') ? img : img + _cacheBuster();
      provider = NetworkImage(url);
    } else {
      final f = File(img);
      if (f.existsSync()) provider = FileImage(f);
    }

    if (provider == null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (ctx) => Center(child: _broken(220, 220)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // evita que el tap en la imagen cierre
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.9,
                ),
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                      image: provider!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);

    return HomeView(
      isDark: widget.isDark,
      onThemeToggle: widget.onThemeToggle,
      loadingPrefs: _loadingPrefs,
      showDeleteHint: _showDeleteHint,
      confirmBeforeDelete: _confirmBeforeDelete,
      stories: storyProvider.stories,
      onOpenSettings: _openSettings,
      onCreateStory: () => _createStory(storyProvider),
      onDeleteStoryAt: (index) => _deleteStoryAt(storyProvider, index),
      onOpenStory: _openStory,
      imageBuilder: _buildAnyImage,
      onPreviewStoryImage: _showImagePreview,
    );
  }
}
