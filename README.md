# Notepad

A lightweight, file-first Flutter editor for ordinary `.txt` and `.md` documents.

## Everyday workflow

- **Open file** to choose an existing TXT or Markdown document from the device.
- **New text document** or **New Markdown document** to start from a blank file.
- Edit in a simple monospaced text area.
- **Save** to write the current document, or **Save As** to choose another destination/name.
- Markdown documents can switch between source editing and rendered preview.
- Unsaved edits are protected by a close confirmation.

The app is designed around individual files, not a mandatory workspace folder or a notes database. Files remain ordinary documents that can be opened by other editors.

## Platform save behavior

On desktop platforms, an opened file is saved back to its selected path when possible. On Android, the system file picker may provide a temporary cached copy rather than a writable handle to the original document. To avoid silently overwriting only that temporary copy, Save uses the Android system save dialog; choose the destination for the saved document.

## Build and test

Install Flutter 3.x, then run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
```

## Project structure

- `lib/main.dart` — file-first home screen with Open and New actions.
- `lib/editor_screen.dart` — text editor, save/save-as, unsaved-change protection, and Markdown preview.
- `lib/note_service.dart` — TXT/MD file selection and persistence.
- `test/widget_test.dart` — app shell and new-document smoke tests.
