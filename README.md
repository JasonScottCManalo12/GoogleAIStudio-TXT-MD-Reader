# Notepad

A focused Flutter app for browsing, writing, and previewing `.txt` and `.md` files in a folder you choose. It is designed to feel lightweight without sacrificing useful editing safeguards.

## What changed

- Material 3 interface with light/dark system themes and a clearer visual hierarchy.
- Workspace header with note count, folder switching, pull-to-refresh, and sort controls.
- Fast search across note titles and content.
- Better empty, loading, error, and no-results states.
- Note cards with file-type badges, previews, and readable timestamps.
- Editor with explicit save, automatic save, save status, character/word counts, and a Markdown preview.
- Safe filename cleanup for characters that are invalid on common filesystems.
- Renaming and switching between `.txt` and `.md` moves the existing note instead of leaving duplicates behind.
- Delete action with confirmation.
- Fixed the generated starter widget test and added a meaningful launch smoke test.

## Run locally

Install Flutter 3.x, then run:

```bash
flutter pub get
flutter test
flutter run
```

On Android, choose a directory with the folder button. The app reads and writes only `.txt` and `.md` files in that workspace.

## Project structure

- `lib/main.dart` — Material 3 shell, workspace browser, search, sorting, and states.
- `lib/editor_screen.dart` — note editor, Markdown preview, autosave, rename, and delete flow.
- `lib/note_service.dart` — folder preferences, file discovery, safe filenames, and persistence.
- `test/widget_test.dart` — launch smoke test.

## Notes

The app intentionally uses ordinary files rather than a database, so notes remain portable and can be opened by other tools. File errors are surfaced to the user instead of being silently ignored.
