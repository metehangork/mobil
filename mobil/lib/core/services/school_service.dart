import 'api_client.dart';
import '../config/api_config.dart';

/// School Service
class SchoolService {
  final ApiClient _client;

  SchoolService(this._client);

  /// Get all schools with optional search and filters
  Future<ApiResponse> getSchools({
    String? search,
    String? city,
    String? type,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    return await _client.get(
      ApiConfig.schools,
      queryParams: queryParams,
    );
  }

  /// Get school by ID
  Future<ApiResponse> getSchool(int schoolId) async {
    return await _client.get('${ApiConfig.schools}/$schoolId');
  }

  /// Get school's departments
  Future<ApiResponse> getSchoolDepartments(int schoolId) async {
    return await _client.get('${ApiConfig.schools}/$schoolId/departments');
  }

  /// Get school's courses
  Future<ApiResponse> getSchoolCourses(
    int schoolId, {
    int? semester,
    int? departmentId,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (semester != null) {
      queryParams['semester'] = semester.toString();
    }
    if (departmentId != null) {
      queryParams['departmentId'] = departmentId.toString();
    }

    return await _client.get(
      '${ApiConfig.schools}/$schoolId/courses',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }
}

/// Department Service
class DepartmentService {
  final ApiClient _client;

  DepartmentService(this._client);

  /// Get all departments with optional search and filters
  Future<ApiResponse> getDepartments({
    String? search,
    int? schoolId,
    String? faculty,
    String? degreeLevel,
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
    if (faculty != null && faculty.isNotEmpty) {
      queryParams['faculty'] = faculty;
    }
    if (degreeLevel != null && degreeLevel.isNotEmpty) {
      queryParams['degreeLevel'] = degreeLevel;
    }

    return await _client.get(
      ApiConfig.departments,
      queryParams: queryParams,
    );
  }

  /// Get department by ID
  Future<ApiResponse> getDepartment(int departmentId) async {
    return await _client.get('${ApiConfig.departments}/$departmentId');
  }

  /// Get department's courses
  Future<ApiResponse> getDepartmentCourses(
    int departmentId, {
    int? semester,
  }) async {
    final queryParams = semester != null 
        ? {'semester': semester.toString()} 
        : null;

    return await _client.get(
      '${ApiConfig.departments}/$departmentId/courses',
      queryParams: queryParams,
    );
  }
}
