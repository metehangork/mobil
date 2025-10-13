import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_badge_model.g.dart';

/// Kullanıcının kazandığı rozetler ve başarılar
@JsonSerializable()
class UserBadge extends Equatable {
  final String id;
  final BadgeType type;
  final String title;
  final String description;
  final String iconUrl;
  final DateTime earnedAt;
  
  const UserBadge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$UserBadgeToJson(this);

  @override
  List<Object?> get props => [id, type, title];
}

/// Rozet türleri
enum BadgeType {
  @JsonValue('verified')
  verified,           // Doğrulanmış öğrenci ✅
  
  @JsonValue('helpful')
  helpful,            // Yardımsever 🏅
  
  @JsonValue('leader')
  leader,             // Kulüp lideri 🏆
  
  @JsonValue('expert')
  expert,             // Ders uzmanı 🎓
  
  @JsonValue('contributor')
  contributor,        // Aktif katkıcı 📝
  
  @JsonValue('early_bird')
  earlyBird,          // İlk kullanıcılardan 🐣
}

/// Profil tamamlama seviyeleri (oyunlaştırma için)
enum ProfileLevel {
  @JsonValue('explorer')
  explorer,           // Seviye 1: Profil Gezgini (avatar + bio)
  
  @JsonValue('academic')
  academic,           // Seviye 2: Akademisyen (3+ ders)
  
  @JsonValue('socializer')
  socializer,         // Seviye 3: Sosyalleşici (5+ ilgi alanı)
  
  @JsonValue('master')
  master,             // Seviye 4: Usta (tam profil + 10+ eşleşme)
}
