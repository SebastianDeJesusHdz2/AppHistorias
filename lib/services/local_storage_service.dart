import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/story.dart';

class LocalStorageService {
  static const _appBox = 'appBox';
  static const _storiesKey = 'stories';

  static const _prefsBox = 'prefsBox';

  static const _apiKeyBox = 'apiKeyBox';
  static const _apiKeyField = 'apiKey';
  static Future<void> saveStories(List<Story> stories) async {
    final box = await Hive.openBox(_appBox);
    final jsonList = stories.map((s) => s.toMap()).toList();
    await box.put(_storiesKey, jsonEncode(jsonList));
  }

  static Future<List<Story>> getStories() async {
    final box = await Hive.openBox(_appBox);
    final raw = box.get(_storiesKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((m) => Story.fromMap(m)).toList();
  }

  static Future<void> clearStoriesOnly() async {
    try {
      final box = await Hive.openBox(_appBox);
      await box.delete(_storiesKey);
    } catch (_) {}
  }

  static Future<void> saveApiKey(String apiKey) async {
    final b = await Hive.openBox(_apiKeyBox);
    await b.put(_apiKeyField, apiKey);
  }

  static Future<String?> getApiKey() async {
    final b = await Hive.openBox(_apiKeyBox);
    return b.get(_apiKeyField) as String?;
  }

  static Future<void> clearApiKeyBox() async {
    try {
      final b = await Hive.openBox(_apiKeyBox);
      await b.clear();
    } catch (_) {}
  }

  static Future<void> setPrefBool(String key, bool value) async {
    final box = await Hive.openBox(_prefsBox);
    await box.put(key, value);
  }

  static Future<bool?> getPrefBool(String key) async {
    final box = await Hive.openBox(_prefsBox);
    return box.get(key) as bool?;
  }

  static Future<Directory> _docsDir() async {
    if (kIsWeb) {
      final tmp = Directory.systemTemp.createTemp('apphistorias_web_');
      return tmp;
    }
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory> _imagesDir() async {
    final base = await _docsDir();
    final d = Directory(p.join(base.path, 'images'));
    if (!(await d.exists())) await d.create(recursive: true);
    return d;
  }

  static Future<String> copyImageToAppDir(String sourcePath) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw FileSystemException('Origen no existe', sourcePath);
    }
    final images = await _imagesDir();
    final ext = _ifEmpty(p.extension(sourcePath), '.jpg');
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(images.path, fileName));
    await dest.writeAsBytes(await src.readAsBytes(), flush: true);
    return dest.path;
  }

  static Future<String> saveBase64ToImage(String base64Str, {String ext = '.png'}) async {
    final images = await _imagesDir();
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = File(p.join(images.path, fileName));
    final bytes = base64Decode(base64Str);
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  static Future<String> downloadImageToAppDir(Uri url) async {
    if (kIsWeb) {
      throw UnsupportedError('Descarga directa no soportada en Web');
    }
    final client = HttpClient();
    final req = await client.getUrl(url);
    final res = await req.close();
    final bytes = await consolidateHttpClientResponseBytes(res);
    final images = await _imagesDir();
    final ext = _ifEmpty(p.extension(url.path), '.jpg');
    final dest = File(p.join(images.path, 'img_${DateTime.now().millisecondsSinceEpoch}$ext'));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  static Future<void> clearAllData() async {
    try {
      final app = await Hive.openBox(_appBox);
      await app.clear();
    } catch (_) {}
    try {
      final api = await Hive.openBox(_apiKeyBox);
      await api.clear();
    } catch (_) {}
    try {
      final prefs = await Hive.openBox(_prefsBox);
      await prefs.clear();
    } catch (_) {}
    await clearImagesDir();
  }

  static Future<void> clearImagesDir() async {
    try {
      final dir = await _imagesDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await (await _imagesDir()).create(recursive: true);
    } catch (_) {}
  }
}

String _ifEmpty(String value, String repl) => value.isEmpty ? repl : value;

