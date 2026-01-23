/// Date Formatter Tests
/// 
/// Tests for the DateFormatter utility class.
library;

import 'package:flutter_diacare/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2024, 1, 15, 14, 30);

    test('formatDate should format date as dd/MM/yyyy', () {
      expect(DateFormatter.formatDate(testDate), '15/01/2024');
    });

    test('formatDateMedium should format date as dd MMM yyyy', () {
      expect(DateFormatter.formatDateMedium(testDate), '15 Jan 2024');
    });

    test('formatTime should format time as HH:mm', () {
      expect(DateFormatter.formatTime(testDate), '14:30');
    });

    test('formatTime12Hour should format time with AM/PM', () {
      expect(DateFormatter.formatTime12Hour(testDate), '02:30 PM');
    });

    test('formatDateTime should format date and time', () {
      expect(DateFormatter.formatDateTime(testDate), '15/01/2024 14:30');
    });

    test('parseDate should parse date string', () {
      final parsed = DateFormatter.parseDate('15/01/2024');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2024);
      expect(parsed.month, 1);
      expect(parsed.day, 15);
    });

    test('parseDate should return null for invalid date', () {
      final parsed = DateFormatter.parseDate('invalid');
      expect(parsed, isNull);
    });

    test('isToday should return true for today', () {
      expect(DateFormatter.isToday(DateTime.now()), true);
    });

    test('isToday should return false for other days', () {
      expect(DateFormatter.isToday(testDate), false);
    });

    test('isYesterday should return true for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.isYesterday(yesterday), true);
    });

    test('formatRelative should return "Just now" for recent times', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'Just now');
    });

    test('formatRelative should return minutes ago', () {
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(fiveMinutesAgo), '5 minutes ago');
    });

    test('formatRelative should return hours ago', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      expect(DateFormatter.formatRelative(twoHoursAgo), '2 hours ago');
    });

    test('formatRelative should return days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.formatRelative(threeDaysAgo), '3 days ago');
    });

    test('getDayName should return day name', () {
      // Note: This test assumes testDate is a Monday
      final dayName = DateFormatter.getDayName(testDate);
      expect(dayName, isNotEmpty);
    });

    test('getMonthName should return month name', () {
      expect(DateFormatter.getMonthName(testDate), 'January');
    });
  });
}
