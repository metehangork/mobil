// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_badge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserBadge _$UserBadgeFromJson(Map<String, dynamic> json) => UserBadge(
      id: json['id'] as String,
      type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );

Map<String, dynamic> _$UserBadgeToJson(UserBadge instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$BadgeTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'earnedAt': instance.earnedAt.toIso8601String(),
    };

const _$BadgeTypeEnumMap = {
  BadgeType.verified: 'verified',
  BadgeType.helpful: 'helpful',
  BadgeType.leader: 'leader',
  BadgeType.expert: 'expert',
  BadgeType.contributor: 'contributor',
  BadgeType.earlyBird: 'early_bird',
};
