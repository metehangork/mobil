import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../../core/models/user_model.dart';
import '../../../../core/config/app_config.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static String get _baseUrl => AppConfig.effectiveApiBaseUrl;

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthRegisterEvent>(_onRegisterRequested);
    on<AuthVerifyEmailEvent>(_onVerifyEmail);
    on<AuthResendCodeEvent>(_onResendCode);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
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
              name: (decoded['firstName'] != null || decoded['lastName'] != null)
                  ? '${decoded['firstName'] ?? ''} ${decoded['lastName'] ?? ''}'.trim()
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
                  ? (decoded['courses'] as List).map((e) => e.toString()).toList()
                  : <String>[],
              createdAt: DateTime.tryParse(decoded['createdAt'].toString()) ?? DateTime.now(),
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
      // TODO: Gerçek login API entegrasyonu
      await Future.delayed(const Duration(milliseconds: 800));
      debugPrint('✅ AUTH BLOC: Mock login successful (replace with real API)');
      final user = UserModel(
        id: 'local-login',
        email: event.email,
        name: event.email.split('@').first,
        university: 'Bilinmiyor',
        department: 'Bilinmiyor',
        classYear: 1,
        isVerified: true,
        courses: const [],
        createdAt: DateTime.now(),
      );
      const token = 'mock_login_token';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, json.encode(user.toJson()));
      emit(AuthAuthenticated(user: user, token: token));
    } catch (e) {
      debugPrint('❌ AUTH BLOC: Login error: ${e.toString()}');
      emit(AuthError(message: 'Giriş sırasında hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Çıkış sırasında hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    emit(AuthUnauthenticated());
  }

  Future<void> _onRegisterRequested(AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final started = DateTime.now();
      debugPrint('🔄 AUTH BLOC: Starting registration for ${event.email} -> POST /api/auth/request-verification');
      debugPrint('🌐 AUTH BLOC: Using API URL: $_baseUrl');
      final uri = Uri.parse('$_baseUrl/auth/request-verification');
      http.Response response;
      try {
        response = await http
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: json.encode({
                'email': event.email,
                'firstName': event.firstName,
                'lastName': event.lastName,
                'university': event.university,
              }),
            )
            .timeout(const Duration(seconds: 12));
      } on TimeoutException {
        debugPrint('⏱️ AUTH BLOC: Registration request timeout');
        emit(const AuthError(message: 'Sunucu yanıt vermedi (timeout).'));
        return;
      } on SocketException catch (se) {
        debugPrint('🌐 AUTH BLOC: Network error (SocketException): $se');
        emit(const AuthError(message: 'Ağ hatası: Sunucuya ulaşılamadı'));
        return;
      }

      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      debugPrint('🔄 AUTH BLOC: Registration response (${response.statusCode}) in ${elapsedMs}ms');
      String bodyPreview = response.body.length > 400 ? response.body.substring(0, 400) + '…(truncated)' : response.body;
      debugPrint('🧪 AUTH BLOC: Response body preview: $bodyPreview');

      if (response.statusCode == 200) {
        emit(AuthRegistrationSuccess(email: event.email));
        debugPrint('✅ AUTH BLOC: Registration success -> navigating to verify screen');
      } else {
        String message = _extractErrorMessage(response.body) ?? 'Kayıt sırasında hata (HTTP ${response.statusCode})';
        emit(AuthError(message: message));
        debugPrint('❌ AUTH BLOC: Registration failed message: $message');
      }
    } catch (e, st) {
      debugPrint('💥 AUTH BLOC: Registration unexpected error: $e');
      debugPrint(st.toString());
      emit(const AuthError(message: 'Beklenmeyen hata oluştu'));
    }
  }

  Future<void> _onVerifyEmail(AuthVerifyEmailEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoading) {
      debugPrint('⚠️ AUTH BLOC: Already loading, ignoring duplicate verify request');
      return;
    }
    emit(AuthLoading());
    try {
      final started = DateTime.now();
      debugPrint('🔄 AUTH BLOC: Verifying code for ${event.email} -> POST /api/auth/verify-code');
      debugPrint('🌐 AUTH BLOC: Using API URL: $_baseUrl');
      final uri = Uri.parse('$_baseUrl/auth/verify-code');
      http.Response response;
      try {
        response = await http
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: json.encode({'email': event.email, 'code': event.code}),
            )
            .timeout(const Duration(seconds: 12));
      } on TimeoutException {
        debugPrint('⏱️ AUTH BLOC: Verification timeout');
        emit(const AuthError(message: 'Sunucu yanıt vermedi. Lütfen tekrar deneyin.'));
        return;
      } on SocketException catch (se) {
        debugPrint('🌐 AUTH BLOC: Verify network error: $se');
        emit(const AuthError(message: 'Ağ hatası: Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.'));
        return;
      }

      final elapsedMs = DateTime.now().difference(started).inMilliseconds;
      debugPrint('🔄 AUTH BLOC: Verify response (${response.statusCode}) in ${elapsedMs}ms');
      String bodyPreview = response.body.length > 400 ? response.body.substring(0, 400) + '…(truncated)' : response.body;
      debugPrint('🧪 AUTH BLOC: Verify body preview: $bodyPreview');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('📦 AUTH BLOC: Response data keys: ${responseData.keys}');
        
        final userData = responseData['user'];
        final token = responseData['token'];
        
        if (userData == null || token == null) {
          debugPrint('❌ AUTH BLOC: Missing user data or token in response');
          emit(const AuthError(message: 'Sunucu yanıtı eksik. Lütfen tekrar deneyin.'));
          return;
        }
        
        final user = UserModel(
          id: userData['id'].toString(),
          email: userData['email'],
          name: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
          university: userData['university'] ?? 'Bilinmiyor',
          department: userData['department'] ?? 'Bilinmiyor',
          classYear: userData['classYear'] ?? 1,
          isVerified: userData['isVerified'] ?? true,
          courses: [],
          createdAt: DateTime.now(),
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(user.toJson()));
        
        debugPrint('✅ AUTH BLOC: Verification success -> user authenticated');
        debugPrint('👤 AUTH BLOC: User: ${user.name} (${user.email})');
        
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        String message = _extractErrorMessage(response.body) ?? 'Doğrulama kodu hatalı veya süresi dolmuş (HTTP ${response.statusCode})';
        emit(AuthError(message: message));
        debugPrint('❌ AUTH BLOC: Verification failed message: $message');
      }
    } catch (e, st) {
      debugPrint('💥 AUTH BLOC: Verification unexpected error: $e');
      debugPrint(st.toString());
      emit(AuthError(message: 'Beklenmeyen hata oluştu: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(AuthUpdateProfileEvent event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      // Burada normalde API'ye bir istek gönderilir.
      // Şimdilik sadece state'i güncelleyip local'de kalıcı hale getirelim.
      try {
        emit(AuthLoading()); // Arayüzde yükleniyor durumu göster
        await Future.delayed(const Duration(milliseconds: 500)); // Mock network delay

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(event.updatedUser.toJson()));

        // State'i yeni kullanıcı bilgileriyle güncelle
        emit(AuthAuthenticated(user: event.updatedUser, token: currentState.token));
        debugPrint('✅ AUTH BLOC: Profile updated successfully.');
      } catch (e) {
        debugPrint('❌ AUTH BLOC: Profile update failed: $e');
        // Hata durumunda eski state'e geri dön
        emit(currentState);
        emit(const AuthError(message: 'Profil güncellenirken bir hata oluştu.'));
      }
    }
  }

  // Attempts to extract a meaningful error string from various backend shapes
  String? _extractErrorMessage(String raw) {
    try {
      final data = json.decode(raw);
      if (data is Map) {
        if (data['message'] is String) return data['message'];
        if (data['error'] is String) return data['error'];
        if (data['errors'] is List && data['errors'].isNotEmpty) {
          final first = data['errors'].first;
          if (first is Map) {
            return (first['msg'] ?? first['message'] ?? first['error'])?.toString();
          } else {
            return first.toString();
          }
        }
      }
    } catch (_) {
      return null; // raw body not JSON or parse failed
    }
    return null;
  }

  Future<void> _onResendCode(AuthResendCodeEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(message: 'Kod gönderilemedi: ${e.toString()}'));
    }
  }
}