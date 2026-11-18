import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient();

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Accept': 'application/json',
          ...?headers,
        },
      )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
        'Unable to connect to the server. Please check your connection and try again.',
      );
    }
  }

  Future<List<dynamic>> getList(
      String path, {
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Accept': 'application/json',
          ...?headers,
        },
      )
          .timeout(ApiConfig.timeout);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (response.body.isEmpty) {
          return <dynamic>[];
        }

        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded;
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: 'Invalid list response from server.',
        );
      }

      Map<String, dynamic> errorData = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            errorData = decoded;
          }
        } catch (_) {}
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(errorData),
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
        'Unable to connect to the server. Please check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> put(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http
          .put(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? {}),
      )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
        'Unable to connect to the server. Please check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? {}),
      )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
        'Unable to connect to the server. Please check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> postMultipart(
      String path, {
        required String fileField,
        required String filePath,
        Map<String, String>? fields,
        Map<String, String>? headers,
      }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw const ApiException(
          message:
          'Selected image file could not be found.',
        );
      }

      final fileInfo = _getImageFileInfo(
        filePath,
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}$path'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        ...?headers,
      });

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: fileInfo.filename,
          contentType: fileInfo.contentType,
        ),
      );

      final streamedResponse = await request
          .send()
          .timeout(ApiConfig.timeout);

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
        'Unable to connect to the server. Please check your connection and try again.',
      );
    }
  }

  _ImageFileInfo _getImageFileInfo(
      String filePath,
      ) {
    final normalizedPath =
    filePath.toLowerCase();

    if (normalizedPath.endsWith('.jpg') ||
        normalizedPath.endsWith('.jpeg')) {
      return _ImageFileInfo(
        filename: 'room.jpg',
        contentType: MediaType(
          'image',
          'jpeg',
        ),
      );
    }

    if (normalizedPath.endsWith('.png')) {
      return _ImageFileInfo(
        filename: 'room.png',
        contentType: MediaType(
          'image',
          'png',
        ),
      );
    }

    if (normalizedPath.endsWith('.webp')) {
      return _ImageFileInfo(
        filename: 'room.webp',
        contentType: MediaType(
          'image',
          'webp',
        ),
      );
    }

    throw const ApiException(
      message:
      'Only JPG, JPEG, PNG and WebP images are allowed.',
    );
  }

  Map<String, dynamic> _handleResponse(
      http.Response response,
      ) {
    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded =
        jsonDecode(response.body);

        if (decoded
        is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        throw ApiException(
          statusCode:
          response.statusCode,
          message:
          'Invalid response from server.',
        );
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw ApiException(
      statusCode:
      response.statusCode,
      message:
      _extractErrorMessage(data),
    );
  }

  String _extractErrorMessage(
      Map<String, dynamic> data,
      ) {
    final message = data['message'];

    if (message is String &&
        message.isNotEmpty) {
      return message;
    }

    if (message is List &&
        message.isNotEmpty) {
      return message.join('\n');
    }

    return 'Something went wrong. Please try again.';
  }
}

class _ImageFileInfo {
  const _ImageFileInfo({
    required this.filename,
    required this.contentType,
  });

  final String filename;
  final MediaType contentType;
}