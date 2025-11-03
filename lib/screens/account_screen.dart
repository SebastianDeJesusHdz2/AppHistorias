import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/services/cloud_sync_service.dart';
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/main.dart'; // StoryProvider

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _descCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
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
    final palette = _PaperPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Borrar datos de perfil', style: TextStyle(color: palette.ink)),
        content: Text(
          'Se eliminarán nombre de usuario, descripción y foto guardados localmente. Tus historias permanecerán intactas.',
          style: TextStyle(color: palette.inkMuted, height: 1.25),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: palette.ink))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.waxSeal),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccountService>();
    final cloud = context.read<CloudSyncService>();
    final stories = context.read<StoryProvider>(); // para refrescar lista tras restaurar
    final palette = _PaperPalette.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo pergamino
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
          // Viñeta radial suave
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.6),
                    radius: 1.2,
                    colors: [Colors.black.withOpacity(0.06), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          Column(
            children: [
              _PaperTopBar(title: 'Perfil del autor', palette: palette),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _busy,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Marco tipo camafeo
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: palette.paper,
                                shape: BoxShape.circle,
                                border: Border.all(color: palette.edge, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: palette.paper,
                                backgroundImage: acc.photoBytes != null ? MemoryImage(acc.photoBytes!) : null,
                                child: acc.photoBytes == null
                                    ? Icon(Icons.person, size: 48, color: palette.inkMuted)
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: palette.ribbon,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: palette.edge, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: palette.onRibbon),
                                  onPressed: () async => acc.setPhotoFromPicker(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          acc.displayName,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (acc.email != null)
                        Center(
                          child: Text(
                            acc.email!,
                            style: TextStyle(color: palette.inkMuted),
                          ),
                        ),
                      const SizedBox(height: 20),

                      _PaperCard(
                        palette: palette,
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              style: TextStyle(color: palette.ink),
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario',
                                labelStyle: TextStyle(color: palette.inkMuted),
                                helperText:
                                'Se mostrará en la app. Si lo dejas vacío, se usará el nombre de Google.',
                                helperStyle: TextStyle(color: palette.inkMuted),
                                prefixIcon: Icon(Icons.badge_outlined, color: palette.inkMuted),
                                filled: true,
                                fillColor: palette.paper.withOpacity(0.7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: palette.edge),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: palette.ribbon, width: 2),
                                ),
                              ),
                              onChanged: acc.setCustomUserName,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _descCtrl,
                              maxLines: 3,
                              style: TextStyle(color: palette.ink),
                              decoration: InputDecoration(
                                labelText: 'Descripción de autor',
                                labelStyle: TextStyle(color: palette.inkMuted),
                                prefixIcon: Icon(Icons.description_outlined, color: palette.inkMuted),
                                filled: true,
                                fillColor: palette.paper.withOpacity(0.7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: palette.edge),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: palette.ribbon, width: 2),
                                ),
                              ),
                              onChanged: acc.setAuthorDescription,
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.login),
                              label: Text(acc.account == null ? 'Conectar Google' : 'Cambiar cuenta'),
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.ribbon,
                                foregroundColor: palette.onRibbon,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: palette.edge),
                                ),
                              ),
                              onPressed: () async {
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
                                    SnackBar(content: Text('Error de Google Sign-In (código ${result.error}). Revisa SHA y OAuth.')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Inicio cancelado por el usuario.')),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (acc.account != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text('Cerrar sesión'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: palette.edge),
                                  foregroundColor: palette.ink,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  await acc.signOutGoogle();
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Borrar datos de perfil'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.edge),
                          foregroundColor: palette.ink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmAndClear(acc),
                      ),
                      const SizedBox(height: 16),

                      _PaperCard(
                        palette: palette,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Subir respaldo'),
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.ribbon,
                                foregroundColor: palette.onRibbon,
                              ),
                              onPressed: acc.account == null
                                  ? null
                                  : () async {
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
                                  // Recarga el provider para reflejar historias restauradas
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
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets y paleta “papel” ----------

class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;
  const _PaperTopBar({required this.title, required this.palette});

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
        border: Border(bottom: BorderSide(color: palette.edge, width: 1)),
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
          height: 60,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: palette.ink),
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Widget child;
  final _PaperPalette palette;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  const _PaperCard({
    required this.child,
    required this.palette,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);
  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Colores principales
  Color get paper => isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge => isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink => isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted => isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  // Cinta / primario
  Color get ribbon => isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  // “Sello de cera” destructivo
  Color get waxSeal => isDark ? const Color(0xFF7C2D2D) : const Color(0xFFA93A3A);

  // Gradientes
  List<Color> get backgroundGradient => isDark
      ? [const Color(0xFF2F2821), const Color(0xFF3A3027), const Color(0xFF2C261F)]
      : [const Color(0xFFF6ECD7), const Color(0xFFF0E1C8), const Color(0xFFE8D6B8)];

  List<Color> get appBarGradient => isDark
      ? [const Color(0xFF3B3229), const Color(0xFF362E25)]
      : [const Color(0xFFF7EBD5), const Color(0xFFF0E1C8)];
}
