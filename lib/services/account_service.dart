import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:apphistorias/services/local_storage_service.dart';

class AccountService with ChangeNotifier {
  // Perfil local
  String authorDescription = '';
  String? photoPath;
  String customUserName = ''; // NUEVO: nombre de usuario editable
  Uint8List? get photoBytes =>
      (photoPath != null && !kIsWeb && File(photoPath!).existsSync())
          ? File(photoPath!).readAsBytesSync()
          : null;

  // Google Sign-In
  final GoogleSignIn _gsi = GoogleSignIn(
    scopes: <String>[
      'https://www.googleapis.com/auth/drive.file',
      'email',
      'profile',
    ],
  );
  GoogleSignInAccount? _account;
  GoogleSignInAccount? get account => _account;
  String? get googleDisplayName => _account?.displayName;
  String? get email => _account?.email;

  // Nombre a mostrar: prioridad al personalizado, luego Google, luego “Sin sesión”
  String get displayName {
    if (customUserName.trim().isNotEmpty) return customUserName.trim();
    if ((googleDisplayName ?? '').trim().isNotEmpty) return googleDisplayName!.trim();
    return 'Sin sesión';
  }

  // Hive
  static const _profileBox = 'profile';
  static const _descKey = 'authorDescription';
  static const _photoKey = 'photoPath';
  static const _nameKey = 'customUserName'; // NUEVO
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_profileBox);
    authorDescription = (_box!.get(_descKey) as String?) ?? '';
    photoPath = _box!.get(_photoKey) as String?;
    customUserName = (_box!.get(_nameKey) as String?) ?? '';
    try {
      _account = await _gsi.signInSilently();
    } catch (_) {}
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

  Future<void> signInWithGoogle() async {
    _account = await _gsi.signIn();
    notifyListeners();
  }

  Future<void> signOutGoogle() async {
    await _gsi.disconnect();
    _account = null;
    notifyListeners();
  }

  // Borra solo datos de perfil en Hive (no historias)
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
    'customUserName': customUserName, // NUEVO
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
