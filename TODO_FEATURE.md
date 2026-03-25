# Todo Feature (One-time & Recurring) + Habit Import

This file documents the enhanced Todo system with habit import from API.

## Overview

Extended the todo system to support:
- Enhanced recurring habits with schedules, categories, tags, descriptions, checklists.
- Import habits from `https://staticapis.pragament.com/daily/habits.json`.
- Browse, search, filter, sort habits by categories/tags/schedules.
- Bulk select and import as recurring todos.
- View imported habits with search/filter/sort.
- Bulk edit schedules.
- Home widget reminders for habits.
- Local notifications for habit reminders.
- Wallpaper setting for habits.

## Key Files

- `lib/models/todo_model.dart`
  - Added: `description`, `category`, `tags`, `checklist`, `schedule` fields.

- `lib/provider/todo_provider.dart`
  - Added: `fetchHabitsFromApi()`, `importHabits()`.
  - Enhanced: `addTodo()`, `editTodo()` with new fields.

- `lib/habit_import_page.dart`
  - New page: Search/filter/sort habits, bulk select for import.

- `lib/todo_home_page.dart`
  - Enhanced: Display new fields, edit with schedule.
  - Added: Selection for bulk edit (placeholder).

- `lib/habit_widget.dart`
  - New widget: Display habit title and next reminder.

- `lib/main.dart`
  - Added: Habit widget update logic, interactive callback for habit completion.

- `lib/quote_home_page.dart`
  - Added: Import habits button in AppBar.

- `pubspec.yaml`
  - Added: `flutter_local_notifications` for reminders.

## Behavior Summary

1. Tap download icon on quotes page → `HabitImportPage`.
2. Fetch habits from API, search/filter by title/description/category/tags.
3. Select multiple habits, import as recurring todos.
4. View in `TodoHomePage` with enhanced details.
5. Home widget shows next habit reminder.
6. Notifications scheduled based on habit schedules.
7. Wallpapers can be set for habits (similar to quotes).

## API Integration

Fetches from `https://staticapis.pragament.com/daily/habits.json`:
- Habits with title, description, category, tags, checklist, schedule.
- Schedule types: daily/weekly/monthly/yearly/interval with details.

## Notes

- Bulk edit schedules not fully implemented (placeholder).
- Notification scheduling logic needs implementation based on schedule.
- Home widget extension for habits added.
- Existing quote features preserved.

## Notes

- No widget integration with todo data yet (future enhancement).
- Existing quote features remain untouched.
- Static analysis (`flutter analyze`) passes with no error from new code.
