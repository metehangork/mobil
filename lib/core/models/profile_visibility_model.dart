import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_visibility_model.g.dart';

/// Kullanıcının profil görünürlük tercihlerini detaylı şekilde yönetir
@JsonSerializable()
class ProfileVisibility extends Equatable {
  /// Profil kartının genel görünürlüğü
  final VisibilityLevel profile;
  
  /// Avatar görünürlüğü (daha kısıtlayıcı olabilir)
  final VisibilityLevel avatar;
  
  /// İsim gösterim şekli
  final NameDisplayType name;
  
  /// Bölüm bilgisi görünürlüğü
  final VisibilityLevel department;
  
  /// Ders listesi görünürlüğü
  final CourseVisibilityType courses;
  
  const ProfileVisibility({
    this.profile = VisibilityLevel.university,
    this.avatar = VisibilityLevel.matches,
    this.name = NameDisplayType.full,
    this.department = VisibilityLevel.university,
    this.courses = CourseVisibilityType.common,
  });

  factory ProfileVisibility.fromJson(Map<String, dynamic> json) =>
      _$ProfileVisibilityFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileVisibilityToJson(this);

  @override
  List<Object?> get props => [profile, avatar, name, department, courses];
}

/// Genel görünürlük seviyeleri
enum VisibilityLevel {
  @JsonValue('public')
  public,        // Herkese açık
  
  @JsonValue('university')
  university,    // Sadece aynı üniversite
  
  @JsonValue('matches')
  matches,       // Sadece eşleşmelerime
  
  @JsonValue('private')
  private,       // Gizli
}

/// İsim gösterim türleri
enum NameDisplayType {
  @JsonValue('full')
  full,          // Ahmet Yılmaz
  
  @JsonValue('initial')
  initial,       // Ahmet Y.
  
  @JsonValue('anonymous')
  anonymous,     // Anonim #1234
}

/// Ders listesi görünürlük türleri
enum CourseVisibilityType {
  @JsonValue('full')
  full,          // Tüm dersler
  
  @JsonValue('common')
  common,        // Sadece ortak dersler
  
  @JsonValue('hidden')
  hidden,        // Gizli
}
