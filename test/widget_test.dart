import 'package:flutter_test/flutter_test.dart';

import 'package:notepad_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the notepad app shell', (tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Notepad'), findsOneWidget);
    expect(find.byType(NotepadHomeScreen), findsOneWidget);
  });
}
