import 'dart:math';
import '../../../core/models/user_model.dart';
import '../../../core/models/match_reason_model.dart';
import '../domain/match_suggestion.dart';

/// Gerçek backend gelene kadar iki (veya daha fazla) kullanıcı arasında
/// basit eşleşme oluşturan mock repository.
class MockMatchRepository {
  final Random _rng = Random();

  /// Sistemden gelen tüm kullanıcıları alıyormuş gibi yap (şimdilik local)
  Future<List<UserModel>> fetchAllUsersExcept(String currentEmail) async {
    // TODO: Backend entegrasyonu gelince HTTP isteği yap
    // Şimdilik local SharedPreferences'da sadece current user var.
    // Bu nedenle sahte 1-2 user üretelim.
    await Future.delayed(const Duration(milliseconds: 200));

    final demo = [
      UserModel(
        id: 'u2',
        name: 'Ayşe Yılmaz',
        email: 'ayse@example.com',
        university: 'Örnek Üniversitesi',
        department: 'Bilgisayar Mühendisliği',
        classYear: 2,
        isVerified: true,
        courses: const ['MAT101', 'FIZ101', 'BLG102'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UserModel(
        id: 'u3',
        name: 'Mehmet Demir',
        email: 'mehmet@example.com',
        university: 'Örnek Üniversitesi',
        department: 'Yazılım Mühendisliği',
        classYear: 3,
        isVerified: false,
        courses: const ['BLG102', 'BLG202', 'IST201'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return demo.where((u) => u.email != currentEmail).toList();
  }

  Future<List<MatchSuggestion>> buildSuggestions(UserModel current) async {
    final others = await fetchAllUsersExcept(current.email);
    if (others.isEmpty) return [];

    return others.map((u) {
      // Basit puanlama: random + ortak ders sayısı
      final sharedCourses = u.courses.where((c) => current.courses.contains(c)).length;
      final base = (_rng.nextDouble() * 0.4 + 0.6) + (sharedCourses * 0.02); // 0.6 - 1.0 + küçük bonus
      final reasons = <MatchReason>[
        if (sharedCourses > 0)
          MatchReason(
            type: MatchReasonType.sharedCourse,
            displayText: '$sharedCourses ortak ders',
            data: sharedCourses.toString(),
            urgency: sharedCourses >= 3 ? 7 : 4,
            icon: '📚',
          ),
        MatchReason(
          type: MatchReasonType.sharedInterest,
            displayText: 'Benzer ilgi alanları',
          data: null,
          urgency: 3,
          icon: '🎯',
        ),
      ];
      return MatchSuggestion(
        user: u,
        score: double.parse(base.clamp(0.0, 1.0).toStringAsFixed(2)),
        reasons: reasons,
      );
    }).toList();
  }
}
