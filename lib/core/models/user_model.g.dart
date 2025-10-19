// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      university: json['university'] as String,
      department: json['department'] as String,
      classYear: (json['classYear'] as num).toInt(),
      studentNumber: json['studentNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
      courses:
          (json['courses'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      bio: json['bio'] as String?,
      hobbies: (json['hobbies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferences: json['preferences'] == null
          ? const UserPreferences()
          : UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>),
      stats: json['stats'] == null
          ? const UserStats()
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      profileCompletion: (json['profileCompletion'] as num?)?.toInt() ?? 0,
      visibility: json['visibility'] == null
          ? const ProfileVisibility()
          : ProfileVisibility.fromJson(
              json['visibility'] as Map<String, dynamic>),
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'university': instance.university,
      'department': instance.department,
      'classYear': instance.classYear,
      'studentNumber': instance.studentNumber,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'courses': instance.courses,
      'createdAt': instance.createdAt.toIso8601String(),
      'bio': instance.bio,
      'hobbies': instance.hobbies,
      'preferences': instance.preferences.toJson(),
      'stats': instance.stats.toJson(),
      'profileCompletion': instance.profileCompletion,
      'visibility': instance.visibility.toJson(),
      'badges': instance.badges.map((e) => e.toJson()).toList(),
    };
