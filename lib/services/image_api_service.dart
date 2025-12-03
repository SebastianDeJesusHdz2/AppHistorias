import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';

class ImageApiService {
  // Modelo de Gemini especializado en imágenes
  static const String _geminiImageModel = 'gemini-2.5-flash-image';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Genera una imagen con Gemini y la devuelve en Base64.
  static Future<String?> generateImage(String prompt) async {
    final apiKey = await LocalStorageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      print('Gemini API key vacía. Configúrala en Settings.');
      return null;
    }

    final url = '$_baseUrl/$_geminiImageModel:generateContent';
    print('Llamando modelo Gemini: $_geminiImageModel');

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          // Configuración opcional: puedes ajustar o eliminar este bloque
          'generationConfig': {
            // Solo queremos imagen en la respuesta
            'responseModalities': ['IMAGE'],
            'imageConfig': {
              // Ajusta según lo que necesites: 1:1, 16:9, 9:16, 4:3, etc.
              'aspectRatio': '1:1',
              // También puede ser '512x512', '2K', etc., según la doc.
              'imageSize': '1024x1024',
            },
          },
        }),
      );

      print('Gemini STATUS: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);

        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          print('Gemini no devolvió candidatos.');
          return null;
        }

        final content =
        candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          print('Gemini no devolvió partes en el contenido.');
          return null;
        }

        // Buscamos la primera parte que contenga imagen (inlineData / inline_data)
        for (final part in parts) {
          final inlineData = part['inlineData'] ?? part['inline_data'];
          if (inlineData != null && inlineData['data'] != null) {
            // 'data' ya es Base64 según la especificación del API
            final String base64Image = inlineData['data'];
            return base64Image;
          }
        }

        print('No se encontró imagen en la respuesta de Gemini.');
        return null;
      } else {
        // Otros errores: imprime cuerpo para depurar
        print('Error Gemini -> ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      print('Excepción llamando a Gemini: $e');
      return null;
    }
  }
}
