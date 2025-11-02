// lib/screens/pdf_preview_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/story.dart';
import '../models/chapter.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Story story;
  final int? chapterIndex; // si se pasa, renderiza solo ese capítulo con numeración real

  const PdfPreviewScreen({
    super.key,
    required this.story,
    this.chapterIndex,
  });

  Future<pw.ThemeData> _pdfTheme() async {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
      italic: await PdfGoogleFonts.robotoItalic(),
    );
  }

  // Genera el contenido de capítulos.
  // baseIndex indica desde qué índice global numerar (0-based).
  List<pw.Widget> _buildChapterWidgets(List<Chapter> chapters, {int baseIndex = 0}) {
    final widgets = <pw.Widget>[];

    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final ordinal = baseIndex + i + 1; // numeración real basada en el orden global
      final capTitle =
      ch.title.trim().isEmpty ? 'Capítulo $ordinal' : 'Capítulo $ordinal. ${ch.title.trim()}';

      widgets.add(pw.Header(level: 1, text: capTitle));

      final content = ch.content.trim().isEmpty ? '(Sin contenido)' : ch.content.trim();
      for (final line in content.split('\n')) {
        final t = line.trim();
        widgets.add(t.isEmpty ? pw.SizedBox(height: 6) : pw.Paragraph(text: t));
      }

      widgets.add(pw.SizedBox(height: 10));
    }

    if (widgets.isEmpty) {
      widgets.add(pw.Paragraph(text: 'Sin capítulos.'));
    }

    return widgets;
  }

  Future<Uint8List> _buildDocument(PdfPageFormat format) async {
    final theme = await _pdfTheme();
    final pdf = pw.Document();

    // Si chapterIndex es nulo se renderiza toda la historia; si no, sólo ese capítulo.
    final isSingle = chapterIndex != null;
    final chapters = isSingle
        ? [story.chapters[chapterIndex!.clamp(0, story.chapters.length - 1)]]
        : story.chapters;

    // baseIndex refleja la posición real del primer capítulo que se imprime.
    final baseIndex = isSingle ? chapterIndex!.clamp(0, story.chapters.length - 1) : 0;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: format,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr,
          orientation: pw.PageOrientation.portrait,
        ),
        // Encabezado solo en la primera página para evitar duplicados.
        header: (ctx) => ctx.pageNumber == 1
            ? pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              story.title.trim().isEmpty ? 'Historia' : story.title.trim(),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (story.description.trim().isNotEmpty)
              pw.Text(
                story.description.trim(),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            pw.SizedBox(height: 6),
            pw.Divider(),
          ],
        )
            : pw.SizedBox.shrink(),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        // MultiPage fluye todo el contenido y respeta la paginación automática.
        build: (ctx) => _buildChapterWidgets(chapters, baseIndex: baseIndex),
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = chapterIndex != null;
    final title = isSingle ? 'Vista previa PDF (Capítulo)' : 'Vista previa PDF (Historia)';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (format) => _buildDocument(format), // Integración con PdfPreview de printing
        canChangePageFormat: true,
        canChangeOrientation: true,
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: isSingle ? 'capitulo.pdf' : 'historia.pdf',
      ),
    );
  }
}
