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
  const PdfPreviewScreen({super.key, required this.story});

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
      italic: await PdfGoogleFonts.robotoItalic(),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr,
          orientation: pw.PageOrientation.portrait,
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(story.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            if (story.description.isNotEmpty)
              pw.Text(story.description, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            pw.Divider(),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          if (story.chapters.isEmpty) {
            widgets.add(pw.Text('Sin capítulos.', style: const pw.TextStyle(fontSize: 14)));
          } else {
            for (int i = 0; i < story.chapters.length; i++) {
              final ch = story.chapters[i];
              widgets.addAll([
                pw.SizedBox(height: 12),
                pw.Text(
                  '${i + 1}. ${ch.title.isEmpty ? 'Capítulo' : ch.title}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(ch.content, style: const pw.TextStyle(fontSize: 12)),
              ]);
            }
          }
          return widgets;
        },
      ),
    );

    return await doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar PDF')),
      body: PdfPreview(
        build: (_) => _buildPdf(),
        canChangePageFormat: true,
        canChangeOrientation: true,
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}

