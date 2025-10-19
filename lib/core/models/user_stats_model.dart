import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_stats_model.g.dart';

/// Kullanıcının platformdaki etkileşim istatistiklerini saklar.
@JsonSerializable()
class UserStats extends Equatable {
  /// Başarıyla tamamlanan ders gruplarının sayısı
  final int completedGroups;

  /// Kullanıcının gönderdiği toplam mesaj sayısı
  final int messagesSent;

  /// Platformda aktif olduğu toplam saat (oyunlaştırma için)
  final double hoursActive;

  /// Eşleşme başarı oranı (%)
  final double matchSuccessRate;

  const UserStats({
    this.completedGroups = 0,
    this.messagesSent = 0,
    this.hoursActive = 0.0,
    this.matchSuccessRate = 0.0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  @override
  List<Object?> get props => [
        completedGroups,
        messagesSent,
        hoursActive,
        matchSuccessRate,
      ];
}
