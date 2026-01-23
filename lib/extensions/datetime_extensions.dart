/// DateTime Extensions
/// 
/// Useful extensions for DateTime manipulation and formatting.
library;

import 'package:intl/intl.dart';

/// Extensions for DateTime class
extension DateTimeExtensions on DateTime {
  /// Format as date string (MMM dd, yyyy)
  String formatDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format as time string (hh:mm a)
  String formatTime() {
    return DateFormat('hh:mm a').format(this);
  }

  /// Format as date and time string (MMM dd, yyyy hh:mm a)
  String formatDateTime() {
    return DateFormat('MMM dd, yyyy hh:mm a').format(this);
  }

  /// Format for API (yyyy-MM-dd)
  String formatForApi() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// Format for API with time (yyyy-MM-ddTHH:mm:ss)
  String formatForApiWithTime() {
    return DateFormat('yyyy-MM-ddTHH:mm:ss').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is in the past
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Check if date is in the future
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Get relative time string (e.g., "2 hours ago", "in 3 days")
  String get relativeTime {
    final now = DateTime.now();
    final difference = this.difference(now);

    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inSeconds < 60) {
        return 'Just now';
      } else if (absDifference.inMinutes < 60) {
        final minutes = absDifference.inMinutes;
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (absDifference.inHours < 24) {
        final hours = absDifference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (absDifference.inDays < 7) {
        final days = absDifference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      } else if (absDifference.inDays < 30) {
        final weeks = (absDifference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (absDifference.inDays < 365) {
        final months = (absDifference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (absDifference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } else {
      // Future
      if (difference.inSeconds < 60) {
        return 'In a moment';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return 'In $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return 'In $hours ${hours == 1 ? 'hour' : 'hours'}';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return 'In $days ${days == 1 ? 'day' : 'days'}';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'In $months ${months == 1 ? 'month' : 'months'}';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'In $years ${years == 1 ? 'year' : 'years'}';
      }
    }
  }

  /// Get start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month);
  }

  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of year
  DateTime get startOfYear {
    return DateTime(year);
  }

  /// Get end of year
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  /// Add business days (excluding weekends)
  DateTime addBusinessDays(int days) {
    var result = this;
    var remainingDays = days;

    while (remainingDays > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        remainingDays--;
      }
    }

    return result;
  }

  /// Check if date is a weekend
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Check if date is a weekday
  bool get isWeekday {
    return !isWeekend;
  }

  /// Get age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Copy with modified fields
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
