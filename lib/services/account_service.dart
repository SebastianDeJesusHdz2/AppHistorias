// lib/services/account_service.dart (SIN initialize)
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
  // Reemplaza por tu Client ID WEB de OAuth 2.0 en Google Cloud
  static const String _webServerClientId = 'TU_WEB_CLIENT_ID.apps.googleusercontent.com';

  // Perfil local
  String authorDescription = '';
  String? photoPath;
  String customUserName = '';
  Uint8List? get photoBytes =>
      (photoPath != null && !kIsWeb && File(photoPath!).existsSync())
          ? File(photoPath!).readAsBytesSync()
          : null;

  // Google Sign-In: pasa serverClientId EN EL CONSTRUCTOR (soporta 6.x y 7.x)
  late final GoogleSignIn _gsi = GoogleSignIn(
    serverClientId: _webServerClientId, // clave: aquí, no con initialize()
    scopes: const [
      'https://www.googleapis.com/auth/drive.file',
      'email',
      'profile',
    ],
    // hostedDomain: null, // opcional si quisieras restringir dominios
  );

  GoogleSignInAccount? _account;
  GoogleSignInAccount? get account => _account;
  String? get googleDisplayName => _account?.displayName;
  String? get email => _account?.email;

  String get displayName {
    if (customUserName.trim().isNotEmpty) return customUserName.trim();
    if ((googleDisplayName ?? '').trim().isNotEmpty) return googleDisplayName!.trim();
    return 'Sin sesión';
  }

  // Hive
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
    // Intenta silent para reusar sesión si existe
    try {
      await _gsi.signInSilently();
    } catch (_) {}

    // Interactivo: el usuario puede elegir cualquier cuenta
    GoogleSignInAccount? acc;
    try {
      acc = await _gsi.signIn();
    } catch (_) {
      acc = null;
    }
    if (acc == null) return; // cancelado

    // Fuerza obtención de headers (token) para confirmar sesión válida
    try {
      await acc.authHeaders;
    } catch (_) {}

    _account = acc;
    notifyListeners();
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
