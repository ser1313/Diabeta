import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _tokenKey = 'token';
  static const _storage = FlutterSecureStorage();
  static const _requestTimeout = Duration(seconds: 15);
  static const _invalidResponse =
      ApiException(502, 'La API devolvió una respuesta no válida.');
  final String baseUrl;
  ApiClient({String? baseUrl}) : baseUrl = _validatedBaseUrl(baseUrl);

  static String _validatedBaseUrl(String? configured) {
    final value = configured ?? const String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');
    final uri = Uri.parse(value);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('API_URL must use http or https');
    }
    if (uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw ArgumentError('API_URL must be an absolute base URL without credentials, query, or fragment');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('Production API_URL must use HTTPS');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
  Future<String?> token() => _storage.read(key: _tokenKey);
  Future<T> _request<T>(
    Future<http.Response> Function(Map<String, String>) call, {
    String? sessionToken,
  }) async {
    final t = sessionToken ?? await token();
    final response = await call({
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    }).timeout(_requestTimeout);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _responseMessage(response.body));
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _invalidResponse;
    }
    if (decoded is! T) throw _invalidResponse;
    return decoded;
  }

  String _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is String) return message;
        if (message is List) return message.whereType<String>().join('; ');
      }
    } on FormatException {
      // No se propaga el cuerpo sin procesar de una respuesta de error.
    }
    return 'La petición no se ha podido completar.';
  }
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _request((headers) => http.patch(
            Uri.parse(baseUrl + path),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ));

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? sessionToken,
  }) =>
      _request(
        (headers) => http.post(
          Uri.parse(baseUrl + path),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ),
        sessionToken: sessionToken,
      );

  Future<List<dynamic>> getList(String path, {String? sessionToken}) => _request(
        (headers) => http.get(Uri.parse(baseUrl + path), headers: headers),
        sessionToken: sessionToken,
      );

  Future<Map<String, dynamic>> getMap(String path, {String? sessionToken}) =>
      _request(
        (headers) => http.get(Uri.parse(baseUrl + path), headers: headers),
        sessionToken: sessionToken,
      );
}
