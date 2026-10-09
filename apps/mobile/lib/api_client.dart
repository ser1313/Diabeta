import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
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
  Future<String?> token() async => (await SharedPreferences.getInstance()).getString('token');
  Future<Map<String, dynamic>> _request(Future<http.Response> Function(Map<String, String>) call) async {
    final t = await token();
    final response = await call({if (t != null) 'Authorization': 'Bearer $t'});
    if (response.statusCode >= 400) throw Exception(response.body);
    final decoded = jsonDecode(response.body);
    return Map<String, dynamic>.from(decoded as Map);
  }
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) => _request((headers) => http.patch(Uri.parse(baseUrl + path), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)));
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) => _request((headers) => http.post(Uri.parse(baseUrl + path), headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)));
  Future<List<dynamic>> getList(String path) async {
    final t = await token();
    final r = await http.get(Uri.parse(baseUrl + path), headers: {if (t != null) 'Authorization': 'Bearer $t'});
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as List<dynamic>;
  }
  Future<Map<String, dynamic>> getMap(String path) async {
    final t = await token();
    final r = await http.get(Uri.parse(baseUrl + path), headers: {if (t != null) 'Authorization': 'Bearer $t'});
    if (r.statusCode >= 400) throw Exception(r.body);
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }
}