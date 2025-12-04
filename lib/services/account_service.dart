import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:apphistorias/services/local_storage_service.dart';

class SignInResult {
  final bool ok;
  final String? error;
  const SignInResult(this.ok, this.error);
}

class AccountService with ChangeNotifier {
  static const String _webServerClientId =
      '138921401527-84edkugl561ulv8re3kb3ea6n85oku25.apps.googleusercontent.com';

  String authorDescription = '';
  String? photoPath;
  String customUserName = '';

  Uint8List? get photoBytes {
    if (photoPath == null || kIsWeb) return null;
    final file = File(photoPath!);
    return file.existsSync() ? file.readAsBytesSync() : null;
  }

  late final GoogleSignIn _gsi = GoogleSignIn(
    serverClientId: _webServerClientId,
    scopes: const ['email', 'profile'],
  );

  GoogleSignInAccount? _account;
  GoogleSignInAccount? get account => _account;
  String? get googleDisplayName => _account?.displayName;
  String? get email => _account?.email;

  String get displayName {
    if (customUserName.trim().isNotEmpty) return customUserName.trim();
    final gName = (googleDisplayName ?? '').trim();
    if (gName.isNotEmpty) return gName;
    return 'Sin sesión';
  }

  static const _profileBox = 'profile';
  static const _descKey = 'authorDescription';
  static const _photoKey = 'photoPath';
  static const _nameKey = 'customUserName';
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_profileBox);
    authorDescription = (_box!.get(_descKey) as String?) ?? '';
    photoPath = _box!.get(_photoKey) as String?;
    customUserName = (_box!.get(_nameKey) as String?) ?? '';

    try {
      _account = await _gsi.signInSilently();
      if (_account != null) {
        await _ensureDriveScope();
      }
    } catch (e) {
      debugPrint('signInSilently error: $e');
    }

    notifyListeners();
  }

  Future<void> setAuthorDescription(String v) async {
    authorDescription = v;
    await _box?.put(_descKey, v);
    notifyListeners();
  }

  Future<void> setCustomUserName(String v) async {
    customUserName = v;
    await _box?.put(_nameKey, v);
    notifyListeners();
  }

  Future<void> setPhotoFromPicker() async {
    final picker = ImagePicker();
    final XFile? file =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final savedPath = await LocalStorageService.copyImageToAppDir(file.path);
    photoPath = savedPath;
    await _box?.put(_photoKey, savedPath);
    notifyListeners();
  }

  Future<void> removePhoto() async {
    photoPath = null;
    await _box?.delete(_photoKey);
    notifyListeners();
  }

  Future<void> _ensureDriveScope() async {
    try {
      await _gsi
          .requestScopes(const ['https://www.googleapis.com/auth/drive.file']);
    } catch (e) {
      debugPrint('requestScopes error: $e');
    }
  }

  Future<SignInResult> signInWithGoogle() async {
    try {
      await _gsi.disconnect();
    } catch (_) {}

    GoogleSignInAccount? acc;
    String? errorCode;

    try {
      acc = await _gsi.signIn();
    } on PlatformException catch (e) {
      errorCode = e.code;
      debugPrint('signIn PlatformException: code=${e.code}, msg=${e.message}');
    } catch (e) {
      debugPrint('signIn error: $e');
    }

    if (acc == null) {
      try {
        acc = await _gsi.signInSilently();
      } catch (e) {
        debugPrint('signInSilently after error: $e');
      }
    }

    if (acc == null) {
      return SignInResult(false, errorCode);
    }

    try {
      await acc.authHeaders;
    } catch (e) {
      debugPrint('authHeaders error: $e');
    }

    await _ensureDriveScope();

    _account = acc;
    notifyListeners();
    return const SignInResult(true, null);
  }

  Future<void> signOutGoogle() async {
    try {
      await _gsi.disconnect();
    } catch (_) {}
    _account = null;
    notifyListeners();
  }

  Future<void> clearProfileData() async {
    _box ??= await Hive.openBox(_profileBox);
    await _box!.delete(_descKey);
    await _box!.delete(_photoKey);
    await _box!.delete(_nameKey);
    authorDescription = '';
    photoPath = null;
    customUserName = '';
    notifyListeners();
  }

  Future<http.Client?> authenticatedHttpClient() async {
    final u = _account ?? await _gsi.signInSilently();
    if (u == null) return null;
    final headers = await u.authHeaders;
    return _GoogleAuthClient(headers);
  }

  Map<String, dynamic> toProfileJson() => {
    'displayName': googleDisplayName,
    'email': email,
    'authorDescription': authorDescription,
    'customUserName': customUserName,
    'hasPhoto': photoPath != null,
  };
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
