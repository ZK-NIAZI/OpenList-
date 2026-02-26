# AI Task Extraction - Technical Design

## Overview
Enable users to create tasks from natural language text using AI-powered extraction. The system will parse text like "Buy groceries tomorrow at 5pm" and automatically extract the task title, due date, time, and set appropriate reminders.

## Design Goals
1. **Accuracy**: Correctly extract task details from natural language
2. **Speed**: Provide near-instant feedback (<2 seconds)
3. **Cost**: Stay within free tier limits (Gemini 1.5 Flash)
4. **Privacy**: Secure API key storage, transparent data usage
5. **UX**: Seamless integration into existing task creation flows

---

## Architecture

### High-Level Flow
```
User Input → AI Service → Parse Response → Preview → Confirm → Create Task
```

### Components

#### 1. AI Service Layer
**File**: `lib/services/ai_extraction_service.dart`

**Responsibilities**:
- Communicate with Gemini API
- Format prompts with context (current date/time)
- Parse JSON responses
- Handle errors and retries
- Rate limiting

**Dependencies**:
- `google_generative_ai` package
- `flutter_secure_storage` (for API key)

#### 2. Data Models
**File**: `lib/data/models/task_extraction_model.dart`

**Models**:
```dart
class TaskExtraction {
  final String title;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final double confidence; // 0.0 to 1.0
  final List<String> detectedKeywords;
  final bool isTask; // vs just a note
}
```

#### 3. Settings Integration
**File**: `lib/features/settings/presentation/ai_settings_screen.dart`

**Settings**:
- Enable/disable AI extraction
- API key configuration
- Default reminder offset (30 min, 1 hour, etc)
- Auto-extract on paste (toggle)

#### 4. UI Integration Points

**A. Quick Add Sheet Enhancement**
- Add "AI Extract" button
- Show extraction preview
- Allow editing before confirmation

**B. Note Detail Screen**
- "Extract Tasks" button for batch extraction
- Highlight detected task patterns

---

## Technical Specifications

### 1. Gemini API Integration

**Model**: `gemini-1.5-flash`
**Endpoint**: Google AI Studio API
**Rate Limits**: 15 requests/minute (free tier)

**Request Format**:
```json
{
  "contents": [{
    "parts": [{
      "text": "PROMPT_HERE"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "responseMimeType": "application/json"
  }
}
```

**Response Format**:
```json
{
  "title": "Buy groceries",
  "dueDate": "2026-02-27T17:00:00Z",
  "reminderAt": "2026-02-27T16:30:00Z",
  "confidence": 0.95,
  "keywords": ["tomorrow", "5pm"],
  "isTask": true
}
```

### 2. Prompt Engineering

**System Prompt**:
```
You are a task extraction assistant for a todo app. Extract structured task information from natural language.

Current date: {CURRENT_DATE}
Current time: {CURRENT_TIME}
Timezone: {TIMEZONE}

Rules:
- "tomorrow" = current date + 1 day
- "today" = current date
- "in X days" = current date + X days
- "next week" = next Monday
- "next [day]" = next occurrence of that weekday
- "end of month" = last day of current month
- If no time specified, use 9:00 AM
- Reminder should be 30 minutes before due time
- If text is just notes/thoughts (not actionable), set isTask=false
- Extract clean task title (remove date/time phrases)

Return ONLY valid JSON, no markdown or explanation.
```

**User Prompt Template**:
```
Extract task from: "{USER_INPUT}"
```

### 3. Date/Time Parsing Logic

**Supported Patterns**:
- Absolute: "tomorrow", "today", "Monday", "March 15"
- Relative: "in 2 days", "in 3 weeks", "in 1 month"
- Time: "at 5pm", "at 17:00", "in the morning" (9am), "in the evening" (6pm)
- Keywords: "deadline", "due", "by", "before", "until"

**Edge Cases**:
- Past dates → Show warning, suggest today
- Invalid dates → Return null, let user set manually
- Ambiguous dates → Use nearest future occurrence
- Multiple dates → Use first mentioned date

### 4. Error Handling

**Scenarios**:
1. **API Error**: Show fallback to manual entry
2. **Invalid JSON**: Retry once, then fallback
3. **Rate Limit**: Queue request, show "Processing..."
4. **Network Error**: Show offline message, save for later
5. **Low Confidence (<0.5)**: Show extraction but mark as uncertain

### 5. Security

**API Key Storage**:
- Use `flutter_secure_storage`
- Never log or expose key
- Validate key format before use

**Data Privacy**:
- User text sent to Google AI
- No data retention by Google (per API terms)
- Add privacy notice in settings
- Option to disable AI features

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Set up AI service and basic extraction

**Tasks**:
1. Add `google_generative_ai` package to pubspec.yaml
2. Create `AIExtractionService` class
3. Create `TaskExtraction` model
4. Implement basic prompt and parsing
5. Add unit tests for date parsing
6. Create AI settings screen for API key input

**Success Criteria**:
- Can send text to Gemini and get JSON response
- Can parse common date formats
- API key stored securely

### Phase 2: UI Integration (Week 2)
**Goal**: Add extraction to Quick Add flow

**Tasks**:
1. Add "AI Extract" button to QuickAddSheet
2. Show loading state during extraction
3. Display extracted data in form fields
4. Allow user to edit before saving
5. Add error handling UI
6. Test with various input patterns

**Success Criteria**:
- User can extract task from natural language
- Extracted data populates form correctly
- User can edit before confirming

### Phase 3: Batch Extraction (Week 3)
**Goal**: Extract multiple tasks from notes

**Tasks**:
1. Add "Extract Tasks" button to note detail screen
2. Detect multiple task patterns in text
3. Show preview of all extracted tasks
4. Allow bulk confirmation
5. Create all tasks as children of note

**Success Criteria**:
- Can extract 3+ tasks from single note
- Preview shows all tasks clearly
- All tasks created correctly

### Phase 4: Polish & Optimization (Week 4)
**Goal**: Improve UX and performance

**Tasks**:
1. Add confidence indicators
2. Implement request caching
3. Add analytics for extraction accuracy
4. Optimize prompt for better results
5. Add keyboard shortcuts
6. Performance testing

**Success Criteria**:
- Extraction completes in <2 seconds
- 90%+ accuracy on common patterns
- Smooth user experience

---

## Data Flow Diagrams

### Single Task Extraction
```
┌─────────────┐
│ User types  │
│ "Buy milk   │
│  tomorrow"  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ AI Service      │
│ - Add context   │
│ - Send to API   │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Gemini API      │
│ - Parse text    │
│ - Extract data  │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Parse Response  │
│ - Validate JSON │
│ - Create model  │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Show Preview    │
│ - Title: "Buy   │
│   milk"         │
│ - Due: Tomorrow │
│   9:00 AM       │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ User Confirms   │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Create Task     │
│ (existing flow) │
└─────────────────┘
```

### Batch Extraction from Note
```
┌─────────────────┐
│ Note with text: │
│ "- Buy milk     │
│  - Call John    │
│  - Submit report│
│    by Friday"   │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ User clicks     │
│ "Extract Tasks" │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ AI Service      │
│ - Detect list   │
│ - Extract each  │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Show Preview    │
│ ✓ Buy milk      │
│ ✓ Call John     │
│ ✓ Submit report │
│   (Due: Friday) │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ User confirms   │
│ all or selects  │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Create tasks as │
│ children of note│
└─────────────────┘
```

---

## API Cost Analysis

### Gemini 1.5 Flash Pricing
- **Free Tier**: 15 RPM, 1.5M requests/day
- **Paid Tier**: $0.075 per 1M input tokens

### Usage Estimation
- Average extraction: ~200 input tokens
- 100 extractions/day/user = 20,000 tokens/day
- 1M tokens = 50 users for 1 day
- **Free tier supports 15,000 users easily**

### Cost at Scale (if needed)
- 1,000 users × 100 extractions/day = 100,000 extractions
- 100,000 × 200 tokens = 20M tokens/month
- Cost: 20 × $0.075 = **$1.50/month**

**Conclusion**: Extremely affordable even at scale

---

## Testing Strategy

### Unit Tests
- Date parsing functions
- Time extraction logic
- JSON parsing
- Error handling

### Integration Tests
- API communication
- Response parsing
- Model creation
- Settings persistence

### E2E Tests
1. Simple extraction: "Buy milk tomorrow"
2. Complex extraction: "Meeting with John next Friday at 3pm"
3. Batch extraction: Multiple tasks in note
4. Error cases: Invalid input, API failure
5. Edge cases: Past dates, ambiguous text

### Test Data
```dart
final testCases = [
  ('Buy groceries tomorrow', 'Buy groceries', tomorrow9am),
  ('Call mom at 5pm today', 'Call mom', today5pm),
  ('Deadline in 3 days', 'Deadline', threeDaysFromNow),
  ('Meeting next Monday 2pm', 'Meeting', nextMonday2pm),
  ('I went to the store', null, null), // Not a task
];
```

---

## Success Metrics

### Accuracy
- 90%+ correct date extraction
- 85%+ correct time extraction
- 95%+ correct task vs note classification

### Performance
- <2 seconds average response time
- <5% API error rate
- 99% uptime

### User Adoption
- 50%+ of users try AI extraction
- 30%+ use it regularly (10+ times/month)
- 4+ star rating for feature

---

## Risks & Mitigations

### Risk 1: API Rate Limits
**Impact**: Users can't extract tasks
**Mitigation**: 
- Implement request queue
- Show clear messaging
- Fallback to manual entry

### Risk 2: Inaccurate Extractions
**Impact**: User frustration, wrong dates
**Mitigation**:
- Always show preview before creating
- Allow editing
- Track accuracy, improve prompts

### Risk 3: API Costs
**Impact**: Unexpected bills
**Mitigation**:
- Monitor usage closely
- Set up billing alerts
- Implement usage caps per user

### Risk 4: Privacy Concerns
**Impact**: Users don't trust feature
**Mitigation**:
- Clear privacy notice
- Option to disable
- Transparent about data usage

---

## Future Enhancements

### Phase 5+ (Future)
1. **Smart Suggestions**: Learn from user patterns
2. **Multi-language Support**: Extract in other languages
3. **Voice Input**: Extract from speech
4. **Recurring Tasks**: Detect "every Monday" patterns
5. **Priority Detection**: Extract urgency from text
6. **Location Extraction**: Detect places mentioned
7. **Contact Linking**: Link to contacts when names mentioned

---

## Dependencies

### New Packages
```yaml
dependencies:
  google_generative_ai: ^0.2.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.18.0 # For date formatting
```

### Existing Dependencies
- `item_repository.dart` - Create tasks
- `sync_manager.dart` - Sync to Supabase
- `isar_service.dart` - Local storage

---

## Next Steps

1. Review this design document
2. Get API key from Google AI Studio
3. Start Phase 1: Foundation
4. Create task breakdown for implementation
5. Begin coding with first task

---

**Status**: Design Complete - Ready for Implementation
**Last Updated**: 2026-02-26
**Owner**: Development Team
