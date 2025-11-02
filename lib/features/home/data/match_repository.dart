import 'package:unicampus/core/services/match_service.dart';
import 'i_match_repository.dart';

class MatchRepository implements IMatchRepository {
  final MatchService _matchService;

  MatchRepository(this._matchService);

  @override
  Future<List<Map<String, dynamic>>> getSuggestedMatches() async {
    try {
      final response = await _matchService.findMatches();
      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      // print('MatchRepository: Error getting suggested matches: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMyMatches({String? status}) async {
    try {
      final response = await _matchService.getMyMatches(status: status);
      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      // print('MatchRepository: Error getting my matches: $e');
      return [];
    }
  }

  @override
  Future<bool> acceptMatch(int matchId) async {
    try {
      final response = await _matchService.acceptMatch(matchId);
      return response.isSuccess;
    } catch (e) {
      // print('MatchRepository: Error accepting match: $e');
      return false;
    }
  }

  @override
  Future<bool> rejectMatch(int matchId) async {
    try {
      final response = await _matchService.rejectMatch(matchId);
      return response.isSuccess;
    } catch (e) {
      // print('MatchRepository: Error rejecting match: $e');
      return false;
    }
  }
}
