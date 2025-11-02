part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;
  const AuthAuthenticated({required this.user, required this.token});
  @override
  List<Object?> get props => [user, token];
}

class AuthRegistrationSuccess extends AuthState {
  final String email;
  const AuthRegistrationSuccess({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthEmailVerified extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class PasswordResetRequested extends AuthState {}
