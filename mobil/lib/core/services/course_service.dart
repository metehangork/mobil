import 'api_client.dart';
import '../config/api_config.dart';

/// Course Service
class CourseService {
  final ApiClient _client;

  CourseService(this._client);

  /// Get all courses with optional search and filters
  Future<ApiResponse> getCourses({
    String? search,
    int? schoolId,
    int? departmentId,
    int? semester,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (schoolId != null) {
      queryParams['schoolId'] = schoolId.toString();
    }
    if (departmentId != null) {
      queryParams['departmentId'] = departmentId.toString();
    }
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }

    return await _client.get(
      ApiConfig.courses,
      queryParams: queryParams,
    );
  }

  /// Get course by ID
  Future<ApiResponse> getCourse(int courseId) async {
    return await _client.get('${ApiConfig.courses}/$courseId');
  }

  /// Enroll in a course
  Future<ApiResponse> enrollCourse(int courseId) async {
    return await _client.post(
      '${ApiConfig.courses}/enroll',
      body: {'courseId': courseId},
    );
  }

  /// Unenroll from a course
  Future<ApiResponse> unenrollCourse(int courseId) async {
    return await _client.delete(
      '${ApiConfig.courses}/unenroll?courseId=$courseId',
    );
  }

  /// Get potential study partners for a course
  Future<ApiResponse> getCourseMatches(int courseId) async {
    return await _client.get('${ApiConfig.courses}/$courseId/matches');
  }

  /// Get user's enrolled courses
  Future<ApiResponse> getMyCourses() async {
    return await _client.get('${ApiConfig.users}/me/courses');
  }
}
