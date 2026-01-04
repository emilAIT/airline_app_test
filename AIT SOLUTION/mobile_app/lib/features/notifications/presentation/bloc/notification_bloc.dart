import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification.dart';

// --- EVENTS ---
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final bool refresh;
  const LoadNotifications({this.refresh = false});
}

class MarkAsRead extends NotificationEvent {
  final int notificationId;
  const MarkAsRead(this.notificationId);
}

class MarkAllAsRead extends NotificationEvent {}

// --- STATES ---
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object> get props => [message];
}

// --- BLOC ---
@injectable
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiClient _apiClient;

  NotificationBloc(this._apiClient) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded || event.refresh) {
      emit(NotificationLoading());
    }

    try {
      final response = await _apiClient.dio.get('/notifications/');
      final data = response.data as List;
      final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      
      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      
      // Optimistic update
      final updatedList = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return NotificationEntity(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true, // Mark as read
            createdAt: n.createdAt,
            bookingId: n.bookingId,
            flightId: n.flightId,
          );
        }
        return n;
      }).toList();

      final newUnreadCount = updatedList.where((n) => !n.isRead).length;

      emit(NotificationLoaded(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      ));

      // Network call
      try {
        await _apiClient.dio.post('/notifications/${event.notificationId}/read');
      } catch (e) {
        // Revert on error (optional implementation)
        add(const LoadNotifications(refresh: true));
      }
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      
      // Optimistic update
      final updatedList = currentState.notifications.map((n) {
        return NotificationEntity(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          isRead: true, 
          createdAt: n.createdAt,
          bookingId: n.bookingId,
          flightId: n.flightId,
        );
      }).toList();

      emit(NotificationLoaded(
        notifications: updatedList,
        unreadCount: 0,
      ));

      try {
        await _apiClient.dio.post('/notifications/mark-all-read');
      } catch (e) {
         add(const LoadNotifications(refresh: true));
      }
    }
  }
}
