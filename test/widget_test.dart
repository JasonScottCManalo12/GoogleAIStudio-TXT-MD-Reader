import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notepad_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the file-first Notepad home screen', (tester) async {
    await tester.pumpWidget(const NotepadApp());

    expect(find.text('Notepad'), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);
    expect(find.byTooltip('Open file'), findsOneWidget);
    expect(find.text('New text document'), findsOneWidget);
    expect(find.text('New Markdown document'), findsOneWidget);
  });

  testWidgets('creates a new plain-text document', (tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.tap(find.text('New text document'));
    await tester.pumpAndSettle();

    expect(find.text('Untitled.txt'), findsOneWidget);
    expect(find.text('Plain text'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('creates a new Markdown document with preview action', (tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.tap(find.text('New Markdown document'));
    await tester.pumpAndSettle();

    expect(find.text('Untitled.md'), findsOneWidget);
    expect(find.byTooltip('Preview Markdown'), findsOneWidget);
  });
}
