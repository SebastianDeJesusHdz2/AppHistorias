import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_storage_service.dart';
import '../main.dart'; // StoryProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final apiKeyController = TextEditingController();
  bool _loading = true;
  bool _hideKey = true;

  bool _showDeleteHint = true;
  bool _confirmBeforeDelete = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final key = await LocalStorageService.getApiKey();
    final showHint = await LocalStorageService.getPrefBool('showDeleteHint') ?? true;
    final confirmDel = await LocalStorageService.getPrefBool('confirmBeforeDelete') ?? true;

    if (!mounted) return;
    setState(() {
      apiKeyController.text = key ?? '';
      _showDeleteHint = showHint;
      _confirmBeforeDelete = confirmDel;
      _loading = false;
    });
  }

  Future<void> _saveApiKey() async {
    await LocalStorageService.saveApiKey(apiKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key guardada localmente.')));
    Navigator.pop(context, true);
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _clearCachesOnly() async {
    final ok = await _confirm(
      'Borrar cachés',
      'Se borrarán la API key y las imágenes locales de la aplicación. Tus historias permanecerán intactas.',
    );
    if (!ok) return;

    await LocalStorageService.clearApiKeyBox();
    await LocalStorageService.clearImagesDir();

    if (!mounted) return;
    setState(() => apiKeyController.clear());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cachés limpiadas. Historias conservadas.')));
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historias eliminadas.')));
    Navigator.pop(context, true);
  }

  Future<void> _toggleShowDeleteHint(bool v) async {
    setState(() => _showDeleteHint = v);
    await LocalStorageService.setPrefBool('showDeleteHint', v);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleConfirmBeforeDelete(bool v) async {
    setState(() => _confirmBeforeDelete = v);
    await LocalStorageService.setPrefBool('confirmBeforeDelete', v);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Nuevo: solo acceso a la configuración de perfil
          const _SectionTitle('Perfil'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar perfil del autor'),
                subtitle: const Text('Foto, nombre (de Google) y descripción'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () => Navigator.of(context).pushNamed('/account'),
              ),
            ),
          ),

          const _SectionTitle('API externa'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: apiKeyController,
                      obscureText: _hideKey,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'API key',
                        helperText: 'Se guarda localmente con Hive. Puedes limpiarla abajo.',
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hideKey = !_hideKey),
                          icon: Icon(_hideKey ? Icons.visibility_off : Icons.visibility),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveApiKey,
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('Guardar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => apiKeyController.clear()),
                            icon: const Icon(Icons.cleaning_services_outlined),
                            label: const Text('Limpiar campo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const _SectionTitle('Preferencias'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Mostrar consejo de borrado'),
                    value: _showDeleteHint,
                    onChanged: _toggleShowDeleteHint,
                    subtitle: const Text('“Desliza hacia la izquierda para eliminar”'),
                    secondary: const Icon(Icons.swipe_left_alt_rounded),
                  ),
                  const Divider(height: 0),
                  SwitchListTile.adaptive(
                    title: const Text('Confirmar antes de eliminar'),
                    value: _confirmBeforeDelete,
                    onChanged: _toggleConfirmBeforeDelete,
                    subtitle: const Text('Diálogo de confirmación antes de borrar'),
                    secondary: const Icon(Icons.warning_amber_rounded),
                  ),
                ],
              ),
            ),
          ),

          const _SectionTitle('Datos locales'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: Colors.teal),
                    title: const Text('Borrar cachés (API + imágenes)'),
                    subtitle: const Text('No elimina historias. Limpia API key y copias de imágenes.'),
                    trailing: FilledButton(onPressed: _clearCachesOnly, child: const Text('Limpiar')),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Borrar todas las historias'),
                    subtitle: const Text('Acción destructiva. Las historias no se pueden recuperar.'),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                      onPressed: _clearStoriesOnly,
                      child: const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

