import 'dart:convert';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/services/service_locator.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthRegisterEvent>(_onRegisterRequested);
    on<AuthVerifyEmailEvent>(_onVerifyEmail);
    on<AuthResendCodeEvent>(_onResendCode);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
    // Initial auth check
    add(const AuthCheckStatus());
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final rawUser = prefs.getString(_userKey);
      if (token != null && rawUser != null) {
        try {
          final decoded = json.decode(rawUser);
          UserModel user;
          if (decoded is Map<String, dynamic>) {
            // createdAt olmayabilir -> varsayılan ver
            if (!decoded.containsKey('createdAt')) {
              decoded['createdAt'] = DateTime.now().toIso8601String();
            }
            // Backend ile model alanları tam eşleşmeyebilir -> eksik alanları doldur
            user = UserModel(
              id: (decoded['id'] ?? '0').toString(),
              email: decoded['email'] ?? '',
              name: (decoded['firstName'] != null ||
                      decoded['lastName'] != null)
                  ? '${decoded['firstName'] ?? ''} ${decoded['lastName'] ?? ''}'
                      .trim()
                  : (decoded['name'] ?? ''),
              university: decoded['university'] ?? 'Bilinmiyor',
              department: decoded['department'] ?? 'Bilinmiyor',
              classYear: (decoded['classYear'] is int)
                  ? decoded['classYear']
                  : int.tryParse('${decoded['classYear'] ?? '1'}') ?? 1,
              studentNumber: decoded['studentNumber']?.toString(),
              avatarUrl: decoded['avatarUrl']?.toString(),
              isVerified: decoded['isVerified'] ?? true,
              courses: (decoded['courses'] is List)
                  ? (decoded['courses'] as List)
                      .map((e) => e.toString())
                      .toList()
                  : <String>[],
              createdAt: DateTime.tryParse(decoded['createdAt'].toString()) ??
                  DateTime.now(),
            );
          } else {
            debugPrint('⚠️ AUTH BLOC: Stored user is not a Map, resetting.');
            emit(AuthUnauthenticated());
            return;
          }
          emit(AuthAuthenticated(user: user, token: token));
          return;
        } catch (e) {
          debugPrint('⚠️ AUTH BLOC: Failed to parse stored user JSON: $e');
        }
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('Auth status check error: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    debugPrint('🔥 AUTH BLOC: _onLogin called with email: ${event.email}');
    emit(AuthLoading());

    try {
      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      // Email ile verification code iste
      debugPrint(
          '📧 AUTH BLOC: Requesting verification code for ${event.email}');
      final codeResponse =
          await authService.requestVerificationCode(event.email);

      if (!codeResponse.isSuccess) {
        emit(AuthError(message: codeResponse.message ?? 'Email gönderilemedi'));
        return;
      }

      // Kullanıcı verification code'u girmeli - şimdilik email verification sayfasına yönlendir
      // NOT: Login için şifre yerine email verification kullanıyoruz
      emit(AuthError(message: 'Lütfen email adresinize gelen kodu girin'));
    } catch (e) {
      debugPrint('❌ AUTH BLOC: Login error: ${e.toString()}');
      emit(AuthError(message: 'Giriş sırasında hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Çıkış sırasında hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      debugPrint('🔄 AUTH BLOC: Starting registration for ${event.email}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      // Email verification code iste
      final response = await authService.requestVerificationCode(event.email);

      if (response.isSuccess) {
        emit(AuthRegistrationSuccess(email: event.email));
        debugPrint(
            '✅ AUTH BLOC: Registration success -> navigating to verify screen');
      } else {
        String message = response.message ?? 'Kayıt sırasında hata oluştu';
        emit(AuthError(message: message));
        debugPrint('❌ AUTH BLOC: Registration failed: $message');
      }
    } catch (e, st) {
      debugPrint('💥 AUTH BLOC: Registration unexpected error: $e');
      debugPrint(st.toString());
      emit(AuthError(message: 'Beklenmeyen hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyEmail(
      AuthVerifyEmailEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoading) {
      debugPrint(
          '⚠️ AUTH BLOC: Already loading, ignoring duplicate verify request');
      return;
    }

    emit(AuthLoading());

    try {
      debugPrint('🔄 AUTH BLOC: Verifying code for ${event.email}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;
      final userService = ServiceLocator.user;

      // Kodu doğrula
      final response = await authService.verifyCode(event.email, event.code);

      if (response.isSuccess) {
        debugPrint('✅ AUTH BLOC: Verification successful');

        // Token otomatik olarak AuthService tarafından kaydedildi
        final token = await authService.getToken();

        if (token == null) {
          emit(const AuthError(message: 'Token kaydedilemedi'));
          return;
        }

        // Kullanıcı profilini çek
        final profileResponse = await userService.getMyProfile();

        if (!profileResponse.isSuccess) {
          emit(AuthError(
              message:
                  profileResponse.message ?? 'Profil bilgileri alınamadı'));
          return;
        }

        // UserModel oluştur
        final userData = profileResponse.data!;
        final user = UserModel(
          id: userData['id'].toString(),
          email: userData['email'] ?? event.email,
          name: userData['full_name'] ?? 'Kullanıcı',
          university: userData['school_name'] ?? 'Bilinmiyor',
          department: userData['department_name'] ?? 'Bilinmiyor',
          classYear: userData['study_level'] ?? 1,
          isVerified: userData['is_verified'] ?? true,
          courses: [],
          createdAt:
              DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
          bio: userData['bio'],
          hobbies: (userData['interests'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
        );

        // SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user.toJson()));

        debugPrint('✅ AUTH BLOC: User authenticated: ${user.name}');
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        String message = response.message ?? 'Doğrulama kodu hatalı';
        emit(AuthError(message: message));
        debugPrint('❌ AUTH BLOC: Verification failed: $message');
      }
    } catch (e, st) {
      debugPrint('💥 AUTH BLOC: Verification unexpected error: $e');
      debugPrint(st.toString());
      emit(AuthError(message: 'Beklenmeyen hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onResendCode(
      AuthResendCodeEvent event, Emitter<AuthState> emit) async {
    try {
      debugPrint('� AUTH BLOC: Resending verification code for ${event.email}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      final response = await authService.requestVerificationCode(event.email);

      if (response.isSuccess) {
        debugPrint('✅ AUTH BLOC: Verification code resent successfully');
        // State değiştirmiyoruz, sadece başarılı olduğunu log'luyoruz
        // UI'da SnackBar ile bilgi verilebilir
      } else {
        debugPrint('❌ AUTH BLOC: Failed to resend code: ${response.message}');
        emit(AuthError(message: response.message ?? 'Kod gönderilemedi'));
      }
    } catch (e) {
      debugPrint('💥 AUTH BLOC: Resend code error: $e');
      emit(AuthError(message: 'Kod gönderirken hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
      AuthUpdateProfileEvent event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;

      try {
        emit(AuthLoading());

        // GERÇEK API KULLANIMI - ServiceLocator üzerinden UserService
        final userService = ServiceLocator.user;

        // Profili güncelle
        final response = await userService.updateProfile({
          'full_name': event.updatedUser.name,
          // Diğer alanlar da eklenebilir
        });

        if (response.isSuccess) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              _userKey, json.encode(event.updatedUser.toJson()));

          emit(AuthAuthenticated(
              user: event.updatedUser, token: currentState.token));
          debugPrint('✅ AUTH BLOC: Profile updated successfully.');
        } else {
          emit(currentState);
          emit(AuthError(message: response.message ?? 'Profil güncellenemedi'));
        }
      } catch (e) {
        debugPrint('❌ AUTH BLOC: Profile update failed: $e');
        emit(currentState);
        emit(AuthError(message: 'Profil güncellenirken bir hata oluştu.'));
      }
    }
  }
}
