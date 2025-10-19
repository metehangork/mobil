import 'package:equatable/equatable.dart';
import '../../../../core/models/app_notification.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsEmpty extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> items;
  const NotificationsLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
