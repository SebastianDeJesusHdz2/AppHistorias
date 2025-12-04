// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_storage_service.dart';
import '../main.dart';
import 'settings_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _showDeleteHint = true;
  bool _confirmBeforeDelete = true;

  bool _prefsChanged = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final showHint =
        await LocalStorageService.getPrefBool('showDeleteHint') ?? true;
    final confirmDel =
        await LocalStorageService.getPrefBool('confirmBeforeDelete') ?? true;

    if (!mounted) return;
    setState(() {
      _showDeleteHint = showHint;
      _confirmBeforeDelete = confirmDel;
      _loading = false;
    });
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _clearCachesOnly() async {
    final ok = await _confirm(
      'Borrar cachés',
      'Se borrarán las imágenes locales de la aplicación. Tus historias permanecerán intactas.',
    );
    if (!ok) return;

    await LocalStorageService.clearImagesDir();

    if (!mounted) return;
    _prefsChanged = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cachés de imágenes limpiadas.')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _clearStoriesOnly() async {
    final ok = await _confirm(
      'Borrar historias',
      'Esto eliminará todas las historias guardadas. Esta acción no se puede deshacer.',
    );
    if (!ok) return;

    await LocalStorageService.clearStoriesOnly();

    final provider = Provider.of<StoryProvider>(context, listen: false);
    provider.stories.clear();
    await provider.saveAll();

    if (!mounted) return;
    _prefsChanged = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historias eliminadas.')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _toggleShowDeleteHint(bool v) async {
    setState(() => _showDeleteHint = v);
    await LocalStorageService.setPrefBool('showDeleteHint', v);
    _prefsChanged = true;
  }

  Future<void> _toggleConfirmBeforeDelete(bool v) async {
    setState(() => _confirmBeforeDelete = v);
    await LocalStorageService.setPrefBool('confirmBeforeDelete', v);
    _prefsChanged = true;
  }

  void _close() {
    Navigator.pop(context, _prefsChanged);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsView(
      loading: _loading,
      showDeleteHint: _showDeleteHint,
      confirmBeforeDelete: _confirmBeforeDelete,
      onToggleShowDeleteHint: _toggleShowDeleteHint,
      onToggleConfirmBeforeDelete: _toggleConfirmBeforeDelete,
      onClearCachesOnly: _clearCachesOnly,
      onClearStoriesOnly: _clearStoriesOnly,
      onClose: _close,
    );
  }
}
