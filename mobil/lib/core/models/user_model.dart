import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_preferences_model.dart';
import 'user_stats_model.dart';
import 'profile_visibility_model.dart';
import 'user_badge_model.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String university;
  final String department;
  final int classYear;
  final String? studentNumber;
  final String? avatarUrl;
  final bool isVerified;
  final List<String> courses;
  final DateTime createdAt;

  // --- YENİ EKLENEN ALANLAR ---
  /// Kullanıcının kendini tanıttığı kısa metin.
  final String? bio;

  /// Kullanıcının ilgi alanları (örn: "Futbol", "Müzik", "Kitap").
  final List<String> hobbies;

  /// Kullanıcının eşleşme ve platform tercihleri.
  final UserPreferences preferences;

  /// Kullanıcının platformdaki istatistikleri.
  final UserStats stats;

  /// Profil tamamlama yüzdesi (0-100) - Oyunlaştırma için
  final int profileCompletion;

  /// Profil görünürlük ayarları (alan bazlı gizlilik)
  final ProfileVisibility visibility;

  /// Kullanıcının kazandığı rozetler
  final List<UserBadge> badges;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.university,
    required this.department,
    required this.classYear,
    this.studentNumber,
    this.avatarUrl,
    required this.isVerified,
    required this.courses,
    required this.createdAt,
    // --- YENİ ALANLARIN CONSTRUCTOR'A EKLENMESİ ---
    this.bio,
    this.hobbies = const [],
    this.preferences = const UserPreferences(),
    this.stats = const UserStats(),
    this.profileCompletion = 0,
    this.visibility = const ProfileVisibility(),
    this.badges = const [],
  });

  // firstName ve lastName getter'ları
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '';

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? university,
    String? department,
    int? classYear,
    String? studentNumber,
    String? avatarUrl,
    bool? isVerified,
    List<String>? courses,
    DateTime? createdAt,
    String? bio,
    List<String>? hobbies,
    UserPreferences? preferences,
    UserStats? stats,
    int? profileCompletion,
    ProfileVisibility? visibility,
    List<UserBadge>? badges,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      university: university ?? this.university,
      department: department ?? this.department,
      classYear: classYear ?? this.classYear,
      studentNumber: studentNumber ?? this.studentNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      courses: courses ?? this.courses,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      hobbies: hobbies ?? this.hobbies,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      visibility: visibility ?? this.visibility,
      badges: badges ?? this.badges,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        university,
        department,
        classYear,
        studentNumber,
        avatarUrl,
        isVerified,
        courses,
        createdAt,
        bio,
        hobbies,
        preferences,
        stats,
        profileCompletion,
        visibility,
        badges,
      ];
}