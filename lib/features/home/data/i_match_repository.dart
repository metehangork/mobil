abstract class IMatchRepository {
  Future<List<Map<String, dynamic>>> getSuggestedMatches();
  Future<List<Map<String, dynamic>>> getMyMatches({String? status});
  Future<bool> acceptMatch(int matchId);
  Future<bool> rejectMatch(int matchId);
}
