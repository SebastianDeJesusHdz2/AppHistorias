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
  final _nameCtrl = TextEditingController(); // NUEVO
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final acc = context.read<AccountService>();
    _descCtrl.text = acc.authorDescription;
    _nameCtrl.text = acc.customUserName; // NUEVO
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose(); // NUEVO
    super.dispose();
  }

  Future<void> _confirmAndClear(AccountService acc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar datos de perfil'),
        content: const Text(
          'Se eliminarán nombre de usuario, descripción y foto guardados localmente. '
              'Tus historias permanecerán intactas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok == true) {
      await acc.clearProfileData();
      if (!mounted) return;
      _descCtrl.clear();
      _nameCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos de perfil borrados.')),
      );
      setState(() {}); // refresca avatar/nombre
    }
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
            Center(child: Text(acc.displayName, style: theme.textTheme.titleMedium)),
            if (acc.email != null)
              Center(child: Text(acc.email!, style: theme.textTheme.bodySmall)),

            const SizedBox(height: 20),
            // NUEVO: nombre de usuario editable (prioridad sobre Google)
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                helperText: 'Se mostrará en la app. Si lo dejas vacío, se usará el nombre de Google.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: acc.setCustomUserName,
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción de autor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
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
                const SizedBox(width: 12),
                // NUEVO: botón borrar datos de perfil locales
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('Borrar datos de perfil'),
                  onPressed: () => _confirmAndClear(acc),
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
