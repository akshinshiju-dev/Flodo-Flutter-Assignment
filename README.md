# Flodo Task Manager 📋

A polished Flutter Task Management App built for the Flodo AI Take-Home Assignment.

---

## Track & Stretch Goal

| Item | Choice |
|------|--------|
| **Track** | **B – Mobile Specialist** (local SQLite, no backend) |
| **Stretch Goal** | **Debounced Autocomplete Search** — 300ms debounce + match-text highlighting |

---

## Features

### Core
- ✅ **CRUD** — Create, Read, Update, Delete tasks
- ✅ **Task fields** — Title, Description, Due Date, Status (To-Do / In Progress / Done), Blocked By
- ✅ **Blocked tasks** — Greyed-out cards with a 🔒 BLOCKED badge; auto-resolved when blocking task is marked Done
- ✅ **Draft persistence** — Typing in the New Task form? Swipe back and return — your text is still there (via SharedPreferences)
- ✅ **2-second save delay** — Simulated on Create and Update, with a loading spinner. The Save button is disabled during the wait (no double-tap)
- ✅ **Search** — Live text filter on task titles
- ✅ **Status filter** — Chips to filter by All / To-Do / In Progress / Done
- ✅ **Overdue detection** — Due dates in the past are highlighted in red

### Stretch Goal — Debounced Search
- 300ms debounce: the list filters 300ms after the user *stops* typing (no jank from every keystroke)
- Matching text within task titles is **highlighted in purple** with a subtle background

### UI/UX Polish
- Dark & Light theme with a toggle in the AppBar
- Inter font via Google Fonts
- Status indicator chips (color-coded)
- Stats summary row (count per status)
- Empty state illustrations
- Animated FAB with spring curve
- Smooth `AnimatedOpacity` on blocked task cards
- Confirmation dialog before delete
- Overdue date indicator
- Snackbar feedback on create / update / delete

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter / Dart |
| State | `provider` (ChangeNotifier) |
| Local DB | `sqflite` |
| Draft cache | `shared_preferences` |
| Fonts | `google_fonts` (Inter) |
| Date format | `intl` |

---

## Setup Instructions

### Prerequisites

1. **Flutter SDK** ≥ 3.0.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. Verify installation:
   ```bash
   flutter doctor
   ```
3. An Android emulator / physical device (or iOS simulator on macOS)

### Run the App

```bash
# 1. Clone / enter the project directory
cd "Flodo Flutter Assignment"

# 2. Install dependencies
flutter pub get

# 3. Run on connected device / emulator
flutter run

# Build release APK (optional)
flutter build apk --release

# Run widget & unit tests
flutter test
```

---

## Project Structure

```
lib/
├── main.dart                              # App entry point
├── app.dart                               # MaterialApp + providers
├── core/
│   ├── database/database_helper.dart      # sqflite singleton CRUD
│   ├── models/task.dart                   # Task model + TaskStatus enum
│   └── theme/app_theme.dart              # Light/dark themes + AppColors extension
├── features/tasks/
│   ├── providers/task_provider.dart       # ChangeNotifier state logic
│   ├── screens/
│   │   ├── task_list_screen.dart          # Main list (search, filter, list)
│   │   └── task_form_screen.dart          # Create / Edit form + draft
│   └── widgets/
│       ├── task_card.dart                 # Card UI (blocked badge, highlight)
│       ├── status_filter_chips.dart       # Filter chip row
│       └── highlighted_text.dart          # Search match highlight widget
└── shared/widgets/
    └── loading_button.dart                # Button with spinner + disabled state
```

---

## AI Usage Report

### Most Helpful Prompts

1. **Architecture prompt** — *"Design a clean Flutter project structure for a Task Management app using Provider, sqflite, and SharedPreferences for draft persistence. Include a Task model with copyWith, toMap/fromMap."* → Generated the full folder layout and data model skeleton instantly.

2. **Debounce pattern** — *"Show me how to implement a 300ms debounced search in Flutter using dart:async Timer, without any extra packages."* → Generated the exact `_debounce?.cancel(); _debounce = Timer(...)` pattern.

3. **Draft persistence** — *"How do I save and restore form field text using SharedPreferences in Flutter, clearing it only after a successful save?"* → Produced the `_loadDraft / _saveDraft / _clearDraft` pattern used in `task_form_screen.dart`.

### AI Hallucination Fixed

**Issue:** The AI initially suggested using `DropdownButton<int>` (non-nullable) for the "Blocked By" dropdown. This caused a type error because the value needs to be `null` when no task is selected.

**Fix:** Changed to `DropdownButton<int?>` and added an explicit `DropdownMenuItem<int?>(value: null, ...)` as the first item. Also had to pass `hint:` instead of relying on a null-value item to show placeholder text.

---

## Design Decisions

1. **Provider over Riverpod/Bloc** — The app's state is simple enough that the overhead of Riverpod isn't justified. Provider with a single `TaskProvider` ChangeNotifier keeps the code readable and testable without ceremony.

2. **Manual Timer debounce** — No extra package (like `rxdart`) needed. `dart:async` `Timer` is zero-cost and exactly as expressive for this single use case.

3. **Draft on SharedPreferences, not in-memory** — Storing the draft in SharedPreferences survives app process kills (e.g., Android low-memory kills), not just back navigation. This meets the assignment's intent more robustly.

4. **`AnimatedOpacity` for blocked cards** — Smooth 300ms opacity transition when a blocker is resolved (marked Done), making the unblocking feel satisfying rather than abrupt.

5. **Sentinel object for `copyWith`** — `blockedById` is nullable. Rather than using a separate `clearBlockedBy` flag, a private `_sentinel` constant lets `copyWith` distinguish *"caller passed null"* from *"caller passed nothing"*.

6. **Cascade unblock on delete** — When a task is deleted from the DB, `blocked_by_id` is set to `NULL` for all dependents in the same transaction. The provider also patches its in-memory list synchronously to avoid a reload round-trip.

---

## Tests

```bash
flutter test
```

Covers:
- `Task` model: `copyWith`, `toMap/fromMap` round-trip, equality, `TaskStatus.fromString`
- `TaskProvider`: blocked-logic unit test
- **Widgets**: `HighlightedText`, `LoadingButton` (idle + loading states), `StatusFilterChips`, `TaskCard` (display, delete callback, no BLOCKED badge for unblocked task)

---

## Demo Video

[Google Drive link — see submission email]

> **Screens recorded in demo:** task creation (2s delay + spinner), search highlight, blocked task badge, draft restore after back-navigation, dark/light toggle.

