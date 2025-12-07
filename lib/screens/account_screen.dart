import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/services/cloud_sync_service.dart';
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/main.dart';
import 'account_view.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final acc = context.read<AccountService>();
    _descCtrl.text = acc.authorDescription;
    _nameCtrl.text = acc.customUserName;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndClear(AccountService acc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar datos de perfil'),
        content: const Text(
          'Se eliminarán nombre de usuario, descripción y foto guardados localmente. Tus historias permanecerán intactas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    await acc.clearProfileData();
    if (!mounted) return;

    _descCtrl.clear();
    _nameCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos de perfil borrados.')),
    );
    setState(() {});
  }

  Future<void> _connectGoogle(AccountService acc) async {
    setState(() => _busy = true);
    final result = await acc.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.ok && acc.account != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado: ${acc.displayName}')),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error de Google Sign-In (código ${result.error}). Revisa SHA y OAuth.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio cancelado por el usuario.')),
      );
    }
  }

  Future<void> _signOutGoogle(AccountService acc) async {
    await acc.signOutGoogle();
    if (mounted) setState(() {});
  }

  Future<void> _uploadBackup(
      AccountService acc,
      CloudSyncService cloud,
      ) async {
    if (acc.account == null) return;
    setState(() => _busy = true);
    try {
      final list = await LocalStorageService.getStories();
      await cloud.uploadAll(account: acc, stories: list);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo subido a Google Drive')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup(
      AccountService acc,
      CloudSyncService cloud,
      StoryProvider stories,
      ) async {
    if (acc.account == null) return;
    setState(() => _busy = true);
    try {
      await cloud.restoreAll(account: acc);
      await stories.reloadFromDisk();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos restaurados desde Drive')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al restaurar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccountService>();
    final cloud = context.read<CloudSyncService>();
    final stories = context.read<StoryProvider>();

    return AccountView(
      busy: _busy,
      account: acc,
      nameController: _nameCtrl,
      descController: _descCtrl,
      onNameChanged: acc.setCustomUserName,
      onDescChanged: acc.setAuthorDescription,
      onPickPhoto: acc.setPhotoFromPicker,
      onConnectGoogle: () => _connectGoogle(acc),
      onSignOutGoogle:
      acc.account == null ? null : () => _signOutGoogle(acc),
      onClearProfile: () => _confirmAndClear(acc),
      onUploadBackup: acc.account == null
          ? null
          : () => _uploadBackup(acc, cloud),
      onRestoreBackup: acc.account == null
          ? null
          : () => _restoreBackup(acc, cloud, stories),
    );
  }
}
