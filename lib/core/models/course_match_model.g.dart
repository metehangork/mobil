// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseMatchModel _$CourseMatchModelFromJson(Map<String, dynamic> json) =>
    CourseMatchModel(
      id: json['id'] as String,
      matchedUser:
          UserModel.fromJson(json['matchedUser'] as Map<String, dynamic>),
      commonCourses: (json['commonCourses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CourseMatchModelToJson(CourseMatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchedUser': instance.matchedUser,
      'commonCourses': instance.commonCourses,
      'compatibilityScore': instance.compatibilityScore,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      credits: (json['credits'] as num).toInt(),
      professor: json['professor'] as String?,
    );

Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'department': instance.department,
      'credits': instance.credits,
      'professor': instance.professor,
    };
