import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import 'dart:async';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/email_verification_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/reset_password_page.dart';
import '../../features/home/presentation/pages/home_root_screen.dart';
import '../../features/courses/presentation/pages/courses_root_screen.dart';
import '../../features/groups/presentation/pages/groups_root_screen.dart';
import '../../features/messages/presentation/pages/messages_root_screen.dart';
import '../../features/profile/presentation/pages/profile_root_screen.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../navigation/navigation_shell.dart';
import '../navigation/app_routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // AuthBloc stream'ini dinleyip GoRouter'a refresh tetiklemek için yardımcı
  // (GoRouter 10+ sürümünde refreshListenable veya Stream listen approach)
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.welcome,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // Auth routes
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        // Notifications
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          name: 'verify-email',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return EmailVerificationPage(email: email);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset-password',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return ResetPasswordPage(email: email);
          },
        ),

        // Main shell with bottom navigation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return NavigationShell(
              currentIndex: navigationShell.currentIndex,
              onTabChanged: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              child: navigationShell,
            );
          },
          branches: [
            // Home tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${AppRoutes.home}',
                  builder: (context, state) => const HomeRootScreen(),
                ),
              ],
            ),

            // Courses tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${AppRoutes.courses}',
                  builder: (context, state) => const CoursesRootScreen(),
                ),
              ],
            ),

            // Groups tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${AppRoutes.groups}',
                  builder: (context, state) => const GroupsRootScreen(),
                ),
              ],
            ),

            // Messages tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${AppRoutes.messages}',
                  builder: (context, state) => const MessagesRootScreen(),
                ),
              ],
            ),

            // Profile tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/${AppRoutes.profile}',
                  builder: (context, state) => const ProfileRootScreen(),
                  routes: [
                    GoRoute(
                      path: AppRoutes.profileEdit,
                      name: 'profile-edit',
                      builder: (context, state) => const ProfileEditPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthenticated = authState is AuthAuthenticated;

        final isAuthRoute = state.matchedLocation.startsWith('/welcome') ||
            state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register') ||
            state.matchedLocation.startsWith('/verify-email');

        final isMainRoute = state.matchedLocation.startsWith('/home') ||
            state.matchedLocation.startsWith('/courses') ||
            state.matchedLocation.startsWith('/groups') ||
            state.matchedLocation.startsWith('/messages') ||
            state.matchedLocation.startsWith('/profile');

        // Redirect to welcome if not authenticated and trying to access main routes
        if (!isAuthenticated && isMainRoute) {
          return AppRoutes.welcome;
        }

        // Redirect to home if authenticated and on auth routes
        if (isAuthenticated && isAuthRoute) {
          return '/${AppRoutes.home}';
        }

        return null;
      },
    );
  }
}

// Stream'den change bildirimi üretmek için basit ChangeNotifier köprüsü
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
