import 'package:google_sign_in/google_sign_in.dart';

import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  static Future<void>? _googleInitialization;

  static const String _googleServerClientId =
      String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
  }

  Future<String?> forgotPassword({
    required String email,
  }) async {
    final response = await _apiClient.post(
      '/auth/forgot-password',
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    final devOtp = response['devOtp'];

    if (devOtp is String && devOtp.isNotEmpty) {
      return devOtp;
    }

    return null;
  }

  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      '/auth/verify-reset-otp',
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
    );

    final resetToken = response['resetToken'] as String?;

    if (resetToken == null || resetToken.isEmpty) {
      throw const ApiException(
        message:
            'Reset verification did not return a valid reset token.',
      );
    }

    return resetToken;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    return _saveAuthenticationResponse(
      response,
      invalidResponseMessage:
          'Login response did not contain valid authentication tokens.',
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw const ApiException(
        message:
            'Google Sign-In is not supported on this device.',
      );
    }

    GoogleSignInAccount googleAccount;

    try {
      googleAccount = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const ApiException(
          message: 'Google sign-in was cancelled.',
        );
      }

      if (
          error.code ==
          GoogleSignInExceptionCode.clientConfigurationError) {
        throw const ApiException(
          message:
              'Google Sign-In is not configured correctly for this app.',
        );
      }

      throw ApiException(
        message:
            error.description ?? 'Unable to sign in with Google.',
      );
    }

    final idToken =
        googleAccount.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException(
        message:
            'Google did not return a valid identity token.',
      );
    }

    final response = await _apiClient.post(
      '/auth/google',
      body: {
        'idToken': idToken,
      },
    );

    return _saveAuthenticationResponse(
      response,
      invalidResponseMessage:
          'Google sign-in response did not contain valid authentication tokens.',
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final accessToken =
        await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active session.',
      );
    }

    try {
      return await _apiClient.get(
        '/auth/me',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      final refreshed = await _refreshTokens();

      return _apiClient.get(
        '/auth/me',
        headers: {
          'Authorization':
              'Bearer ${refreshed.accessToken}',
        },
      );
    }
  }

  Future<bool> restoreSession() async {
    final hasTokens = await _tokenStorage.hasTokens();

    if (!hasTokens) {
      return false;
    }

    try {
      await getMe();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStorage.clearTokens();
        return false;
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    final accessToken =
        await _tokenStorage.getAccessToken();

    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
      }
    } finally {
      await _tokenStorage.clearTokens();

      if (_googleInitialization != null) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // RoomStylo logout must still complete even if
          // Google cannot clear its local account state.
        }
      }
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleServerClientId.isEmpty) {
      throw const ApiException(
        message:
            'Google Sign-In client ID is not configured. Start Flutter with GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );

    try {
      await _googleInitialization;
    } on GoogleSignInException catch (error) {
      throw ApiException(
        message:
            error.description ?? 'Unable to initialize Google Sign-In.',
      );
    }
  }

  Future<Map<String, dynamic>>
      _saveAuthenticationResponse(
    Map<String, dynamic> response, {
    required String invalidResponseMessage,
  }) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw ApiException(
        message: invalidResponseMessage,
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = response['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    return <String, dynamic>{};
  }

  Future<_TokenPair> _refreshTokens() async {
    final refreshToken =
        await _tokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clearTokens();

      throw const ApiException(
        statusCode: 401,
        message: 'Your session has expired.',
      );
    }

    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        body: {
          'refreshToken': refreshToken,
        },
      );

      final newAccessToken =
          response['accessToken'] as String?;

      final newRefreshToken =
          response['refreshToken'] as String?;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Unable to refresh your session.',
        );
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return _TokenPair(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
    } on ApiException {
      await _tokenStorage.clearTokens();
      rethrow;
    }
  }
}

class _TokenPair {
  const _TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
