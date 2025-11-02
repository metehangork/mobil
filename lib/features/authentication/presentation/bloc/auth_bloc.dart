import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_preferences_model.dart';
import '../../../../core/models/user_stats_model.dart';
import '../../../../core/models/profile_visibility_model.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/firebase_notification_service.dart';

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
    on<RequestPasswordReset>(_onRequestPasswordReset);
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
    debugPrint('� AUTH BLOC: Login with email: ${event.email}');
    emit(AuthLoading());

    try {
      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      // Email ve şifre ile giriş
      final loginResponse =
          await authService.login(event.email, event.password);

      if (!loginResponse.isSuccess) {
        debugPrint('❌ AUTH BLOC: Login failed: ${loginResponse.message}');
        emit(AuthError(message: loginResponse.message ?? 'Giriş başarısız'));
        return;
      }

      // Kullanıcı bilgilerini al
      debugPrint('✅ AUTH BLOC: Login successful, fetching user profile...');
      final userService = ServiceLocator.user;
      final userResponse = await userService.getMyProfile();

      if (!userResponse.isSuccess) {
        debugPrint('❌ AUTH BLOC: Failed to fetch user profile');
        emit(const AuthError(message: 'Kullanıcı bilgileri alınamadı'));
        return;
      }

      // UserModel oluştur
      final userData = userResponse.data;
      final token = loginResponse.data['token'] ?? '';
      final user = UserModel(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? event.email,
        name: userData['full_name'] ?? 'Kullanıcı',
        university: userData['school_name'] ?? 'Bilinmiyor',
        department: userData['department_name'] ?? 'Bilinmiyor',
        classYear: userData['study_level'] ?? 1,
        isVerified: userData['is_verified'] ?? true,
        courses: const [],
        createdAt:
            DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        bio: userData['bio'],
        hobbies: (userData['interests'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        preferences: const UserPreferences(),
        stats: const UserStats(),
        profileCompletion: userData['profile_completion'] ?? 0,
        visibility: const ProfileVisibility(),
        badges: const [],
      );

      debugPrint('✅ AUTH BLOC: User authenticated: ${user.email}');
      emit(AuthAuthenticated(user: user, token: token));

      // FCM token'ı backend'e gönder
      _sendFCMTokenToBackend(token);
    } catch (e) {
      debugPrint('💥 AUTH BLOC: Login error: ${e.toString()}');
      emit(AuthError(message: 'Giriş sırasında hata oluştu: ${e.toString()}'));
    }
  }

  /// FCM token'ı backend'e gönder
  Future<void> _sendFCMTokenToBackend(String authToken) async {
    try {
      final fcmService = FirebaseNotificationService();
      final fcmToken = fcmService.fcmToken;

      if (fcmToken == null) {
        debugPrint('⚠️ FCM token henüz hazır değil');
        return;
      }

      // Platform bilgisi
      String platform = 'unknown';
      if (!kIsWeb) {
        platform = Platform.isAndroid
            ? 'android'
            : (Platform.isIOS ? 'ios' : 'unknown');
      }

      final authService = ServiceLocator.auth;
      final response = await authService.sendFCMToken(fcmToken, platform);

      if (response.isSuccess) {
        debugPrint('✅ FCM token backend\'e gönderildi');
      } else {
        debugPrint('⚠️ FCM token gönderilemedi: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ FCM token gönderme hatası: $e');
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
      debugPrint(
          '🏫 AUTH BLOC: School ID: ${event.schoolId}, Department ID: ${event.departmentId}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      // Yeni register endpoint'ini kullan (direkt token döner)
      final response = await authService.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        schoolId: event.schoolId,
        departmentId: event.departmentId,
      );

      if (response.isSuccess) {
        // Kayıt başarılı, email doğrulama gerekiyor
        emit(AuthRegistrationSuccess(email: event.email));
        debugPrint(
            '✅ AUTH BLOC: Registration success, email verification required');
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
          courses: const [],
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
      emit(AuthLoading());
      debugPrint('📧 AUTH BLOC: Sending verification code for ${event.email}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      final response = await authService.requestVerificationCode(event.email);

      if (response.isSuccess) {
        debugPrint('✅ AUTH BLOC: Verification code sent successfully');
        // Login için de aynı state'i emit et
        emit(AuthRegistrationSuccess(email: event.email));
      } else {
        debugPrint('❌ AUTH BLOC: Failed to send code: ${response.message}');
        emit(AuthError(message: response.message ?? 'Kod gönderilemedi'));
      }
    } catch (e) {
      debugPrint('💥 AUTH BLOC: Send code error: $e');
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
        emit(
            const AuthError(message: 'Profil güncellenirken bir hata oluştu.'));
      }
    }
  }

  Future<void> _onRequestPasswordReset(
      RequestPasswordReset event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      debugPrint('🔄 AUTH BLOC: Password reset requested for ${event.email}');

      // GERÇEK API KULLANIMI - ServiceLocator üzerinden AuthService
      final authService = ServiceLocator.auth;

      // Şifre sıfırlama isteği gönder
      final response = await authService.forgotPassword(email: event.email);

      if (response.isSuccess) {
        emit(PasswordResetRequested());
        debugPrint('✅ AUTH BLOC: Password reset email sent');
      } else {
        String message =
            response.message ?? 'Şifre sıfırlama sırasında hata oluştu';
        emit(AuthError(message: message));
        debugPrint('❌ AUTH BLOC: Password reset request failed: $message');
      }
    } catch (e) {
      debugPrint('💥 AUTH BLOC: Password reset error: ${e.toString()}');
      emit(AuthError(
          message: 'Şifre sıfırlama sırasında hata oluştu: ${e.toString()}'));
    }
  }
}
