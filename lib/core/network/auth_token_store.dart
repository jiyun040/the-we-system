import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'the_we_access_token';
  final FlutterSecureStorage _storage;
  String? _memoryToken;

  Future<String?> read() async {
    if (_memoryToken != null) return _memoryToken;
    try {
      _memoryToken = await _storage.read(key: _key);
    } on MissingPluginException {
      // Widget tests do not install the platform storage plugin.
    }
    return _memoryToken;
  }

  Future<void> write(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _key, value: token);
    } on MissingPluginException {
      // Keep the in-memory value during tests.
    }
  }

  Future<void> clear() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _key);
    } on MissingPluginException {
      // Nothing else to clear during tests.
    }
  }
}
