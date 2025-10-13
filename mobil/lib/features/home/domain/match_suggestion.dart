import 'package:equatable/equatable.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/match_reason_model.dart';

class MatchSuggestion extends Equatable {
  final UserModel user; // Önerilen diğer kullanıcı
  final double score; // 0-1 arasında puan
  final List<MatchReason> reasons; // Neden eşleşti

  const MatchSuggestion({
    required this.user,
    required this.score,
    required this.reasons,
  });

  @override
  List<Object?> get props => [user, score, reasons];
}
