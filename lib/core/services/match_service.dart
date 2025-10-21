import 'api_client.dart';
import '../config/api_config.dart';

/// Match Service - Smart matching algorithm for study partners
class MatchService {
  final ApiClient _client;

  MatchService(this._client);

  /// Find potential study partners using smart matching algorithm
  /// 
  /// Algorithm considers:
  /// - Common courses (50% weight)
  /// - Common interests
  /// - Same school/department bonuses
  /// - Study level compatibility
  Future<ApiResponse> findMatches({
    List<String>? interests,
    String? preferredGender,
    String? preferredCity,
    int? preferredStudyLevel,
    int minScore = 0,
    int limit = 20,
  }) async {
    final body = <String, dynamic>{
      'minScore': minScore,
      'limit': limit,
    };

    if (interests != null && interests.isNotEmpty) {
      body['interests'] = interests;
    }
    if (preferredGender != null && preferredGender.isNotEmpty) {
      body['preferredGender'] = preferredGender;
    }
    if (preferredCity != null && preferredCity.isNotEmpty) {
      body['preferredCity'] = preferredCity;
    }
    if (preferredStudyLevel != null) {
      body['preferredStudyLevel'] = preferredStudyLevel;
    }

    return await _client.post(
      '${ApiConfig.matches}/find',
      body: body,
    );
  }

  /// Get all my matches (pending, accepted, rejected)
  Future<ApiResponse> getMyMatches({
    String? status, // 'pending', 'accepted', 'rejected'
  }) async {
    final queryParams = status != null 
        ? {'status': status} 
        : null;

    return await _client.get(
      ApiConfig.matches,
      queryParams: queryParams,
    );
  }

  /// Get specific match details
  Future<ApiResponse> getMatch(int matchId) async {
    return await _client.get('${ApiConfig.matches}/$matchId');
  }

  /// Accept or reject a match
  /// 
  /// [action] can be 'accept' or 'reject'
  /// When both users accept, a conversation is automatically created
  Future<ApiResponse> respondToMatch(int matchId, String action) async {
    if (action != 'accept' && action != 'reject') {
      throw ArgumentError('action must be "accept" or "reject"');
    }

    return await _client.patch(
      '${ApiConfig.matches}/$matchId/action',
      body: {'action': action},
    );
  }

  /// Accept a match (shorthand method)
  Future<ApiResponse> acceptMatch(int matchId) async {
    return respondToMatch(matchId, 'accept');
  }

  /// Reject a match (shorthand method)
  Future<ApiResponse> rejectMatch(int matchId) async {
    return respondToMatch(matchId, 'reject');
  }
}
