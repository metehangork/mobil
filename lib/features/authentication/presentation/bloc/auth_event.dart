part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String university;
  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.university,
  });
  @override
  List<Object?> get props => [email, password, firstName, lastName, university];
}

class AuthVerifyEmailEvent extends AuthEvent {
  final String email;
  final String code;
  const AuthVerifyEmailEvent({required this.email, required this.code});
  @override
  List<Object?> get props => [email, code];
}

class AuthUpdateProfileEvent extends AuthEvent {
  final UserModel updatedUser;
  const AuthUpdateProfileEvent({required this.updatedUser});
  @override
  List<Object?> get props => [updatedUser];
}

class AuthResendCodeEvent extends AuthEvent {
  const AuthResendCodeEvent();
}