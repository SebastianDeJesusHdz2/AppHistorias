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
  static const String imagesFolderName = 'images';
  static const String storiesFileName = 'stories.json';
  static const String profileFileName = 'profile.json';
  static const String profilePngName = 'profile.png';

  String? _folderId;
  String? _imagesFolderId;
  String? _storiesFileId;
  String? _profileFileId;
  String? _profilePngId;

  Future<gdrive.DriveApi?> _drive(AccountService acc) async {
    final client = await acc.authenticatedHttpClient();
    if (client == null) return null;
    return gdrive.DriveApi(client);
  }

  Future<void> _ensureAppFolder(AccountService acc) async {
    final drive = await _drive(acc);
    if (drive == null) {
      throw Exception('Inicia sesión con Google');
    }

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

  Future<void> _ensureImagesFolder(AccountService acc) async {
    final drive = await _drive(acc);
    if (drive == null) {
      throw Exception('Inicia sesión con Google');
    }

    await _ensureAppFolder(acc);

    final q =
        "'$_folderId' in parents and name = '$imagesFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";

    final res = await drive.files.list(q: q, $fields: 'files(id, name)');
    if (res.files != null && res.files!.isNotEmpty) {
      _imagesFolderId = res.files!.first.id;
    } else {
      final folder = gdrive.File()
        ..name = imagesFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [_folderId!];
      _imagesFolderId = (await drive.files.create(folder, $fields: 'id')).id;
    }
  }

  Future<void> _ensureHandles(AccountService acc) async {
    final drive = await _drive(acc);
    if (drive == null) {
      throw Exception('Inicia sesión con Google');
    }

    await _ensureAppFolder(acc);

    Future<String?> find(String name) async {
      final q =
          "'$_folderId' in parents and name = '$name' and mimeType != 'application/vnd.google-apps.folder' and trashed = false";
      final res = await drive.files.list(q: q, $fields: 'files(id, name)');
      return res.files != null && res.files!.isNotEmpty
          ? res.files!.first.id
          : null;
    }

    _storiesFileId ??= await find(storiesFileName);
    _profileFileId ??= await find(profileFileName);
    _profilePngId ??= await find(profilePngName);
  }

  Future<void> uploadAll({
    required AccountService account,
    required List<Story> stories,
  }) async {
    final drive = await _drive(account);
    if (drive == null) {
      throw Exception('Inicia sesión con Google');
    }

    await _ensureHandles(account);

    final storiesJson =
    jsonEncode(stories.map((s) => s.toMap()).toList());
    final storiesBytes = utf8.encode(storiesJson);
    final mediaStories =
    gdrive.Media(Stream.value(storiesBytes), storiesBytes.length);

    final fileStories = gdrive.File()
      ..name = storiesFileName
      ..parents = [_folderId!]
      ..mimeType = 'application/json';

    if (_storiesFileId == null) {
      _storiesFileId = (await drive.files.create(
        fileStories,
        uploadMedia: mediaStories,
        $fields: 'id',
      ))
          .id;
    } else {
      await drive.files.update(
        gdrive.File()..mimeType = 'application/json',
        _storiesFileId!,
        uploadMedia: mediaStories,
      );
    }

    final profileJson = jsonEncode(account.toProfileJson());
    final profileBytes = utf8.encode(profileJson);
    final mediaProfile =
    gdrive.Media(Stream.value(profileBytes), profileBytes.length);

    if (_profileFileId == null) {
      _profileFileId = (await drive.files.create(
        gdrive.File()
          ..name = profileFileName
          ..parents = [_folderId!]
          ..mimeType = 'application/json',
        uploadMedia: mediaProfile,
        $fields: 'id',
      ))
          .id;
    } else {
      await drive.files.update(
        gdrive.File()..mimeType = 'application/json',
        _profileFileId!,
        uploadMedia: mediaProfile,
      );
    }

    if (account.photoPath != null &&
        File(account.photoPath!).existsSync()) {
      final bytes = File(account.photoPath!).readAsBytesSync();
      final mediaPng =
      gdrive.Media(Stream.value(bytes), bytes.length);

      if (_profilePngId == null) {
        _profilePngId = (await drive.files.create(
          gdrive.File()
            ..name = profilePngName
            ..parents = [_folderId!]
            ..mimeType = 'image/png',
          uploadMedia: mediaPng,
          $fields: 'id',
        ))
            .id;
      } else {
        await drive.files.update(
          gdrive.File()..mimeType = 'image/png',
          _profilePngId!,
          uploadMedia: mediaPng,
        );
      }
    }

    await _uploadStoryImages(account, drive, stories);
  }

  Future<void> _uploadStoryImages(
      AccountService account,
      gdrive.DriveApi drive,
      List<Story> stories,
      ) async {
    await _ensureImagesFolder(account);

    final existingRes = await drive.files.list(
      q: "'$_imagesFolderId' in parents and trashed = false",
      $fields: 'files(id, name)',
    );
    final existing = <String, String>{};
    for (final f in existingRes.files ?? <gdrive.File>[]) {
      if (f.id != null && f.name != null) {
        existing[f.name!] = f.id!;
      }
    }

    final imagePaths = _collectImagePaths(stories);

    for (final path in imagePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final name = p.basename(path);
      final bytes = file.readAsBytesSync();
      final media = gdrive.Media(Stream.value(bytes), bytes.length);

      final String? existingId = existing[name];

      if (existingId == null) {
        await drive.files.create(
          gdrive.File()
            ..name = name
            ..parents = [_imagesFolderId!]
            ..mimeType = _mimeFromExtension(p.extension(name)),
          uploadMedia: media,
        );
      } else {
        await drive.files.update(
          gdrive.File()..mimeType = _mimeFromExtension(p.extension(name)),
          existingId,
          uploadMedia: media,
        );
      }
    }
  }

  Set<String> _collectImagePaths(List<Story> stories) {
    final paths = <String>{};

    void collect(dynamic value) {
      if (value is String) {
        final ext = p.extension(value).toLowerCase();
        if (ext == '.png' ||
            ext == '.jpg' ||
            ext == '.jpeg' ||
            ext == '.webp') {
          final file = File(value);
          if (file.existsSync()) {
            paths.add(value);
          }
        }
      } else if (value is Map) {
        for (final v in value.values) {
          collect(v);
        }
      } else if (value is List) {
        for (final v in value) {
          collect(v);
        }
      }
    }

    for (final s in stories) {
      collect(s.toMap());
    }

    return paths;
  }

  Future<void> restoreAll({required AccountService account}) async {
    final drive = await _drive(account);
    if (drive == null) {
      throw Exception('Inicia sesión con Google');
    }

    await _ensureHandles(account);

    Map<String, String> imageNameToLocalPath = {};

    if (_imagesFolderId != null) {
      imageNameToLocalPath =
      await _downloadStoryImages(account, drive);
    }

    if (_storiesFileId != null) {
      final media = await drive.files.get(
        _storiesFileId!,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      ) as gdrive.Media;

      final bytes =
      await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final decoded =
      jsonDecode(utf8.decode(bytes)) as List<dynamic>;

      final rawList = decoded
          .cast<Map<String, dynamic>>()
          .map((m) => _patchImagePathsInMap(m, imageNameToLocalPath))
          .toList();

      final stories =
      rawList.map((m) => Story.fromMap(m)).toList();

      await LocalStorageService.saveStories(stories);
    }

    if (_profileFileId != null) {
      final media = await drive.files.get(
        _profileFileId!,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      ) as gdrive.Media;

      final bytes =
      await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final map =
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      await account
          .setAuthorDescription((map['authorDescription'] as String?) ?? '');
      await account.setCustomUserName(
          (map['customUserName'] as String?) ?? '');
    }

    if (_profilePngId != null) {
      final media = await drive.files.get(
        _profilePngId!,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      ) as gdrive.Media;

      final bytes =
      await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));

      final base64Str = base64Encode(bytes);
      final imgPath = await LocalStorageService.saveBase64ToImage(
        base64Str,
        ext: '.png',
      );

      final box = await Hive.openBox('profile');
      await box.put('photoPath', imgPath);
      account.photoPath = imgPath;
      account.notifyListeners();
    }
  }

  Future<Map<String, String>> _downloadStoryImages(
      AccountService account,
      gdrive.DriveApi drive,
      ) async {
    await _ensureImagesFolder(account);

    final res = await drive.files.list(
      q: "'$_imagesFolderId' in parents and trashed = false",
      $fields: 'files(id, name, mimeType)',
    );

    final Map<String, String> nameToPath = {};

    for (final f in res.files ?? <gdrive.File>[]) {
      final id = f.id;
      final name = f.name;
      if (id == null || name == null) continue;

      final media = await drive.files.get(
        id,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      ) as gdrive.Media;

      final bytes =
      await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final base64Str = base64Encode(bytes);
      final ext = p.extension(name).isEmpty ? '.png' : p.extension(name);

      final localPath =
      await LocalStorageService.saveBase64ToImage(base64Str, ext: ext);

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
        return value.map(
              (k, v) => MapEntry(k, patch(v)),
        );
      } else if (value is List) {
        return value.map(patch).toList();
      }
      return value;
    }

    return patch(map) as Map<String, dynamic>;
  }

  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
