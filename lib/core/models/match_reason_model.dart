import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_reason_model.g.dart';

/// Eşleşme nedenlerini temsil eder (bağlam ve öncelikle)
@JsonSerializable()
class MatchReason extends Equatable {
  final MatchReasonType type;
  final String displayText;
  final String? data;         // Örn: "MAT201", "Gitar"
  final int urgency;          // 0-10 (10 en acil)
  final String icon;          // Emoji veya icon ismi
  
  const MatchReason({
    required this.type,
    required this.displayText,
    this.data,
    this.urgency = 5,
    this.icon = '🎯',
  });

  factory MatchReason.fromJson(Map<String, dynamic> json) =>
      _$MatchReasonFromJson(json);

  Map<String, dynamic> toJson() => _$MatchReasonToJson(this);

  @override
  List<Object?> get props => [type, displayText, data, urgency];
}

/// Eşleşme neden türleri (akıllı önceliklendirme için)
enum MatchReasonType {
  @JsonValue('critical_course')
  criticalCourse,    // "MAT201 sınavı 3 gün sonra!" 🚨
  
  @JsonValue('shared_course')
  sharedCourse,      // "3 ortak dersiniz var" 📚
  
  @JsonValue('shared_interest')
  sharedInterest,    // "İkiniz de gitar çalıyor" 🎸
  
  @JsonValue('study_time')
  studyTime,         // "İkiniz de akşam çalışıyorsunuz" 🌙
  
  @JsonValue('same_class')
  sameClass,         // "Aynı sınıftan arkadaşlarınız var" 👥
  
  @JsonValue('complementary')
  complementary,     // "Sen kodlama, o tasarım biliyor" 🤝
  
  @JsonValue('location')
  location,          // "Aynı kampüstesiniz" 📍
}

/// Eşleşme modeli (zenginleştirilmiş)
@JsonSerializable()
class Match extends Equatable {
  final String id;
  final String userId;
  final String otherId;
  final int score;                      // 0-100
  final List<MatchReason> reasons;
  final MatchStatus status;
  final String? firstMessageTemplate;    // Önerilen ilk mesaj
  final DateTime createdAt;
  final DateTime? respondedAt;
  
  const Match({
    required this.id,
    required this.userId,
    required this.otherId,
    required this.score,
    required this.reasons,
    required this.status,
    this.firstMessageTemplate,
    required this.createdAt,
    this.respondedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) =>
      _$MatchFromJson(json);

  Map<String, dynamic> toJson() => _$MatchToJson(this);

  @override
  List<Object?> get props => [id, userId, otherId, score, status];
}

enum MatchStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('accepted')
  accepted,
  
  @JsonValue('declined')
  declined,
  
  @JsonValue('expired')
  expired,
}
