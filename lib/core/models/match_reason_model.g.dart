// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_reason_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchReason _$MatchReasonFromJson(Map<String, dynamic> json) => MatchReason(
      type: $enumDecode(_$MatchReasonTypeEnumMap, json['type']),
      displayText: json['displayText'] as String,
      data: json['data'] as String?,
      urgency: (json['urgency'] as num?)?.toInt() ?? 5,
      icon: json['icon'] as String? ?? '🎯',
    );

Map<String, dynamic> _$MatchReasonToJson(MatchReason instance) =>
    <String, dynamic>{
      'type': _$MatchReasonTypeEnumMap[instance.type]!,
      'displayText': instance.displayText,
      'data': instance.data,
      'urgency': instance.urgency,
      'icon': instance.icon,
    };

const _$MatchReasonTypeEnumMap = {
  MatchReasonType.criticalCourse: 'critical_course',
  MatchReasonType.sharedCourse: 'shared_course',
  MatchReasonType.sharedInterest: 'shared_interest',
  MatchReasonType.studyTime: 'study_time',
  MatchReasonType.sameClass: 'same_class',
  MatchReasonType.complementary: 'complementary',
  MatchReasonType.location: 'location',
};

Match _$MatchFromJson(Map<String, dynamic> json) => Match(
      id: json['id'] as String,
      userId: json['userId'] as String,
      otherId: json['otherId'] as String,
      score: (json['score'] as num).toInt(),
      reasons: (json['reasons'] as List<dynamic>)
          .map((e) => MatchReason.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$MatchStatusEnumMap, json['status']),
      firstMessageTemplate: json['firstMessageTemplate'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
    );

Map<String, dynamic> _$MatchToJson(Match instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'otherId': instance.otherId,
      'score': instance.score,
      'reasons': instance.reasons,
      'status': _$MatchStatusEnumMap[instance.status]!,
      'firstMessageTemplate': instance.firstMessageTemplate,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
    };

const _$MatchStatusEnumMap = {
  MatchStatus.pending: 'pending',
  MatchStatus.accepted: 'accepted',
  MatchStatus.declined: 'declined',
  MatchStatus.expired: 'expired',
};
