import 'package:flutter_test/flutter_test.dart';
import 'package:openlist/utils/date_parser.dart';

void main() {
  group('DateParser - parseRelativeDate', () {
    final referenceDate = DateTime(2026, 2, 26, 10, 30); // Thursday, Feb 26, 2026

    test('parses "today" correctly', () {
      final result = DateParser.parseRelativeDate('today', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 2);
      expect(result.day, 26);
    });

    test('parses "tomorrow" correctly', () {
      final result = DateParser.parseRelativeDate('tomorrow', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 2);
      expect(result.day, 27);
    });

    test('parses "yesterday" correctly', () {
      final result = DateParser.parseRelativeDate('yesterday', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 2);
      expect(result.day, 25);
    });

    test('parses "in 3 days" correctly', () {
      final result = DateParser.parseRelativeDate('in 3 days', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 1);
    });

    test('parses "in 2 weeks" correctly', () {
      final result = DateParser.parseRelativeDate('in 2 weeks', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 12);
    });

    test('parses "in 1 month" correctly', () {
      final result = DateParser.parseRelativeDate('in 1 month', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 26);
    });

    test('parses "next week" correctly (next Monday)', () {
      final result = DateParser.parseRelativeDate('next week', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 3);
      expect(result.day, 2); // Next Monday
      expect(result.weekday, DateTime.monday);
    });

    test('parses "next monday" correctly', () {
      final result = DateParser.parseRelativeDate('next monday', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.monday);
      expect(result.isAfter(referenceDate), true);
    });

    test('parses "next friday" correctly', () {
      final result = DateParser.parseRelativeDate('next friday', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.friday);
      expect(result.year, 2026);
      expect(result.month, 2);
      expect(result.day, 27); // Next Friday from Thursday
    });

    test('parses "end of month" correctly', () {
      final result = DateParser.parseRelativeDate('end of month', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.year, 2026);
      expect(result.month, 2);
      expect(result.day, 28); // February 2026 has 28 days
    });

    test('parses "end of week" correctly', () {
      final result = DateParser.parseRelativeDate('end of week', referenceDate: referenceDate);
      expect(result, isNotNull);
      expect(result!.weekday, DateTime.sunday);
    });

    test('returns null for unrecognized date', () {
      final result = DateParser.parseRelativeDate('some random text', referenceDate: referenceDate);
      expect(result, isNull);
    });

    test('handles case insensitivity', () {
      final result1 = DateParser.parseRelativeDate('TOMORROW', referenceDate: referenceDate);
      final result2 = DateParser.parseRelativeDate('Tomorrow', referenceDate: referenceDate);
      final result3 = DateParser.parseRelativeDate('tomorrow', referenceDate: referenceDate);
      
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result3, isNotNull);
      expect(result1!.day, result2!.day);
      expect(result2.day, result3!.day);
    });
  });

  group('DateParser - parseTime', () {
    test('parses "5pm" correctly', () {
      final result = DateParser.parseTime('at 5pm');
      expect(result, isNotNull);
      expect(result!['hour'], 17);
      expect(result['minute'], 0);
    });

    test('parses "5am" correctly', () {
      final result = DateParser.parseTime('at 5am');
      expect(result, isNotNull);
      expect(result!['hour'], 5);
      expect(result['minute'], 0);
    });

    test('parses "12pm" (noon) correctly', () {
      final result = DateParser.parseTime('12pm');
      expect(result, isNotNull);
      expect(result!['hour'], 12);
      expect(result['minute'], 0);
    });

    test('parses "12am" (midnight) correctly', () {
      final result = DateParser.parseTime('12am');
      expect(result, isNotNull);
      expect(result!['hour'], 0);
      expect(result['minute'], 0);
    });

    test('parses "17:00" (24-hour) correctly', () {
      final result = DateParser.parseTime('17:00');
      expect(result, isNotNull);
      expect(result!['hour'], 17);
      expect(result['minute'], 0);
    });

    test('parses "9:30" correctly', () {
      final result = DateParser.parseTime('9:30');
      expect(result, isNotNull);
      expect(result!['hour'], 9);
      expect(result['minute'], 30);
    });

    test('parses "in the morning" correctly', () {
      final result = DateParser.parseTime('in the morning');
      expect(result, isNotNull);
      expect(result!['hour'], 9);
      expect(result['minute'], 0);
    });

    test('parses "in the afternoon" correctly', () {
      final result = DateParser.parseTime('in the afternoon');
      expect(result, isNotNull);
      expect(result!['hour'], 14);
      expect(result['minute'], 0);
    });

    test('parses "in the evening" correctly', () {
      final result = DateParser.parseTime('in the evening');
      expect(result, isNotNull);
      expect(result!['hour'], 18);
      expect(result['minute'], 0);
    });

    test('parses "at night" correctly', () {
      final result = DateParser.parseTime('at night');
      expect(result, isNotNull);
      expect(result!['hour'], 20);
      expect(result['minute'], 0);
    });

    test('parses "noon" correctly', () {
      final result = DateParser.parseTime('noon');
      expect(result, isNotNull);
      expect(result!['hour'], 12);
      expect(result['minute'], 0);
    });

    test('parses "midnight" correctly', () {
      final result = DateParser.parseTime('midnight');
      expect(result, isNotNull);
      expect(result!['hour'], 0);
      expect(result['minute'], 0);
    });

    test('returns null for unrecognized time', () {
      final result = DateParser.parseTime('some random text');
      expect(result, isNull);
    });

    test('handles case insensitivity', () {
      final result1 = DateParser.parseTime('5PM');
      final result2 = DateParser.parseTime('5pm');
      
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!['hour'], result2!['hour']);
    });
  });

  group('DateParser - combineDateAndTime', () {
    test('combines date and time correctly', () {
      final date = DateTime(2026, 2, 26);
      final time = {'hour': 17, 'minute': 30};
      
      final result = DateParser.combineDateAndTime(date, time);
      
      expect(result.year, 2026);
      expect(result.month, 2);
      expect(result.day, 26);
      expect(result.hour, 17);
      expect(result.minute, 30);
    });

    test('uses default time (9:00 AM) when time is null', () {
      final date = DateTime(2026, 2, 26);
      
      final result = DateParser.combineDateAndTime(date, null);
      
      expect(result.hour, 9);
      expect(result.minute, 0);
    });
  });

  group('DateParser - calculateReminderTime', () {
    test('calculates reminder 30 minutes before by default', () {
      final dueDate = DateTime(2026, 2, 26, 17, 0);
      
      final result = DateParser.calculateReminderTime(dueDate);
      
      expect(result.hour, 16);
      expect(result.minute, 30);
    });

    test('calculates reminder with custom minutes', () {
      final dueDate = DateTime(2026, 2, 26, 17, 0);
      
      final result = DateParser.calculateReminderTime(dueDate, minutesBefore: 60);
      
      expect(result.hour, 16);
      expect(result.minute, 0);
    });
  });

  group('DateParser - isPastDate', () {
    test('returns true for past dates', () {
      final pastDate = DateTime(2020, 1, 1);
      expect(DateParser.isPastDate(pastDate), true);
    });

    test('returns false for future dates', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      expect(DateParser.isPastDate(futureDate), false);
    });

    test('returns false for today', () {
      final today = DateTime.now();
      expect(DateParser.isPastDate(today), false);
    });
  });

  group('DateParser - formatDate', () {
    test('formats today as "Today"', () {
      final today = DateTime.now();
      expect(DateParser.formatDate(today), 'Today');
    });

    test('formats tomorrow as "Tomorrow"', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(DateParser.formatDate(tomorrow), 'Tomorrow');
    });

    test('formats dates within a week as weekday name', () {
      final now = DateTime.now();
      final inThreeDays = now.add(const Duration(days: 3));
      final result = DateParser.formatDate(inThreeDays);
      
      // Should be a weekday name
      expect(
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            .contains(result),
        true,
      );
    });
  });

  group('DateParser - extractKeywords', () {
    test('extracts date keywords', () {
      final keywords = DateParser.extractKeywords('Buy groceries tomorrow at 5pm');
      
      expect(keywords.contains('tomorrow'), true);
      expect(keywords.contains('pm'), true);
    });

    test('extracts multiple keywords', () {
      final keywords = DateParser.extractKeywords('Meeting next monday in the morning');
      
      expect(keywords.contains('monday'), true);
      expect(keywords.contains('morning'), true);
    });

    test('extracts action keywords', () {
      final keywords = DateParser.extractKeywords('Deadline by friday');
      
      expect(keywords.contains('friday'), true);
      expect(keywords.contains('by'), true);
    });

    test('returns empty list for text without keywords', () {
      final keywords = DateParser.extractKeywords('Just a regular note');
      
      expect(keywords.isEmpty, true);
    });
  });
}
