import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import 'auth_service.dart';

class CatalogService {
  CatalogService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    AuthService? authService,
  })  : _apiClient = apiClient ?? const ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage(),
        _authService = authService ?? AuthService();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final AuthService _authService;

  Future<List<Map<String, dynamic>>> getCategories() async {
    final result = await _withAuthenticationList(
      (accessToken) => _apiClient.getList(
        '/catalog/categories',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    return result
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getProducts({
    required List<String> categoryIds,
    String? search,
  }) async {
    final query = <String>[];

    if (categoryIds.isNotEmpty) {
      query.add(
        'categoryIds=${Uri.encodeQueryComponent(categoryIds.join(','))}',
      );
    }

    final cleanedSearch = search?.trim() ?? '';
    if (cleanedSearch.isNotEmpty) {
      query.add(
        'search=${Uri.encodeQueryComponent(cleanedSearch)}',
      );
    }

    final path = query.isEmpty
        ? '/catalog/products'
        : '/catalog/products?${query.join('&')}';

    final result = await _withAuthenticationList(
      (accessToken) => _apiClient.getList(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    return result
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<dynamic>> _withAuthenticationList(
    Future<List<dynamic>> Function(String accessToken) request,
  ) async {
    var accessToken = await _tokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active session.',
      );
    }

    try {
      return await request(accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      await _authService.getMe();
      accessToken = await _tokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Your session has expired. Please sign in again.',
        );
      }

      return request(accessToken);
    }
  }
}
