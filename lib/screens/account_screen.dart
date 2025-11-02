import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/services/cloud_sync_service.dart';
import 'package:apphistorias/services/local_storage_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _descCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final acc = context.read<AccountService>();
    _descCtrl.text = acc.authorDescription;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccountService>();
    final cloud = context.read<CloudSyncService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del autor')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primary.withOpacity(.15),
                    backgroundImage: acc.photoBytes != null ? MemoryImage(acc.photoBytes!) : null,
                    child: acc.photoBytes == null
                        ? Icon(Icons.person, size: 48, color: theme.colorScheme.primary)
                        : null,
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async => acc.setPhotoFromPicker(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(acc.displayName ?? 'Sin sesión', style: theme.textTheme.titleMedium),
            ),
            if (acc.email != null)
              Center(child: Text(acc.email!, style: theme.textTheme.bodySmall)),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción de autor',
                border: OutlineInputBorder(),
              ),
              onChanged: acc.setAuthorDescription,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text(acc.account == null ? 'Conectar Google' : 'Cambiar cuenta'),
                  onPressed: () async {
                    await acc.signInWithGoogle();
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(width: 12),
                if (acc.account != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    onPressed: () async {
                      await acc.signOutGoogle();
                      if (mounted) setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Subir respaldo'),
                  onPressed: acc.account == null
                      ? null
                      : () async {
                    setState(() => _busy = true);
                    try {
                      final stories = await LocalStorageService.getStories();
                      await cloud.uploadAll(account: acc, stories: stories);
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
                  },
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Restaurar respaldo'),
                  onPressed: acc.account == null
                      ? null
                      : () async {
                    setState(() => _busy = true);
                    try {
                      await cloud.restoreAll(account: acc);
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
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
