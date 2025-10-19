import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// HTTP Client wrapper with error handling
class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get authentication token
  String? get token => _token;

  /// GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client
          .get(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PATCH request
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final url = '${ApiConfig.apiUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }
    return Uri.parse(url);
  }

  /// Build headers with authentication
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{...ApiConfig.defaultHeaders};
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    
    return headers;
  }

  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        statusCode: statusCode,
      );
    } else {
      final error = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : {'error': 'Unknown error'};
      
      return ApiResponse.error(
        message: error['error'] ?? error['message'] ?? 'Request failed',
        statusCode: statusCode,
        data: error,
      );
    }
  }

  /// Handle exceptions
  ApiResponse _handleError(dynamic error) {
    return ApiResponse.error(
      message: error.toString(),
      statusCode: 0,
    );
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory ApiResponse.success({
    dynamic data,
    required int statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    required String message,
    required int statusCode,
    dynamic data,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}
