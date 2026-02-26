import 'package:flutter/foundation.dart';

/// Model representing the result of AI task extraction from natural language text
@immutable
class TaskExtraction {
  /// The extracted task title (cleaned, without date/time phrases)
  final String title;

  /// The extracted due date (null if no date mentioned)
  final DateTime? dueDate;

  /// The suggested reminder time (null if no reminder needed)
  final DateTime? reminderAt;

  /// Confidence score from 0.0 to 1.0 indicating extraction accuracy
  final double confidence;

  /// Keywords detected in the text (e.g., "tomorrow", "deadline", "5pm")
  final List<String> detectedKeywords;

  /// Whether this text represents an actionable task (vs just a note)
  final bool isTask;

  const TaskExtraction({
    required this.title,
    this.dueDate,
    this.reminderAt,
    this.confidence = 1.0,
    this.detectedKeywords = const [],
    this.isTask = true,
  });

  /// Create TaskExtraction from JSON response
  factory TaskExtraction.fromJson(Map<String, dynamic> json) {
    return TaskExtraction(
      title: json['title'] as String? ?? '',
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      reminderAt: json['reminderAt'] != null
          ? DateTime.parse(json['reminderAt'] as String)
          : null,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      detectedKeywords: (json['keywords'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      isTask: json['isTask'] as bool? ?? true,
    );
  }

  /// Convert TaskExtraction to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'confidence': confidence,
      'keywords': detectedKeywords,
      'isTask': isTask,
    };
  }

  /// Create a copy with modified fields
  TaskExtraction copyWith({
    String? title,
    DateTime? dueDate,
    DateTime? reminderAt,
    double? confidence,
    List<String>? detectedKeywords,
    bool? isTask,
  }) {
    return TaskExtraction(
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      confidence: confidence ?? this.confidence,
      detectedKeywords: detectedKeywords ?? this.detectedKeywords,
      isTask: isTask ?? this.isTask,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskExtraction &&
        other.title == title &&
        other.dueDate == dueDate &&
        other.reminderAt == reminderAt &&
        other.confidence == confidence &&
        listEquals(other.detectedKeywords, detectedKeywords) &&
        other.isTask == isTask;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      dueDate,
      reminderAt,
      confidence,
      Object.hashAll(detectedKeywords),
      isTask,
    );
  }

  @override
  String toString() {
    return 'TaskExtraction(title: $title, dueDate: $dueDate, '
        'reminderAt: $reminderAt, confidence: $confidence, '
        'keywords: $detectedKeywords, isTask: $isTask)';
  }
}
