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

  // Nuevo: indica si ya hay una API key guardada en el dispositivo
  bool _hasStoredApiKey = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // OJO: aquí solo comprobamos si existe, no la mostramos
    final key = await LocalStorageService.getApiKey();
    final showHint =
        await LocalStorageService.getPrefBool('showDeleteHint') ?? true;
    final confirmDel =
        await LocalStorageService.getPrefBool('confirmBeforeDelete') ?? true;

    if (!mounted) return;
    setState(() {
      _hasStoredApiKey = (key != null && key.isNotEmpty);
      _showDeleteHint = showHint;
      _confirmBeforeDelete = confirmDel;
      _loading = false;
    });
  }

  Future<void> _saveApiKey() async {
    // Nunca hacemos print de la API key
    final value = apiKeyController.text.trim();

    if (value.isEmpty) {
      // Campo vacío: se interpreta como “eliminar API key”
      await LocalStorageService.clearApiKeyBox();
      if (!mounted) return;
      setState(() {
        _hasStoredApiKey = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key eliminada de este dispositivo.'),
        ),
      );
    } else {
      // Guardar / reemplazar API key
      await LocalStorageService.saveApiKey(value);
      if (!mounted) return;
      setState(() {
        _hasStoredApiKey = true;
        apiKeyController.clear(); // limpiamos el campo después de guardar
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key guardada de forma segura en este dispositivo.'),
        ),
      );
    }

    // Cerramos la pantalla avisando al caller de que hubo cambios
    Navigator.pop(context, true);
  }

  Future<bool> _confirm(String title, String message) async {
    final palette = _PaperPalette.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.paper,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: palette.ink)),
        content: Text(message,
            style:
            TextStyle(color: palette.inkMuted, height: 1.25)),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: palette.ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: palette.waxSeal),
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
      'Se borrarán la API key y las imágenes locales de la aplicación. Tus historias permanecerán intactas.',
    );
    if (!ok) return;

    await LocalStorageService.clearApiKeyBox();
    await LocalStorageService.clearImagesDir();

    if (!mounted) return;
    setState(() {
      apiKeyController.clear();
      _hasStoredApiKey = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cachés limpiadas. Historias conservadas.')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historias eliminadas.')),
    );
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
    final palette = _PaperPalette.of(context);

    return Scaffold(
      // Fondo estilo pergamino
      body: Stack(
        children: [
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
              _PaperTopBar(
                title: 'Configuración',
                palette: palette,
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _SectionTitle('Perfil', palette: palette),
                    _PaperCard(
                      palette: palette,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: ListTile(
                        leading:
                        Icon(Icons.person, color: palette.ink),
                        title: Text(
                          'Editar perfil del autor',
                          style: TextStyle(
                            color: palette.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Foto, nombre (de Google) y descripción',
                          style:
                          TextStyle(color: palette.inkMuted),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: palette.inkMuted,
                        ),
                        onTap: () => Navigator.of(context)
                            .pushNamed('/account'),
                      ),
                    ),

                    _SectionTitle('API externa', palette: palette),
                    _PaperCard(
                      palette: palette,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: apiKeyController,
                            obscureText: _hideKey,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType:
                            TextInputType.visiblePassword,
                            style:
                            TextStyle(color: palette.ink),
                            decoration: InputDecoration(
                              labelText: 'API key',
                              labelStyle: TextStyle(
                                  color: palette.inkMuted),
                              helperText: _hasStoredApiKey
                                  ? 'Ya hay una API key guardada de forma segura. Pega una nueva para reemplazarla o deja el campo vacío y pulsa "Guardar" para eliminarla.'
                                  : 'Se guardará solo en este dispositivo. No se envía a ningún servidor propio.',
                              helperStyle: TextStyle(
                                  color: palette.inkMuted),
                              prefixIcon: Icon(
                                Icons.vpn_key,
                                color: palette.inkMuted,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                        () => _hideKey = !_hideKey),
                                icon: Icon(
                                  _hideKey
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: palette.inkMuted,
                                ),
                              ),
                              filled: true,
                              fillColor: palette.paper
                                  .withOpacity(0.7),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: palette.edge),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: palette.ribbon,
                                    width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                    palette.ribbon,
                                    foregroundColor:
                                    palette.onRibbon,
                                  ),
                                  onPressed: _saveApiKey,
                                  icon: const Icon(
                                      Icons.save_alt_rounded),
                                  label: const Text('Guardar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: palette.edge),
                                    foregroundColor:
                                    palette.ink,
                                  ),
                                  onPressed: () => setState(() =>
                                      apiKeyController.clear()),
                                  icon: const Icon(Icons
                                      .cleaning_services_outlined),
                                  label:
                                  const Text('Limpiar campo'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _SectionTitle('Preferencias', palette: palette),
                    _PaperCard(
                      palette: palette,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            title: Text(
                              'Mostrar consejo de borrado',
                              style: TextStyle(
                                  color: palette.ink),
                            ),
                            value: _showDeleteHint,
                            onChanged: _toggleShowDeleteHint,
                            subtitle: Text(
                              '“Desliza hacia la izquierda para eliminar”',
                              style: TextStyle(
                                  color: palette.inkMuted),
                            ),
                            secondary: Icon(
                              Icons.swipe_left_alt_rounded,
                              color: palette.inkMuted,
                            ),
                          ),
                          Divider(
                              height: 0,
                              color: palette.edge),
                          SwitchListTile.adaptive(
                            title: Text(
                              'Confirmar antes de eliminar',
                              style: TextStyle(
                                  color: palette.ink),
                            ),
                            value: _confirmBeforeDelete,
                            onChanged:
                            _toggleConfirmBeforeDelete,
                            subtitle: Text(
                              'Diálogo de confirmación antes de borrar',
                              style: TextStyle(
                                  color: palette.inkMuted),
                            ),
                            secondary: Icon(
                              Icons.warning_amber_rounded,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _SectionTitle('Datos locales', palette: palette),
                    _PaperCard(
                      palette: palette,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.cleaning_services_rounded,
                              color: Colors.teal,
                            ),
                            title: Text(
                              'Borrar cachés (API + imágenes)',
                              style: TextStyle(
                                color: palette.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'No elimina historias. Limpia API key y copias de imágenes.',
                              style: TextStyle(
                                  color: palette.inkMuted),
                            ),
                            trailing: FilledButton(
                              onPressed: _clearCachesOnly,
                              child: const Text('Limpiar'),
                            ),
                          ),
                          Divider(
                              height: 0,
                              color: palette.edge),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Borrar todas las historias',
                              style: TextStyle(
                                color: palette.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Acción destructiva. Las historias no se pueden recuperar.',
                              style: TextStyle(
                                  color: palette.inkMuted),
                            ),
                            trailing: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                palette.waxSeal,
                                foregroundColor:
                                Colors.white,
                              ),
                              onPressed: _clearStoriesOnly,
                              child: const Text('Eliminar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets de estilo papel ----------

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
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final _PaperPalette palette;
  const _PaperCard({
    required this.child,
    required this.palette,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final _PaperPalette palette;
  const _SectionTitle(this.text, {required this.palette});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: palette.ink,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ------ Paleta pergamino (igual que en Home) ------
class _PaperPalette {
  final BuildContext context;
  _PaperPalette._(this.context);
  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  // Colores principales
  Color get paper =>
      isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge =>
      isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink =>
      isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted =>
      isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  // Cinta / botones principales
  Color get ribbon =>
      isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  // “Sello de cera” para acciones destructivas
  Color get waxSeal =>
      isDark ? const Color(0xFF7C2D2D) : const Color(0xFFA93A3A);

  // Gradientes base
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
