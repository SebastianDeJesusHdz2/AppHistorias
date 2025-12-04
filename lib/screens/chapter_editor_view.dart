import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chapter.dart';

class ChapterEditorView extends StatelessWidget {
  final List<Chapter> chapters;
  final VoidCallback onAddChapter;
  final void Function(int index) onEditChapter;
  final void Function(int index) onDeleteChapter;
  final void Function(int oldIndex, int newIndex) onReorderChapters;
  final VoidCallback onPreviewAllPdf;
  final void Function(int index) onPreviewOnePdf;

  const ChapterEditorView({
    super.key,
    required this.chapters,
    required this.onAddChapter,
    required this.onEditChapter,
    required this.onDeleteChapter,
    required this.onReorderChapters,
    required this.onPreviewAllPdf,
    required this.onPreviewOnePdf,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _PaperPalette.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Capítulos'),
        actions: [
          IconButton(
            tooltip: 'Exportar todo a PDF',
            onPressed: onPreviewAllPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            onPressed: onAddChapter,
            icon: const Icon(Icons.add),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: palette.appBarGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
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
                    center: const Alignment(0.0, -0.7),
                    radius: 1.3,
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, 1.0),
                    radius: 1.4,
                    colors: [
                      Colors.black.withOpacity(0.14),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: chapters.isEmpty
                ? Center(
              child: _GlassCard(
                palette: palette,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Text(
                  'Sin capítulos. Agrega el primero.',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: chapters.length,
              onReorder: onReorderChapters,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final ch = chapters[index];
                return _ChapterCard(
                  key: ValueKey(ch.id ?? const Uuid().v4()),
                  chapter: ch,
                  index: index,
                  palette: palette,
                  onTap: () => onEditChapter(index),
                  onEdit: () => onEditChapter(index),
                  onDelete: () => onDeleteChapter(index),
                  onPreviewPdf: () => onPreviewOnePdf(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter chapter;
  final int index;
  final _PaperPalette palette;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPreviewPdf;

  const _ChapterCard({
    super.key,
    required this.chapter,
    required this.index,
    required this.palette,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final title =
    chapter.title.trim().isEmpty ? 'Capítulo ${index + 1}' : chapter.title;
    final rawContent = chapter.content.trim();
    final preview =
    rawContent.length > 80 ? '${rawContent.substring(0, 80)}…' : rawContent;

    return _GlassCard(
      palette: palette,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            color: palette.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            preview.isEmpty ? 'Sin contenido' : preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.inkMuted,
              height: 1.25,
            ),
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Vista previa PDF',
              onPressed: onPreviewPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              color: palette.ink,
            ),
            IconButton(
              tooltip: 'Editar capítulo',
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              color: palette.ink,
            ),
            IconButton(
              tooltip: 'Eliminar capítulo',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever),
              color: Colors.red,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: palette.inkMuted,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final _PaperPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({
    required this.palette,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 0.9,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.paper.withOpacity(0.92),
                  palette.paper.withOpacity(0.76),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
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
