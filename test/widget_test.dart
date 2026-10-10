import 'package:flutter_test/flutter_test.dart';
import 'package:serenitalk_system/main.dart';

void main() {
  testWidgets('SereniTalk app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SereniTalkApp());

    expect(find.byType(SereniTalkApp), findsOneWidget);
  });
}
