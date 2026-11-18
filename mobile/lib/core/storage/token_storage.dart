import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _accessTokenKey =
      'roomstylo_access_token';

  static const String _refreshTokenKey =
      'roomstylo_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(
        key: _accessTokenKey,
        value: accessToken,
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      ),
    ]);
  }

  Future<String?> getAccessToken() {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  Future<String?> getRefreshToken() {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(
        key: _accessTokenKey,
      ),
      _storage.delete(
        key: _refreshTokenKey,
      ),
    ]);
  }

  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }
}