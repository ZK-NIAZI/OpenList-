import 'package:intl/intl.dart';

/// Utility class for parsing natural language dates and times
class DateParser {
  /// Parse relative date expressions like "tomorrow", "in 3 days", "next week"
  /// 
  /// Returns DateTime if parsing succeeds, null otherwise
  /// 
  /// Examples:
  /// - "tomorrow" → current date + 1 day
  /// - "today" → current date
  /// - "in 3 days" → current date + 3 days
  /// - "next week" → next Monday
  /// - "next monday" → next Monday
  static DateTime? parseRelativeDate(String text, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final lowerText = text.toLowerCase().trim();

    // Today
    if (lowerText.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }

    // Tomorrow
    if (lowerText.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    }

    // Yesterday (for completeness)
    if (lowerText.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }

    // "in X days/weeks/months"
    final inXPattern = RegExp(r'in\s+(\d+)\s+(day|week|month)s?', caseSensitive: false);
    final inXMatch = inXPattern.firstMatch(lowerText);
    if (inXMatch != null) {
      final amount = int.parse(inXMatch.group(1)!);
      final unit = inXMatch.group(2)!.toLowerCase();
      
      switch (unit) {
        case 'day':
          final targetDate = now.add(Duration(days: amount));
          return DateTime(targetDate.year, targetDate.month, targetDate.day);
        case 'week':
          final targetDate = now.add(Duration(days: amount * 7));
          return DateTime(targetDate.year, targetDate.month, targetDate.day);
        case 'month':
          final targetDate = DateTime(now.year, now.month + amount, now.day);
          return DateTime(targetDate.year, targetDate.month, targetDate.day);
      }
    }

    // "next week" → next Monday
    if (lowerText.contains('next week')) {
      final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
      return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
    }

    // "next [weekday]"
    final weekdays = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    for (final entry in weekdays.entries) {
      if (lowerText.contains('next ${entry.key}')) {
        final targetWeekday = entry.value;
        final daysUntilTarget = (targetWeekday - now.weekday + 7) % 7;
        final nextOccurrence = now.add(Duration(days: daysUntilTarget == 0 ? 7 : daysUntilTarget));
        return DateTime(nextOccurrence.year, nextOccurrence.month, nextOccurrence.day);
      }
    }

    // "this [weekday]" → next occurrence this week or next week
    for (final entry in weekdays.entries) {
      if (lowerText.contains('this ${entry.key}')) {
        final targetWeekday = entry.value;
        final daysUntilTarget = (targetWeekday - now.weekday) % 7;
        final thisOccurrence = now.add(Duration(days: daysUntilTarget));
        return DateTime(thisOccurrence.year, thisOccurrence.month, thisOccurrence.day);
      }
    }

    // "end of month"
    if (lowerText.contains('end of month') || lowerText.contains('month end')) {
      final lastDay = DateTime(now.year, now.month + 1, 0);
      return DateTime(lastDay.year, lastDay.month, lastDay.day);
    }

    // "end of week"
    if (lowerText.contains('end of week') || lowerText.contains('week end')) {
      final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      final endOfWeek = now.add(Duration(days: daysUntilSunday));
      return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    }

    return null;
  }

  /// Parse time expressions like "at 5pm", "at 17:00", "in the morning"
  /// 
  /// Returns TimeOfDay-like values as a Map with 'hour' and 'minute' keys
  /// 
  /// Examples:
  /// - "at 5pm" → {hour: 17, minute: 0}
  /// - "at 17:00" → {hour: 17, minute: 0}
  /// - "in the morning" → {hour: 9, minute: 0}
  static Map<String, int>? parseTime(String text) {
    final lowerText = text.toLowerCase().trim();

    // Check specific words before substrings (midnight before night, afternoon before noon)
    if (lowerText.contains('midnight')) {
      return {'hour': 0, 'minute': 0};
    }

    if (lowerText.contains('afternoon')) {
      return {'hour': 14, 'minute': 0};
    }

    if (lowerText.contains('noon')) {
      return {'hour': 12, 'minute': 0};
    }

    // "at HH:MM" or "HH:MM" (24-hour format)
    final time24Pattern = RegExp(r'(\d{1,2}):(\d{2})');
    final time24Match = time24Pattern.firstMatch(lowerText);
    if (time24Match != null) {
      final hour = int.parse(time24Match.group(1)!);
      final minute = int.parse(time24Match.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return {'hour': hour, 'minute': minute};
      }
    }

    // "at 5pm" or "5pm" (12-hour format with am/pm)
    final time12Pattern = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false);
    final time12Match = time12Pattern.firstMatch(lowerText);
    if (time12Match != null) {
      var hour = int.parse(time12Match.group(1)!);
      final period = time12Match.group(2)!.toLowerCase();
      
      if (period == 'pm' && hour != 12) {
        hour += 12;
      } else if (period == 'am' && hour == 12) {
        hour = 0;
      }
      
      if (hour >= 0 && hour < 24) {
        return {'hour': hour, 'minute': 0};
      }
    }

    // "in the morning" → 9:00 AM
    if (lowerText.contains('morning')) {
      return {'hour': 9, 'minute': 0};
    }

    // "in the evening" → 6:00 PM
    if (lowerText.contains('evening')) {
      return {'hour': 18, 'minute': 0};
    }

    // "at night" → 8:00 PM
    if (lowerText.contains('night')) {
      return {'hour': 20, 'minute': 0};
    }

    return null;
  }

  /// Combine date and time into a single DateTime
  /// 
  /// If time is null, uses 9:00 AM as default
  static DateTime combineDateAndTime(DateTime date, Map<String, int>? time) {
    final hour = time?['hour'] ?? 9;
    final minute = time?['minute'] ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Calculate reminder time (default: 30 minutes before due date)
  static DateTime calculateReminderTime(DateTime dueDate, {int minutesBefore = 30}) {
    return dueDate.subtract(Duration(minutes: minutesBefore));
  }

  /// Check if a date is in the past
  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly.difference(today).inDays < 7 && dateOnly.isAfter(today)) {
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else {
      return DateFormat('MMM d, yyyy').format(date); // Jan 15, 2026
    }
  }

  /// Format time for display
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime); // 5:00 PM
  }

  /// Format date and time together
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Extract all date/time keywords from text
  static List<String> extractKeywords(String text) {
    final lowerText = text.toLowerCase();
    final keywords = <String>[];

    // Date keywords
    final dateKeywords = [
      'today', 'tomorrow', 'yesterday',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'next week', 'this week', 'end of month', 'end of week',
    ];

    for (final keyword in dateKeywords) {
      if (lowerText.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    // Time keywords
    final timeKeywords = [
      'morning', 'afternoon', 'evening', 'night',
      'noon', 'midnight',
      'am', 'pm',
    ];

    for (final keyword in timeKeywords) {
      if (lowerText.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    // Pattern-based keywords
    if (RegExp(r'in\s+\d+\s+(day|week|month)s?').hasMatch(lowerText)) {
      keywords.add('relative date');
    }

    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(lowerText)) {
      keywords.add('specific time');
    }

    if (RegExp(r'\d{1,2}\s*(am|pm)').hasMatch(lowerText)) {
      keywords.add('12-hour time');
    }

    // Action keywords
    final actionKeywords = [
      'deadline', 'due', 'by', 'before', 'until', 'on',
    ];

    for (final keyword in actionKeywords) {
      if (lowerText.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    return keywords;
  }
}
