import 'package:bloc/bloc.dart';
import '../../../../core/models/app_notification.dart';
import '../../data/mock_notification_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final MockNotificationRepository repository;
  List<AppNotification> _items = const [];

  NotificationsCubit({MockNotificationRepository? repository})
      : repository = repository ?? MockNotificationRepository(),
        super(NotificationsInitial());

  Future<void> load() async {
    emit(NotificationsLoading());
    try {
      final items = await repository.fetchNotifications();
      _items = items;
      if (items.isEmpty) {
        emit(NotificationsEmpty());
      } else {
        emit(NotificationsLoaded(items));
      }
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  void markAsRead(String id) {
    _items = _items
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList(growable: false);
    emit(NotificationsLoaded(_items));
  }

  int unreadCount() => _items.where((n) => !n.read).length;
}
