/// Notification State Management Provider
/// 
/// Manages in-app notifications, alerts, and notification filtering.
/// Provides methods for adding, reading, and removing notifications.
/// 
/// Features:
/// - Notification CRUD operations
/// - Unread notification tracking
/// - Type-based filtering (appointments, health, system)
/// - In-app notification display
/// - Batch operations (mark all read, clear all)
library;
import 'package:flutter/material.dart';

/// Notification state management provider
/// 
/// Handles all notification-related operations including creation,
/// reading status management, and filtering by type.
class NotificationProvider extends ChangeNotifier {
  // Notification storage
  final List<AppNotification> _notifications = [];
  final List<AppNotification> _unreadNotifications = [];
  
  // Loading and error state
  final bool _isLoading = false;
  String? _error;
  
  // Filter state
  NotificationFilter _currentFilter = NotificationFilter.all;

  // Public getters for notification access
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NotificationFilter get currentFilter => _currentFilter;
  int get unreadCount => _unreadNotifications.length;
  bool get hasUnread => _unreadNotifications.isNotEmpty;

  /// Add a new notification
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadNotifications.add(notification);
    }
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadNotifications.clear();
    notifyListeners();
  }

  /// Remove notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _unreadNotifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadNotifications.clear();
    notifyListeners();
  }

  /// Set notification filter
  void setFilter(NotificationFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Get filtered notifications
  List<AppNotification> getFilteredNotifications() {
    switch (_currentFilter) {
      case NotificationFilter.all:
        return _notifications;
      case NotificationFilter.unread:
        return _unreadNotifications;
      case NotificationFilter.read:
        return _notifications.where((n) => n.isRead).toList();
      case NotificationFilter.appointments:
        return _notifications
            .where((n) => n.type == NotificationType.appointment)
            .toList();
      case NotificationFilter.health:
        return _notifications
            .where((n) => n.type == NotificationType.health)
            .toList();
      case NotificationFilter.system:
        return _notifications
            .where((n) => n.type == NotificationType.system)
            .toList();
    }
  }

  /// Show in-app notification (like a snackbar or toast)
  void showInAppNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      onTap: onTap,
    );

    addNotification(notification);

    // Auto-remove after duration for temporary notifications
    if (type == NotificationType.info || type == NotificationType.success) {
      Future<void>.delayed(duration, () {
        removeNotification(notification.id);
      });
    }
  }

  /// Show success notification
  void showSuccess(String message, {String? title}) {
    showInAppNotification(
      title: title ?? 'Success',
      message: message,
      type: NotificationType.success,
    );
  }

  /// Show error notification
  void showError(String message, {String? title}) {
    showInAppNotification(
      title: title ?? 'Error',
      message: message,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Show warning notification
  void showWarning(String message, {String? title}) {
    showInAppNotification(
      title: title ?? 'Warning',
      message: message,
      type: NotificationType.warning,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show info notification
  void showInfo(String message, {String? title}) {
    showInAppNotification(
      title: title ?? 'Info',
      message: message,
    );
  }

  /// Create appointment notification
  void showAppointmentNotification({
    required String title,
    required String message,
    required DateTime appointmentTime,
    VoidCallback? onTap,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.appointment,
      timestamp: DateTime.now(),
      appointmentTime: appointmentTime,
      isPersistent: true,
      onTap: onTap,
    );

    addNotification(notification);
  }

  /// Create health alert notification
  void showHealthAlert({
    required String title,
    required String message,
    HealthAlertSeverity severity = HealthAlertSeverity.medium,
    VoidCallback? onTap,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.health,
      timestamp: DateTime.now(),
      healthSeverity: severity,
      isPersistent: severity == HealthAlertSeverity.high,
      onTap: onTap,
    );

    addNotification(notification);
  }

  /// Get notification statistics
  Map<String, int> getStatistics() {
    return {
      'total': _notifications.length,
      'unread': _unreadNotifications.length,
      'read': _notifications.where((n) => n.isRead).length,
      'appointments': _notifications
          .where((n) => n.type == NotificationType.appointment)
          .length,
      'health': _notifications
          .where((n) => n.type == NotificationType.health)
          .length,
      'system': _notifications
          .where((n) => n.type == NotificationType.system)
          .length,
    };
  }

  /// Clear old notifications (older than specified days)
  void clearOldNotifications({int daysToKeep = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    _notifications.removeWhere(
      (notification) =>
          !notification.isPersistent &&
          notification.timestamp.isBefore(cutoffDate),
    );

    _unreadNotifications.removeWhere(
      (notification) =>
          !notification.isPersistent &&
          notification.timestamp.isBefore(cutoffDate),
    );

    notifyListeners();
  }
}

/// App notification model
class AppNotification {

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isPersistent = false,
    this.appointmentTime,
    this.healthSeverity,
    this.onTap,
  });
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isPersistent;
  final DateTime? appointmentTime;
  final HealthAlertSeverity? healthSeverity;
  final VoidCallback? onTap;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isPersistent,
    DateTime? appointmentTime,
    HealthAlertSeverity? healthSeverity,
    VoidCallback? onTap,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      healthSeverity: healthSeverity ?? this.healthSeverity,
      onTap: onTap ?? this.onTap,
    );
  }

  /// Get icon for notification type
  IconData get icon {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.health:
        return Icons.health_and_safety;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.system:
        return Icons.settings;
    }
  }

  /// Get color for notification type
  Color get color {
    switch (type) {
      case NotificationType.appointment:
        return Colors.blue;
      case NotificationType.health:
        return healthSeverity?.color ?? Colors.green;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  /// Format timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Notification type enumeration
enum NotificationType {
  appointment,
  health,
  success,
  error,
  warning,
  info,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.appointment:
        return 'Appointment';
      case NotificationType.health:
        return 'Health Alert';
      case NotificationType.success:
        return 'Success';
      case NotificationType.error:
        return 'Error';
      case NotificationType.warning:
        return 'Warning';
      case NotificationType.info:
        return 'Information';
      case NotificationType.system:
        return 'System';
    }
  }
}

/// Health alert severity enumeration
enum HealthAlertSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case HealthAlertSeverity.low:
        return 'Low';
      case HealthAlertSeverity.medium:
        return 'Medium';
      case HealthAlertSeverity.high:
        return 'High';
      case HealthAlertSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case HealthAlertSeverity.low:
        return Colors.green;
      case HealthAlertSeverity.medium:
        return Colors.yellow;
      case HealthAlertSeverity.high:
        return Colors.orange;
      case HealthAlertSeverity.critical:
        return Colors.red;
    }
  }
}

/// Notification filter enumeration
enum NotificationFilter {
  all,
  unread,
  read,
  appointments,
  health,
  system;

  String get displayName {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.read:
        return 'Read';
      case NotificationFilter.appointments:
        return 'Appointments';
      case NotificationFilter.health:
        return 'Health';
      case NotificationFilter.system:
        return 'System';
    }
  }
}

