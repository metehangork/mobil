part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String? fullName;
  final String? phone;
  final String? gender;
  final DateTime? birthDate;
  final String? city;

  const UpdateProfile({
    this.fullName,
    this.phone,
    this.gender,
    this.birthDate,
    this.city,
  });

  @override
  List<Object?> get props => [fullName, phone, gender, birthDate, city];
}

class UpdateExtendedProfile extends ProfileEvent {
  final String? bio;
  final List<String>? interests;
  final List<String>? studyHabits;
  final String? availability;

  const UpdateExtendedProfile({
    this.bio,
    this.interests,
    this.studyHabits,
    this.availability,
  });

  @override
  List<Object?> get props => [bio, interests, studyHabits, availability];
}

class UpdateSettings extends ProfileEvent {
  final bool? allowMatchRequests;
  final bool? showOnlineStatus;
  final bool? emailNotifications;
  final bool? pushNotifications;

  const UpdateSettings({
    this.allowMatchRequests,
    this.showOnlineStatus,
    this.emailNotifications,
    this.pushNotifications,
  });

  @override
  List<Object?> get props => [
        allowMatchRequests,
        showOnlineStatus,
        emailNotifications,
        pushNotifications,
      ];
}
