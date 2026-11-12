import 'package:flutter_test/flutter_test.dart';

import 'package:notepad_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the workspace picker on first launch', (tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pumpAndSettle();

    expect(find.text('Notepad'), findsOneWidget);
    expect(find.text('A calmer place for your notes'), findsOneWidget);
    expect(find.text('Choose a folder'), findsOneWidget);
  });
}
