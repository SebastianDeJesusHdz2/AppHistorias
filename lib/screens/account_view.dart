import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:apphistorias/services/account_service.dart';

typedef AsyncVoidCallback = Future<void> Function();

class AccountView extends StatelessWidget {
  final bool busy;
  final AccountService account;
  final TextEditingController nameController;
  final TextEditingController descController;

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescChanged;

  final AsyncVoidCallback onPickPhoto;
  final AsyncVoidCallback onConnectGoogle;
  final AsyncVoidCallback? onSignOutGoogle;
  final AsyncVoidCallback onClearProfile;
  final AsyncVoidCallback? onUploadBackup;
  final AsyncVoidCallback? onRestoreBackup;

  const AccountView({
    super.key,
    required this.busy,
    required this.account,
    required this.nameController,
    required this.descController,
    required this.onNameChanged,
    required this.onDescChanged,
    required this.onPickPhoto,
    required this.onConnectGoogle,
    required this.onSignOutGoogle,
    required this.onClearProfile,
    required this.onUploadBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.backgroundGradient,
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.9),
                  radius: 1.2,
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftLeafPainter(palette),
              ),
            ),
          ),
          Column(
            children: [
              _PaperTopBar(
                title: 'Perfil del autor',
                palette: palette,
              ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: busy,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                        children: [
                          _AvatarSection(
                            palette: palette,
                            account: account,
                            onPickPhoto: onPickPhoto,
                          ),
                          const SizedBox(height: 20),
                          _GlassCard(
                            palette: palette,
                            child: Column(
                              children: [
                                _TextFieldPaper(
                                  controller: nameController,
                                  label: 'Nombre de usuario',
                                  helper:
                                  'Se mostrará en la app. Si lo dejas vacío, se usará el nombre de Google.',
                                  icon: Icons.badge_outlined,
                                  palette: palette,
                                  maxLines: 1,
                                  onChanged: onNameChanged,
                                ),
                                const SizedBox(height: 12),
                                _TextFieldPaper(
                                  controller: descController,
                                  label: 'Descripción de autor',
                                  icon: Icons.description_outlined,
                                  palette: palette,
                                  maxLines: 3,
                                  onChanged: onDescChanged,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.login),
                                  label: Text(
                                    account.account == null
                                        ? 'Conectar Google'
                                        : 'Cambiar cuenta',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: palette.ribbon,
                                    foregroundColor: palette.onRibbon,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(color: palette.edge),
                                    ),
                                    elevation: 5,
                                    shadowColor:
                                    Colors.black.withOpacity(0.25),
                                  ),
                                  onPressed: () => onConnectGoogle(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (onSignOutGoogle != null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Cerrar sesión'),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: palette.edge),
                                      foregroundColor: palette.ink,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => onSignOutGoogle!(),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            label: const Text('Borrar datos de perfil'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: palette.edge),
                              foregroundColor: palette.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => onClearProfile(),
                          ),
                          const SizedBox(height: 18),
                          _GlassCard(
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
                                  onPressed: onUploadBackup == null
                                      ? null
                                      : () => onUploadBackup!(),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('Restaurar respaldo'),
                                  onPressed: onRestoreBackup == null
                                      ? null
                                      : () => onRestoreBackup!(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (busy)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: ColoredBox(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final _PaperPalette palette;
  final AccountService account;
  final AsyncVoidCallback onPickPhoto;

  const _AvatarSection({
    required this.palette,
    required this.account,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(80),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: palette.paper.withOpacity(0.9),
                    backgroundImage: account.photoBytes != null
                        ? MemoryImage(account.photoBytes!)
                        : null,
                    child: account.photoBytes == null
                        ? Icon(
                      Icons.person,
                      size: 48,
                      color: palette.inkMuted,
                    )
                        : null,
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
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: palette.onRibbon),
                        onPressed: () => onPickPhoto(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            account.displayName,
            style: TextStyle(
              color: palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (account.email != null)
          Center(
            child: Text(
              account.email!,
              style: TextStyle(color: palette.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _TextFieldPaper extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helper;
  final IconData icon;
  final _PaperPalette palette;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _TextFieldPaper({
    required this.controller,
    required this.label,
    required this.icon,
    required this.palette,
    required this.maxLines,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: palette.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.inkMuted),
        helperText: helper,
        helperStyle:
        helper != null ? TextStyle(color: palette.inkMuted) : null,
        prefixIcon: Icon(icon, color: palette.inkMuted),
        filled: true,
        fillColor: palette.paper.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.edge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.ribbon, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _PaperTopBar extends StatelessWidget {
  final String title;
  final _PaperPalette palette;

  const _PaperTopBar({
    required this.title,
    required this.palette,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final _PaperPalette palette;

  const _GlassCard({
    required this.child,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.paper.withOpacity(0.86),
                  palette.paper.withOpacity(0.68),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftLeafPainter extends CustomPainter {
  final _PaperPalette palette;

  _SoftLeafPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.edge.withOpacity(0.18),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathTop = Path()
      ..moveTo(0, size.height * 0.02)
      ..quadraticBezierTo(
          size.width * 0.35, size.height * 0.0, size.width * 0.7, size.height * 0.08)
      ..quadraticBezierTo(
          size.width * 0.42, size.height * 0.18, 0, size.height * 0.14)
      ..close();
    canvas.drawPath(pathTop, paintTop);

    final paintSide = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.edge.withOpacity(0.26),
          Colors.transparent,
        ],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathSide = Path()
      ..moveTo(size.width, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.4,
          size.width * 0.62, size.height * 0.56)
      ..quadraticBezierTo(
          size.width * 0.86, size.height * 0.7, size.width, size.height * 0.76)
      ..close();
    canvas.drawPath(pathSide, paintSide);

    final paintBottom = Paint()
      ..shader = LinearGradient(
        colors: [
          palette.paper.withOpacity(0.0),
          palette.edge.withOpacity(0.22),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathBottom = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.87,
          size.width * 0.6, size.height * 0.93)
      ..quadraticBezierTo(
          size.width * 0.32, size.height * 1.02, 0, size.height * 0.98)
      ..close();
    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant _SoftLeafPainter oldDelegate) => false;
}

class _PaperPalette {
  final BuildContext context;

  _PaperPalette._(this.context);

  static _PaperPalette of(BuildContext context) => _PaperPalette._(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get paper =>
      isDark ? const Color(0xFF3C342B) : const Color(0xFFF1E3CC);
  Color get edge =>
      isDark ? const Color(0xFF5A4C3E) : const Color(0xFFCBB38D);
  Color get ink =>
      isDark ? const Color(0xFFF0E6D6) : const Color(0xFF2F2A25);
  Color get inkMuted =>
      isDark ? const Color(0xFFD8CCBA) : const Color(0xFF5B5249);

  Color get ribbon =>
      isDark ? const Color(0xFF9A4A4A) : const Color(0xFFB35B4F);
  Color get onRibbon => Colors.white;

  Color get waxSeal =>
      isDark ? const Color(0xFF7C2D2D) : const Color(0xFFA93A3A);

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
