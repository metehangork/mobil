import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/service_locator.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateExtendedProfile>(_onUpdateExtendedProfile);
    on<UpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final userService = ServiceLocator.user;
      final response = await userService.getMyProfile();

      if (response.isSuccess && response.data != null) {
        emit(ProfileLoaded(profile: response.data!));
      } else {
        emit(ProfileError(message: response.message ?? 'Profil yüklenemedi'));
      }
    } catch (e) {
      emit(ProfileError(message: 'Beklenmeyen hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    emit(ProfileLoading());

    try {
      final userService = ServiceLocator.user;
      final response = await userService.updateProfile({
        if (event.fullName != null) 'full_name': event.fullName,
        if (event.phone != null) 'phone': event.phone,
        if (event.gender != null) 'gender': event.gender,
        if (event.birthDate != null) 'birth_date': event.birthDate,
        if (event.city != null) 'city': event.city,
      });

      if (response.isSuccess) {
        // Profili yeniden yükle
        add(LoadProfile());
      } else {
        if (currentState is ProfileLoaded) {
          emit(currentState);
        }
        emit(
            ProfileError(message: response.message ?? 'Profil güncellenemedi'));
      }
    } catch (e) {
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
      emit(ProfileError(message: 'Beklenmeyen hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateExtendedProfile(
    UpdateExtendedProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    emit(ProfileLoading());

    try {
      final userService = ServiceLocator.user;
      final response = await userService.updateExtendedProfile({
        if (event.bio != null) 'bio': event.bio,
        if (event.interests != null) 'interests': event.interests,
        if (event.studyHabits != null) 'study_habits': event.studyHabits,
        if (event.availability != null) 'availability': event.availability,
      });

      if (response.isSuccess) {
        add(LoadProfile());
      } else {
        if (currentState is ProfileLoaded) {
          emit(currentState);
        }
        emit(
            ProfileError(message: response.message ?? 'Profil güncellenemedi'));
      }
    } catch (e) {
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
      emit(ProfileError(message: 'Beklenmeyen hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettings event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final userService = ServiceLocator.user;
      await userService.updateSettings({
        if (event.allowMatchRequests != null)
          'allow_match_requests': event.allowMatchRequests,
        if (event.showOnlineStatus != null)
          'show_online_status': event.showOnlineStatus,
        if (event.emailNotifications != null)
          'email_notifications': event.emailNotifications,
        if (event.pushNotifications != null)
          'push_notifications': event.pushNotifications,
      });

      // Settings güncellemesi profil state'ini değiştirmez
      // Sadece başarılı olduğunu gösterebiliriz
    } catch (e) {
      emit(ProfileError(message: 'Ayarlar güncellenemedi: ${e.toString()}'));
    }
  }
}
