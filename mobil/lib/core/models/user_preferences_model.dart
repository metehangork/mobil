import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_preferences_model.g.dart';

/// Kullanıcının ders arkadaşı bulma ve etkileşim tercihlerini saklar.
@JsonSerializable()
class UserPreferences extends Equatable {
  /// Tercih edilen çalışma zamanı (örn: Gündüz, Gece, Farketmez)
  final StudyTimePreference studyTime;

  /// Tercih edilen grup büyüklüğü (örn: Birebir, Küçük Grup, Büyük Grup)
  final GroupSizePreference groupSize;

  /// Tercih edilen iletişim şekli (örn: Yüzyüze, Online, Hibrit)
  final CommunicationPreference communicationStyle;

  /// Kullanıcının ne kadar sıklıkla müsait olduğu (örn: Hafta içi, Hafta sonu, Esnek)
  final List<Availability> availability;

  const UserPreferences({
    this.studyTime = StudyTimePreference.any,
    this.groupSize = GroupSizePreference.any,
    this.communicationStyle = CommunicationPreference.any,
    this.availability = const [Availability.any],
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  @override
  List<Object?> get props => [
        studyTime,
        groupSize,
        communicationStyle,
        availability,
      ];
}

// --- Enums for Preferences ---

enum StudyTimePreference {
  @JsonValue('day')
  day,
  @JsonValue('night')
  night,
  @JsonValue('any')
  any,
}

enum GroupSizePreference {
  @JsonValue('one_on_one')
  oneOnOne,
  @JsonValue('small_group') // 2-4 kişi
  smallGroup,
  @JsonValue('large_group') // 5+ kişi
  largeGroup,
  @JsonValue('any')
  any,
}

enum CommunicationPreference {
  @JsonValue('in_person')
  inPerson,
  @JsonValue('online')
  online,
  @JsonValue('hybrid')
  hybrid,
  @JsonValue('any')
  any,
}

enum Availability {
  @JsonValue('weekdays')
  weekdays,
  @JsonValue('weekends')
  weekends,
  @JsonValue('flexible')
  flexible,
  @JsonValue('any')
  any,
}
