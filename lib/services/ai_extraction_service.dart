import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../data/models/task_extraction_model.dart';

/// Service for extracting task information from natural language using AI
class AIExtractionService {
  final GenerativeModel _model;
  
  AIExtractionService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
          ),
        );

  /// Extract task information from natural language text
  /// 
  /// Returns [TaskExtraction] if successful, null if extraction fails
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.extractTask('Buy groceries tomorrow at 5pm');
  /// // Returns: TaskExtraction(title: 'Buy groceries', dueDate: tomorrow 5pm, ...)
  /// ```
  Future<TaskExtraction?> extractTask(String text) async {
    if (text.trim().isEmpty) {
      return null;
    }

    try {
      final prompt = _buildPrompt(text);
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        return null;
      }

      return _parseResponse(response.text!);
    } catch (e) {
      // Log error but don't throw - graceful degradation
      print('AI extraction error: $e');
      return null;
    }
  }

  /// Build the prompt with current date/time context
  String _buildPrompt(String userInput) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');
    final dayFormat = DateFormat('EEEE');
    
    return '''
You are a task extraction assistant for a todo app. Extract structured task information from natural language.

Current date: ${dateFormat.format(now)}
Current time: ${timeFormat.format(now)}
Current day: ${dayFormat.format(now)}
Timezone: ${now.timeZoneName}

Rules for date extraction:
- "tomorrow" = ${dateFormat.format(now.add(const Duration(days: 1)))}
- "today" = ${dateFormat.format(now)}
- "in X days" = current date + X days
- "next week" = next Monday
- "next [day]" = next occurrence of that weekday
- "end of month" = last day of current month
- If no time specified, use 09:00
- Reminder should be 30 minutes before due time
- If text is just notes/thoughts (not actionable), set isTask=false
- Extract clean task title (remove date/time phrases)

Rules for confidence:
- High confidence (0.8-1.0): Clear task with explicit date/time
- Medium confidence (0.5-0.7): Task with vague date or no date
- Low confidence (0.0-0.4): Unclear if it's a task or just a note

Extract task from: "$userInput"

Return ONLY valid JSON with this exact structure:
{
  "title": "cleaned task title without date/time",
  "dueDate": "ISO 8601 date string or null",
  "reminderAt": "ISO 8601 datetime string or null",
  "confidence": 0.95,
  "keywords": ["array", "of", "detected", "keywords"],
  "isTask": true
}

Do not include any markdown formatting or explanation, just the JSON object.
''';
  }

  /// Parse the AI response into TaskExtraction model
  TaskExtraction? _parseResponse(String responseText) {
    try {
      // Remove any markdown code blocks if present
      String cleanedText = responseText.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      final json = jsonDecode(cleanedText) as Map<String, dynamic>;
      return TaskExtraction.fromJson(json);
    } catch (e) {
      print('Failed to parse AI response: $e');
      print('Response text: $responseText');
      return null;
    }
  }

  /// Test the API connection
  /// 
  /// Returns true if connection is successful, false otherwise
  Future<bool> testConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text('Respond with just the word "ok" if you can read this.')
      ]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
