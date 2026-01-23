/// Date Formatter
/// 
/// Utility functions for date formatting.
library;

import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatter {
  DateFormatter._();

  /// Format date as 'dd/MM/yyyy'
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as 'dd MMM yyyy' (e.g., 15 Jan 2024)
  static String formatDateMedium(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as 'EEEE, dd MMMM yyyy' (e.g., Monday, 15 January 2024)
  static String formatDateLong(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  /// Format time as 'HH:mm' (24-hour)
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Format time as 'hh:mm a' (12-hour with AM/PM)
  static String formatTime12Hour(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  /// Format date and time as 'dd/MM/yyyy HH:mm'
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Format as relative time (e.g., "2 hours ago")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Parse date from string (dd/MM/yyyy)
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date time from string (dd/MM/yyyy HH:mm)
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }
}
