// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      studyTime: $enumDecodeNullable(
              _$StudyTimePreferenceEnumMap, json['studyTime']) ??
          StudyTimePreference.any,
      groupSize: $enumDecodeNullable(
              _$GroupSizePreferenceEnumMap, json['groupSize']) ??
          GroupSizePreference.any,
      communicationStyle: $enumDecodeNullable(
              _$CommunicationPreferenceEnumMap, json['communicationStyle']) ??
          CommunicationPreference.any,
      availability: (json['availability'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$AvailabilityEnumMap, e))
              .toList() ??
          const [Availability.any],
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'studyTime': _$StudyTimePreferenceEnumMap[instance.studyTime]!,
      'groupSize': _$GroupSizePreferenceEnumMap[instance.groupSize]!,
      'communicationStyle':
          _$CommunicationPreferenceEnumMap[instance.communicationStyle]!,
      'availability':
          instance.availability.map((e) => _$AvailabilityEnumMap[e]!).toList(),
    };

const _$StudyTimePreferenceEnumMap = {
  StudyTimePreference.day: 'day',
  StudyTimePreference.night: 'night',
  StudyTimePreference.any: 'any',
};

const _$GroupSizePreferenceEnumMap = {
  GroupSizePreference.oneOnOne: 'one_on_one',
  GroupSizePreference.smallGroup: 'small_group',
  GroupSizePreference.largeGroup: 'large_group',
  GroupSizePreference.any: 'any',
};

const _$CommunicationPreferenceEnumMap = {
  CommunicationPreference.inPerson: 'in_person',
  CommunicationPreference.online: 'online',
  CommunicationPreference.hybrid: 'hybrid',
  CommunicationPreference.any: 'any',
};

const _$AvailabilityEnumMap = {
  Availability.weekdays: 'weekdays',
  Availability.weekends: 'weekends',
  Availability.flexible: 'flexible',
  Availability.any: 'any',
};
