import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import 'package:path/path.dart' as p;
import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/models/story.dart';

class CloudSyncService {
  static const String appFolderName = 'AppHistorias';
  static const String backupFileName = 'backup.dat';

  String? _folderId;
  String? _backupFileId;

  Future<gdrive.DriveApi?> _drive(AccountService acc) async {
    final client = await acc.authenticatedHttpClient();
    if (client == null) return null;
    return gdrive.DriveApi(client);
  }

  Future<void> _ensureAppFolder(AccountService acc) async {
    final drive = await _drive(acc);
    if (drive == null) throw Exception('Inicia sesión con Google');

    final q =
        "name = '$appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final res = await drive.files.list(q: q, $fields: 'files(id, name)');
    if (res.files != null && res.files!.isNotEmpty) {
      _folderId = res.files!.first.id;
    } else {
      final folder = gdrive.File()
        ..name = appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      _folderId = (await drive.files.create(folder, $fields: 'id')).id;
    }
  }

  Future<void> _ensureHandles(AccountService acc) async {
    final drive = await _drive(acc);
    if (drive == null) throw Exception('Inicia sesión con Google');

    await _ensureAppFolder(acc);

    final q =
        "'$_folderId' in parents and name = '$backupFileName' and mimeType != 'application/vnd.google-apps.folder' and trashed = false";
    final res = await drive.files.list(q: q, $fields: 'files(id, name)');
    _backupFileId =
    res.files != null && res.files!.isNotEmpty ? res.files!.first.id : null;
  }

  Future<void> uploadAll({
    required AccountService account,
    required List<Story> stories,
  }) async {
    final drive = await _drive(account);
    if (drive == null) throw Exception('Inicia sesión con Google');

    await _ensureHandles(account);

    final imagesBase64 = _collectImageBlobs(stories);
    final profilePhotoBase64 = await _profilePhotoAsBase64(account);

    final payload = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'stories': stories.map((s) => s.toMap()).toList(),
      'profile': account.toProfileJson(),
      'profilePhoto': profilePhotoBase64,
      'images': imagesBase64,
    };

    final jsonStr = jsonEncode(payload);
    final jsonBytes = utf8.encode(jsonStr);
    final compressedBytes = gzip.encode(jsonBytes);

    final media =
    gdrive.Media(Stream.value(compressedBytes), compressedBytes.length);
    final file = gdrive.File()
      ..name = backupFileName
      ..parents = [_folderId!]
      ..mimeType = 'application/octet-stream';

    if (_backupFileId == null) {
      _backupFileId = (await drive.files.create(
        file,
        uploadMedia: media,
        $fields: 'id',
      ))
          .id;
    } else {
      await drive.files.update(
        gdrive.File()..mimeType = 'application/octet-stream',
        _backupFileId!,
        uploadMedia: media,
      );
    }
  }

  Future<void> restoreAll({required AccountService account}) async {
    final drive = await _drive(account);
    if (drive == null) throw Exception('Inicia sesión con Google');

    await _ensureHandles(account);
    if (_backupFileId == null) {
      throw Exception('No se encontró respaldo en Drive');
    }

    final media = await drive.files.get(
      _backupFileId!,
      downloadOptions: gdrive.DownloadOptions.fullMedia,
    ) as gdrive.Media;

    final compressed =
    await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
    final jsonBytes = gzip.decode(compressed);
    final decoded = jsonDecode(utf8.decode(jsonBytes));

    final root =
    Map<String, dynamic>.from(decoded as Map<dynamic, dynamic>);

    final imagesMapRaw =
    Map<String, dynamic>.from(root['images'] as Map? ?? {});
    final nameToLocalPath =
    await _restoreImagesFromBase64(imagesMapRaw);

    final storiesListRaw = (root['stories'] as List? ?? []);
    final storiesMaps = storiesListRaw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((m) => _patchImagePathsInMap(m, nameToLocalPath))
        .toList();
    final stories = storiesMaps.map((m) => Story.fromMap(m)).toList();
    await LocalStorageService.saveStories(stories);

    final profileRaw =
    Map<String, dynamic>.from(root['profile'] as Map? ?? {});
    await account.setAuthorDescription(
      (profileRaw['authorDescription'] as String?) ?? '',
    );
    await account.setCustomUserName(
      (profileRaw['customUserName'] as String?) ?? '',
    );

    final profilePhotoBase64 = root['profilePhoto'] as String?;
    if (profilePhotoBase64 != null && profilePhotoBase64.isNotEmpty) {
      final profilePath = await LocalStorageService.saveBase64ToImage(
        profilePhotoBase64,
        ext: '.png',
      );
      final box = await Hive.openBox('profile');
      await box.put('photoPath', profilePath);
      account.photoPath = profilePath;
      account.notifyListeners();
    }
  }

  Map<String, String> _collectImageBlobs(List<Story> stories) {
    final paths = <String>{};

    void collect(dynamic value) {
      if (value is String) {
        final ext = p.extension(value).toLowerCase();
        if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
          final file = File(value);
          if (file.existsSync()) paths.add(value);
        }
      } else if (value is Map) {
        for (final v in value.values) collect(v);
      } else if (value is List) {
        for (final v in value) collect(v);
      }
    }

    for (final s in stories) {
      collect(s.toMap());
    }

    final result = <String, String>{};
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      final b64 = base64Encode(bytes);
      final name = p.basename(path);
      result[name] = b64;
    }
    return result;
  }

  Future<String?> _profilePhotoAsBase64(AccountService account) async {
    final path = account.photoPath;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<Map<String, String>> _restoreImagesFromBase64(
      Map<String, dynamic> imagesMap,
      ) async {
    final Map<String, String> nameToPath = {};
    for (final entry in imagesMap.entries) {
      final name = entry.key;
      final b64 = entry.value;
      if (b64 is! String || b64.isEmpty) continue;

      final ext = p.extension(name).isEmpty ? '.png' : p.extension(name);
      final localPath =
      await LocalStorageService.saveBase64ToImage(b64, ext: ext);
      nameToPath[name] = localPath;
    }
    return nameToPath;
  }

  Map<String, dynamic> _patchImagePathsInMap(
      Map<String, dynamic> map,
      Map<String, String> nameToLocalPath,
      ) {
    dynamic patch(dynamic value) {
      if (value is String) {
        final baseName = p.basename(value);
        final newPath = nameToLocalPath[baseName];
        return newPath ?? value;
      } else if (value is Map) {
        return value.map((k, v) => MapEntry(k, patch(v)));
      } else if (value is List) {
        return value.map(patch).toList();
      }
      return value;
    }

    final patched = patch(map) as Map;
    return Map<String, dynamic>.from(patched as Map<dynamic, dynamic>);
  }
}
