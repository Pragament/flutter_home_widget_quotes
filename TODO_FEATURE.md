# Todo Feature (One-time & Recurring)

This file documents the new Todo extension added to the existing `flutter_home_widget_quotes` app.

## Overview

Added a minimal todo system with:
- One-time tasks (`isRecurring = false`), complete/delete.
- Recurring tasks (`isRecurring = true`), check to update last completion date and keep active.
- Local persistence with Hive box: `todosBox`.
- UI in `TodoHomePage` with active vs completed list sections.
- Quick navigation from `QuoteHomePage` app bar.

## Key Files

- `lib/models/todo_model.dart`
  - `TodoModel` fields:
    - `id`, `title`, `isDone`, `isRecurring`
    - `createdAt`, `completedAt`, `lastCompletedAt`
  - `toMap()` / `fromMap()` for Hive serialization.

- `lib/provider/todo_provider.dart`
  - `TodoProvider` handles:
    - loading from `Box('todosBox')`
    - adding/editing/deleting/toggling todos
    - `pendingTodos` and `completedTodos` getters
    - recurring task logic (history state is kept while remaining pending)

- `lib/todo_home_page.dart`
  - UI
    - Add/Edit modal dialog with title and recurring toggle
    - active tasks with checkbox/edit/delete actions
    - completed one-time tasks with delete
    - overview labels

- `lib/main.dart`
  - open Hive box: `await Hive.openBox('todosBox');`
  - add provider: `ChangeNotifierProvider(create: (_) => TodoProvider())`

- `lib/quote_home_page.dart`
  - AppBar `IconButton` opens `TodoHomePage`

## Behavior Summary

1. Users can tap checklist icon from quotes screen.
2. Add todo (task title + recurring flag). 
3. Toggle complete:
   - one-time: moved to completed list + completion time.
   - recurring: updates `lastCompletedAt` and remains in active list.
4. Edit or delete tasks.

## Notes

- No widget integration with todo data yet (future enhancement).
- Existing quote features remain untouched.
- Static analysis (`flutter analyze`) passes with no error from new code.
