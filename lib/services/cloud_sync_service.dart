import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

import 'package:apphistorias/services/local_storage_service.dart';
import 'package:apphistorias/services/account_service.dart';
import 'package:apphistorias/models/story.dart';

class CloudSyncService {
  static const String appFolderName = 'AppHistorias';
  static const String storiesFileName = 'stories.json';
  static const String profileFileName = 'profile.json';
  static const String profilePngName = 'profile.png';

  String? _folderId;
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
    Future<String?> find(String name) async {
      final q =
          "'$_folderId' in parents and name = '$name' and mimeType != 'application/vnd.google-apps.folder' and trashed = false";
      final res = await drive.files.list(q: q, $fields: 'files(id, name)');
      return res.files != null && res.files!.isNotEmpty ? res.files!.first.id : null;
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
    if (drive == null) throw Exception('Inicia sesión con Google');
    await _ensureHandles(account);

    final storiesJson = jsonEncode(stories.map((s) => s.toMap()).toList());
    final storiesBytes = utf8.encode(storiesJson);
    final mediaStories = gdrive.Media(Stream.value(storiesBytes), storiesBytes.length);
    final fileStories = gdrive.File()
      ..name = storiesFileName
      ..parents = [_folderId!]
      ..mimeType = 'application/json';
    if (_storiesFileId == null) {
      _storiesFileId = (await drive.files.create(fileStories, uploadMedia: mediaStories, $fields: 'id')).id;
    } else {
      await drive.files.update(
        gdrive.File()..mimeType = 'application/json',
        _storiesFileId!,
        uploadMedia: mediaStories,
      );
    }

    final profileJson = jsonEncode(account.toProfileJson());
    final profileBytes = utf8.encode(profileJson);
    final mediaProfile = gdrive.Media(Stream.value(profileBytes), profileBytes.length);
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

    if (account.photoPath != null && File(account.photoPath!).existsSync()) {
      final bytes = File(account.photoPath!).readAsBytesSync();
      final mediaPng = gdrive.Media(Stream.value(bytes), bytes.length);
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
  }

  Future<void> restoreAll({required AccountService account}) async {
    final drive = await _drive(account);
    if (drive == null) throw Exception('Inicia sesión con Google');
    await _ensureHandles(account);

    if (_storiesFileId != null) {
      final media = await drive.files
          .get(_storiesFileId!, downloadOptions: gdrive.DownloadOptions.fullMedia) as gdrive.Media;
      final bytes = await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final list = (jsonDecode(utf8.decode(bytes)) as List).cast<Map<String, dynamic>>();
      final stories = list.map((m) => Story.fromMap(m)).toList();
      await LocalStorageService.saveStories(stories);
    }

    if (_profileFileId != null) {
      final media = await drive.files
          .get(_profileFileId!, downloadOptions: gdrive.DownloadOptions.fullMedia) as gdrive.Media;
      final bytes = await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await account.setAuthorDescription((map['authorDescription'] as String?) ?? '');
    }

    if (_profilePngId != null) {
      final media = await drive.files
          .get(_profilePngId!, downloadOptions: gdrive.DownloadOptions.fullMedia) as gdrive.Media;
      final bytes = await media.stream.fold<List<int>>([], (a, b) => a..addAll(b));
      final base64Str = base64Encode(bytes);
      final imgPath = await LocalStorageService.saveBase64ToImage(base64Str, ext: '.png');
      final box = await Hive.openBox('profile');
      await box.put('photoPath', imgPath);
      account.photoPath = imgPath;
      account.notifyListeners();
    }
  }
}

