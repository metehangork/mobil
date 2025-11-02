import 'i_match_repository.dart';

/// Gerçek backend gelene kadar basit mock repository.
class MockMatchRepository implements IMatchRepository {
  @override
  Future<List<Map<String, dynamic>>> getSuggestedMatches() async {
    // Mock data döndür
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {
        'id': 'u2',
        'name': 'Ayşe Yılmaz',
        'email': 'ayse@example.com',
        'university': 'Örnek Üniversitesi',
        'department': 'Bilgisayar Mühendisliği',
        'score': 0.85,
        'reasons': ['Ortak dersler', 'Aynı bölüm']
      },
      {
        'id': 'u3',
        'name': 'Mehmet Demir',
        'email': 'mehmet@example.com',
        'university': 'Örnek Üniversitesi',
        'department': 'Yazılım Mühendisliği',
        'score': 0.72,
        'reasons': ['Benzer ilgi alanları']
      }
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getMyMatches({String? status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {
        'id': 'm1',
        'userId': 'u2',
        'status': status ?? 'pending',
        'createdAt': DateTime.now().toIso8601String()
      }
    ];
  }

  @override
  Future<bool> acceptMatch(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> rejectMatch(int matchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
}
