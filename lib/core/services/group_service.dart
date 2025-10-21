import 'api_client.dart';
import '../config/api_config.dart';

/// Group Service - Study groups management
class GroupService {
  final ApiClient _client;

  GroupService(this._client);

  /// Get all groups with optional search and filters
  Future<ApiResponse> getGroups({
    String? search,
    int? courseId,
    String? studyType, // 'online', 'in-person', 'hybrid'
    String? city,
    bool myGroupsOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (courseId != null) {
      queryParams['courseId'] = courseId.toString();
    }
    if (studyType != null && studyType.isNotEmpty) {
      queryParams['studyType'] = studyType;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (myGroupsOnly) {
      queryParams['myGroups'] = 'true';
    }

    return await _client.get(
      ApiConfig.groups,
      queryParams: queryParams,
    );
  }

  /// Get specific group details
  Future<ApiResponse> getGroup(int groupId) async {
    return await _client.get('${ApiConfig.groups}/$groupId');
  }

  /// Create a new study group
  Future<ApiResponse> createGroup({
    required String name,
    String? description,
    required int courseId,
    required String studyType, // 'online', 'in-person', 'hybrid'
    String? city,
    String? meetingLocation,
    String? meetingSchedule,
    int? maxMembers,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'courseId': courseId,
      'studyType': studyType,
    };

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (city != null && city.isNotEmpty) {
      body['city'] = city;
    }
    if (meetingLocation != null && meetingLocation.isNotEmpty) {
      body['meetingLocation'] = meetingLocation;
    }
    if (meetingSchedule != null && meetingSchedule.isNotEmpty) {
      body['meetingSchedule'] = meetingSchedule;
    }
    if (maxMembers != null) {
      body['maxMembers'] = maxMembers;
    }

    return await _client.post(
      ApiConfig.groups,
      body: body,
    );
  }

  /// Join a study group
  Future<ApiResponse> joinGroup(int groupId) async {
    return await _client.post('${ApiConfig.groups}/$groupId/join');
  }

  /// Leave a study group
  Future<ApiResponse> leaveGroup(int groupId) async {
    return await _client.post('${ApiConfig.groups}/$groupId/leave');
  }

  /// Get group members
  Future<ApiResponse> getGroupMembers(int groupId) async {
    return await _client.get('${ApiConfig.groups}/$groupId/members');
  }

  /// Get my study groups
  Future<ApiResponse> getMyGroups() async {
    return await _client.get(
      ApiConfig.groups,
      queryParams: {'myGroups': 'true'},
    );
  }

  /// Update group details (only for group creator)
  Future<ApiResponse> updateGroup(
    int groupId, {
    String? name,
    String? description,
    String? studyType,
    String? city,
    String? meetingLocation,
    String? meetingSchedule,
    int? maxMembers,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (studyType != null) body['studyType'] = studyType;
    if (city != null) body['city'] = city;
    if (meetingLocation != null) body['meetingLocation'] = meetingLocation;
    if (meetingSchedule != null) body['meetingSchedule'] = meetingSchedule;
    if (maxMembers != null) body['maxMembers'] = maxMembers;
    if (isActive != null) body['isActive'] = isActive;

    if (body.isEmpty) {
      throw ArgumentError('At least one field must be provided for update');
    }

    return await _client.patch(
      '${ApiConfig.groups}/$groupId',
      body: body,
    );
  }
}
