# AI Task Extraction - Implementation Tasks

## Phase 1: Foundation (Current Phase)

### Task 1.1: Setup Dependencies
**Status**: completed ✅
**Description**: Add required packages to project
**Files**: 
- `pubspec.yaml`

**Steps**:
1. Add `google_generative_ai: ^0.2.0`
2. Add `flutter_secure_storage: ^9.0.0` (if not already present)
3. Run `flutter pub get`
4. Verify packages installed correctly

**Acceptance Criteria**:
- [x] Packages added to pubspec.yaml
- [x] No dependency conflicts
- [x] `flutter pub get` runs successfully

---

### Task 1.2: Create Data Models
**Status**: completed ✅
**Description**: Create models for AI extraction results
**Files**:
- `lib/data/models/task_extraction_model.dart` (new)

**Steps**:
1. Create `TaskExtraction` class with fields:
   - `String title`
   - `DateTime? dueDate`
   - `DateTime? reminderAt`
   - `double confidence`
   - `List<String> detectedKeywords`
   - `bool isTask`
2. Add `fromJson` factory constructor
3. Add `toJson` method
4. Add `copyWith` method for editing

**Acceptance Criteria**:
- [x] Model created with all fields
- [x] Can parse from JSON
- [x] Can convert to JSON
- [x] Null safety handled correctly

---

### Task 1.3: Create AI Service
**Status**: completed ✅
**Description**: Create service to communicate with Gemini API
**Files**:
- `lib/services/ai_extraction_service.dart` (new)

**Steps**:
1. Create `AIExtractionService` class
2. Initialize `GenerativeModel` with API key
3. Implement `extractTask(String text)` method
4. Build prompt with current date/time context
5. Send request to Gemini API
6. Parse JSON response
7. Return `TaskExtraction` object
8. Add error handling

**Acceptance Criteria**:
- [x] Service can connect to Gemini API
- [x] Prompt includes current date/time
- [x] Response parsed correctly
- [x] Errors handled gracefully
- [x] Returns null on failure

---

### Task 1.4: Create AI Settings Screen
**Status**: completed ✅
**Description**: Add screen for users to configure AI settings
**Files**:
- `lib/features/settings/presentation/ai_settings_screen.dart` (new)
- `lib/features/settings/presentation/settings_screen.dart` (modify)

**Steps**:
1. Create new AI settings screen
2. Add API key input field (obscured)
3. Add "Test Connection" button
4. Add enable/disable toggle
5. Add default reminder offset dropdown
6. Save settings to secure storage
7. Add navigation from main settings screen

**Acceptance Criteria**:
- [x] Can input and save API key securely
- [x] Can test API connection
- [x] Settings persist across app restarts
- [x] Accessible from main settings

---

### Task 1.5: Implement Date Parsing Utilities
**Status**: completed ✅
**Description**: Create helper functions for parsing natural language dates
**Files**:
- `lib/utils/date_parser.dart` (new)

**Steps**:
1. Create `DateParser` class
2. Implement `parseRelativeDate(String text)`:
   - "tomorrow" → current date + 1
   - "today" → current date
   - "in X days" → current date + X
   - "next week" → next Monday
3. Implement `parseTime(String text)`:
   - "at 5pm" → 17:00
   - "at 17:00" → 17:00
   - "in the morning" → 9:00
4. Add unit tests

**Acceptance Criteria**:
- [x] All common date patterns parsed correctly
- [x] All common time patterns parsed correctly
- [x] Unit tests pass
- [x] Edge cases handled

---

### Task 1.6: Add Unit Tests
**Status**: completed ✅
**Description**: Create comprehensive tests for AI extraction
**Files**:
- `test/utils/date_parser_test.dart` (new)

**Steps**:
1. Test date parsing with various inputs
2. Test time parsing
3. Test JSON parsing
4. Test error handling
5. Mock API responses
6. Test edge cases

**Acceptance Criteria**:
- [x] 90%+ code coverage
- [x] All tests pass (41/41 tests passing)
- [x] Edge cases covered

---

## Phase 2: UI Integration (Current Phase)

### Task 2.1: Enhance Quick Add Sheet
**Status**: completed ✅
**Description**: Add AI extraction to quick add flow
**Files**:
- `lib/features/task/presentation/quick_add_sheet.dart` (modify)

**Steps**:
1. Add AI extraction button/icon to text field
2. Create AI extraction provider
3. Integrate AIExtractionService
4. Show loading state during extraction
5. Populate form fields with extracted data
6. Allow user to edit before saving

**Acceptance Criteria**:
- [x] User can trigger AI extraction
- [x] Loading state shows during extraction
- [x] Extracted data populates form fields
- [x] User can edit extracted data
- [x] Works with existing task creation flow

---

### Task 2.2: Add Error Handling UI
**Status**: completed ✅
**Description**: Show user-friendly error messages
**Files**:
- `lib/features/task/presentation/quick_add_sheet.dart` (already modified in 2.1)

**Steps**:
1. Handle API errors gracefully
2. Show user-friendly error messages
3. Provide fallback to manual entry
4. Handle missing API key scenario
5. Handle network errors

**Acceptance Criteria**:
- [x] Clear error messages shown
- [x] User can continue manually on error
- [x] No crashes on API failure
- [x] Missing API key handled gracefully
- [x] Low-confidence extractions handled (shows confirmation)

---

### Task 2.3: Add Confidence Indicators
**Status**: pending
**Description**: Show confidence scores for low-confidence extractions

---

### Task 2.4: Integration Testing
**Status**: pending
**Description**: Test complete flow with real API

---

## Phase 3: Batch Extraction (Future)

### Task 3.1: Add Extract Button to Notes
**Status**: pending
**Description**: Add "Extract Tasks" button to note detail screen

### Task 3.2: Implement Batch Extraction
**Status**: pending
**Description**: Extract multiple tasks from single note

### Task 3.3: Add Batch Preview UI
**Status**: pending
**Description**: Show all extracted tasks for confirmation

---

## Phase 4: Polish (Future)

### Task 4.1: Add Confidence Indicators
**Status**: pending
**Description**: Show confidence scores to users

### Task 4.2: Optimize Performance
**Status**: pending
**Description**: Cache requests, optimize prompts

### Task 4.3: Add Analytics
**Status**: pending
**Description**: Track extraction accuracy

---

**Current Focus**: Phase 1 - Foundation
**Next Task**: Task 1.1 - Setup Dependencies
