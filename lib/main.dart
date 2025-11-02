import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/service_locator.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/services/socket_service.dart';
import 'core/config/app_config.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase'i başlat
    await Firebase.initializeApp();

    // Initialize Firebase & Notifications
    await FirebaseNotificationService().initialize();

    // Initialize all API services
    await ServiceLocator.initialize();
  } catch (e, st) {
    log('❌ Application failed to initialize', error: e, stackTrace: st);
    return;
  }

  runApp(const UniCampusApp());
}

class UniCampusApp extends StatefulWidget {
  const UniCampusApp({super.key});

  @override
  State<UniCampusApp> createState() => _UniCampusAppState();
}

class _UniCampusAppState extends State<UniCampusApp> {
  final SocketService _socketService = SocketService();
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: Builder(
        builder: (context) {
          // AuthBloc referansını al
          final authBloc = context.read<AuthBloc>();

          // İLK DEFA için: Hem initial state'i kontrol et HEM de listener'ı kur
          if (!_hasInitialized) {
            _hasInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentState = authBloc.state;
              print(
                  '🔍 [MAIN Init] Initial state: ${currentState.runtimeType}');

              // Eğer zaten authenticated ise socket'i başlat
              if (currentState is AuthAuthenticated) {
                print(
                    '🔥 [MAIN Init] Kullanıcı zaten giriş yapmış, Socket başlatılıyor...');
                final serverUrl =
                    AppConfig.effectiveApiBaseUrl.replaceAll('/api', '');
                _socketService.connect(serverUrl, currentState.token);
              }

              // AuthBloc değişikliklerini dinle
              authBloc.stream.listen((state) {
                print('🔍 [MAIN Stream] State değişti: ${state.runtimeType}');
                if (state is AuthAuthenticated) {
                  print(
                      '🔥 [MAIN Stream] Kullanıcı giriş yaptı, Socket başlatılıyor...');
                  final serverUrl =
                      AppConfig.effectiveApiBaseUrl.replaceAll('/api', '');
                  _socketService.connect(serverUrl, state.token);
                } else if (state is AuthUnauthenticated) {
                  print(
                      '❌ [MAIN Stream] Kullanıcı çıkış yaptı, Socket kapatılıyor...');
                  _socketService.disconnect();
                }
              });
            });
          }

          return MaterialApp.router(
            title: 'Kafadar Kampüs',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.createRouter(authBloc),
          );
        },
      ),
    );
  }
}
