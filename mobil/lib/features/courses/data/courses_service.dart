import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/models/course_match_model.dart';

class CoursesService {
  final String baseUrl = AppConfig.apiBaseUrl;

  Future<String?> _getToken() async {
    // TODO: Implement token retrieval from secure storage
    return null;
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Tüm dersleri getir
  Future<List<CourseModel>> getCourses({String? departmentId, String? search}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (departmentId != null) queryParams['departmentId'] = departmentId;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/courses').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final courses = (data['courses'] as List)
            .map((e) => CourseModel.fromJson(e))
            .toList();
        return courses;
      }
      throw Exception('Dersler getirilemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dersler getirilemedi: $e');
    }
  }

  /// Kullanıcının derslerini getir
  Future<List<CourseModel>> getMyCourses() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/courses/my-courses'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final courses = (data['courses'] as List)
            .map((e) => CourseModel.fromJson(e))
            .toList();
        return courses;
      }
      throw Exception('Dersler getirilemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dersler getirilemedi: $e');
    }
  }

  /// Ders ekle
  Future<void> enrollCourse(String courseId, {String? semester}) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/courses/enroll'),
        headers: _getHeaders(token),
        body: json.encode({
          'courseId': courseId,
          if (semester != null) 'semester': semester,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Ders eklenemedi');
      }
    } catch (e) {
      throw Exception('Ders eklenemedi: $e');
    }
  }

  /// Ders çıkar
  Future<void> unenrollCourse(String courseId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/courses/unenroll/$courseId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Ders çıkarılamadı');
      }
    } catch (e) {
      throw Exception('Ders çıkarılamadı: $e');
    }
  }

  /// Ders arkadaşı eşleştirmeleri getir (EMİLETÖR)
  Future<List<CourseMatchModel>> getMatches({int minCommonCourses = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/courses/matches').replace(
        queryParameters: {
          'minCommonCourses': minCommonCourses.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = (data['matches'] as List)
            .map((e) => CourseMatchModel.fromJson(e))
            .toList();
        return matches;
      }
      throw Exception('Eşleştirmeler getirilemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Eşleştirmeler getirilemedi: $e');
    }
  }

  /// Belirli bir ders için arkadaş bul
  Future<List<Map<String, dynamic>>> getCourseMatches(String courseId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/courses/course/$courseId/matches'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['matches']);
      }
      throw Exception('Ders arkadaşları getirilemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Ders arkadaşları getirilemedi: $e');
    }
  }
}
