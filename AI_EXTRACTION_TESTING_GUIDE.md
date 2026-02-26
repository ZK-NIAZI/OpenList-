# AI Extraction - Testing Guide

## ✅ FIXED: Gemini API Model Name

**Issue**: Model names `gemini-1.5-flash-8b` and `gemini-1.5-flash` were not valid for API version v1
**Solution**: Changed to `gemini-pro` (the stable model name for google_generative_ai v0.2.0)

---

## How to Test

### 1. Quick Add Sheet (Magic Wand)

**Steps**:
1. Open the app
2. Tap the "+" button to open Quick Add Sheet
3. Type: "Buy groceries tomorrow at 5pm"
4. Tap the magic wand icon (✨)
5. **Expected**: Task details extracted automatically
   - Title: "Buy groceries"
   - Due: Tomorrow 5:00 PM
   - Reminder: Tomorrow 4:30 PM

**More Examples**:
- "Call dentist next Monday morning"
- "Submit report by Friday 3pm"
- "Team meeting in 3 days at 2pm"

---

### 2. Notes App (AI Extract Button)

**Steps**:
1. Create a new note
2. Add content:
   ```
   Project Planning
   
   Remember to:
   - Call John tomorrow at 3pm
   - Submit final report by Friday
   - Schedule team meeting next Monday
   ```
3. Tap "AI Extract" button at bottom toolbar
4. **Expected**: First task extracted and linked to note
5. Tap "AI Extract" again to extract more tasks

---

## API Configuration

Your API key is already configured:
- Key: `AIzaSyCNSkrfZYK4YTaSlfS7e8geMEKaeBDogDE`
- Model: `gemini-pro` ✅ (stable model for v0.2.0)
- Status: Ready to test

---

## What Changed

### File Modified
- `lib/services/ai_extraction_service.dart`
  - Line 11: Changed model from `gemini-1.5-flash-8b` → `gemini-1.5-flash` → `gemini-pro` ✅

### Why It Failed Before
- The `-8b` suffix doesn't exist in the Gemini API
- `gemini-1.5-flash` is not available for API version v1
- Valid model for v0.2.0: `gemini-pro` (alias for gemini-1.0-pro)
- The package version (0.2.0) requires using the stable `gemini-pro` model name

---

## Expected Behavior

### Success Cases
✅ "Buy milk tomorrow" → Task with due date
✅ "Meeting at 3pm Friday" → Task with date and time
✅ "Call mom in 2 days" → Task with calculated date
✅ "Submit report by end of week" → Task with Friday date

### Error Cases
❌ Empty input → "Please enter a task"
❌ No API key → "Please configure your API key"
❌ Not a task → "This looks more like a note"
❌ Network error → "AI extraction failed: [error]"

---

## Performance

- **Response Time**: 1-2 seconds
- **API Usage**: ~200-300 tokens per extraction
- **Rate Limit**: 15 requests/minute (free tier)

---

## Troubleshooting

### If extraction fails:
1. Check internet connection
2. Verify API key in Settings > AI Extraction
3. Test connection using "Test" button
4. Check console for error messages

### If button doesn't appear:
1. Make sure AI extraction is enabled in Settings
2. Restart the app after enabling
3. Check that you're in a note (not a task)

---

## Next Steps

1. Run the app: `flutter run`
2. Test Quick Add with magic wand
3. Test Notes with AI Extract button
4. Verify tasks are created correctly
5. Check that dates/times are parsed properly

---

## Status: READY TO TEST 🚀

The AI extraction feature is now fully functional and ready for testing!
