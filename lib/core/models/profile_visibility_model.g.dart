// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_visibility_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileVisibility _$ProfileVisibilityFromJson(Map<String, dynamic> json) =>
    ProfileVisibility(
      profile: $enumDecodeNullable(_$VisibilityLevelEnumMap, json['profile']) ??
          VisibilityLevel.university,
      avatar: $enumDecodeNullable(_$VisibilityLevelEnumMap, json['avatar']) ??
          VisibilityLevel.matches,
      name: $enumDecodeNullable(_$NameDisplayTypeEnumMap, json['name']) ??
          NameDisplayType.full,
      department:
          $enumDecodeNullable(_$VisibilityLevelEnumMap, json['department']) ??
              VisibilityLevel.university,
      courses:
          $enumDecodeNullable(_$CourseVisibilityTypeEnumMap, json['courses']) ??
              CourseVisibilityType.common,
    );

Map<String, dynamic> _$ProfileVisibilityToJson(ProfileVisibility instance) =>
    <String, dynamic>{
      'profile': _$VisibilityLevelEnumMap[instance.profile]!,
      'avatar': _$VisibilityLevelEnumMap[instance.avatar]!,
      'name': _$NameDisplayTypeEnumMap[instance.name]!,
      'department': _$VisibilityLevelEnumMap[instance.department]!,
      'courses': _$CourseVisibilityTypeEnumMap[instance.courses]!,
    };

const _$VisibilityLevelEnumMap = {
  VisibilityLevel.public: 'public',
  VisibilityLevel.university: 'university',
  VisibilityLevel.matches: 'matches',
  VisibilityLevel.private: 'private',
};

const _$NameDisplayTypeEnumMap = {
  NameDisplayType.full: 'full',
  NameDisplayType.initial: 'initial',
  NameDisplayType.anonymous: 'anonymous',
};

const _$CourseVisibilityTypeEnumMap = {
  CourseVisibilityType.full: 'full',
  CourseVisibilityType.common: 'common',
  CourseVisibilityType.hidden: 'hidden',
};
