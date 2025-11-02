import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';

class ImageApiService {
  // Modelos en orden de prueba (puedes ajustar)
  static const List<String> _models = [
    'stabilityai/sdxl-turbo',
    'stabilityai/stable-diffusion-2-1',
    'black-forest-labs/FLUX.1-schnell',
  ];

  static Future<String?> generateImage(String prompt) async {
    final apiKey = await LocalStorageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      print('HF API key vacía. Configúrala en Settings.');
      return null;
    }

    for (final model in _models) {
      final url = 'https://api-inference.huggingface.co/models/$model';
      print('Llamando modelo: $model');

      try {
        final resp = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'image/png', // pedimos bytes PNG
          },
          body: jsonEncode({
            'inputs': prompt,
            'options': {'wait_for_model': true},
          }),
        );

        print('HF STATUS ($model): ${resp.statusCode}');

        if (resp.statusCode == 200) {
          // Éxito: devolvemos base64 de la imagen
          return base64Encode(resp.bodyBytes);
        }

        if (resp.statusCode == 503) {
          // Cold start: espera breve y reintenta una vez
          await Future.delayed(const Duration(seconds: 2));
          final retry = await http.post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'image/png',
            },
            body: jsonEncode({
              'inputs': prompt,
              'options': {'wait_for_model': true},
            }),
          );
          if (retry.statusCode == 200) {
            return base64Encode(retry.bodyBytes);
          } else {
            print('Retry falló ($model): ${retry.statusCode} ${retry.body}');
          }
        } else if (resp.statusCode == 404) {
          // Modelo no disponible o sin acceso; probamos el siguiente
          print('404 Not Found en $model, probando siguiente...');
          continue;
        } else {
          // Otros errores: imprime cuerpo por si viene JSON explicativo
          print('Error $model -> ${resp.statusCode}: ${resp.body}');
          // Sigue al siguiente modelo
          continue;
        }
      } catch (e) {
        print('Excepción en $model: $e');
        // Probamos siguiente modelo
        continue;
      }
    }

    // Si ninguno funcionó:
    print('Ningún modelo respondió correctamente. Verifica acceso/terms del modelo y tu token.');
    return null;
  }
}

