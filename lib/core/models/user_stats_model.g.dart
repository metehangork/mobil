// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      completedGroups: (json['completedGroups'] as num?)?.toInt() ?? 0,
      messagesSent: (json['messagesSent'] as num?)?.toInt() ?? 0,
      hoursActive: (json['hoursActive'] as num?)?.toDouble() ?? 0.0,
      matchSuccessRate: (json['matchSuccessRate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'completedGroups': instance.completedGroups,
      'messagesSent': instance.messagesSent,
      'hoursActive': instance.hoursActive,
      'matchSuccessRate': instance.matchSuccessRate,
    };
