import 'package:equatable/equatable.dart';

enum NotificationPriority { critical, important, normal }

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool read;
  final String? route; // optional deep link route

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.read = false,
    this.route,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? read,
    String? route,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      route: route ?? this.route,
    );
  }

  @override
  List<Object?> get props => [id, title, message, priority, createdAt, read, route];
}
