import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import 'auth_service.dart';

class RoomService {
  RoomService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    AuthService? authService,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage(),
        _authService = authService ?? AuthService();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AuthService _authService;

  Future<Map<String, dynamic>> uploadRoomImage(
      String imagePath,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.postMultipart(
        '/rooms/upload',
        fileField: 'image',
        filePath: imagePath,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> startAnalysis(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.post(
        '/rooms/$roomId/analysis/start',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getAnalysis(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.get(
        '/rooms/$roomId/analysis',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> startDesignSuggestions(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.post(
        '/rooms/$roomId/suggestions/start',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getDesignSuggestions(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.get(
        '/rooms/$roomId/suggestions',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> saveSelectedProducts(
      String roomId,
      List<String> productIds,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.put(
        '/rooms/$roomId/selected-products',
        body: {
          'productIds': productIds,
        },
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> startPlacementPlan(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.post(
        '/rooms/$roomId/placement/start',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getPlacementPlan(
      String roomId,
      ) async {
    return _withAuthentication(
          (accessToken) => _apiClient.get(
        '/rooms/$roomId/placement',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _withAuthentication(
      Future<Map<String, dynamic>> Function(
          String accessToken,
          ) request,
      ) async {
    var accessToken =
    await _tokenStorage.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active session.',
      );
    }

    try {
      return await request(
        accessToken,
      );
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      // AuthService.getMe() already uses the
      // existing refresh-token rotation flow.
      await _authService.getMe();

      accessToken =
      await _tokenStorage.getAccessToken();

      if (accessToken == null ||
          accessToken.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message:
          'Your session has expired. Please sign in again.',
        );
      }

      return request(
        accessToken,
      );
    }
  }
}