import 'package:flutter_test/flutter_test.dart';

import 'package:ludo/main.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LudoApp());

    expect(find.text('Ludo Flutter'), findsOneWidget);
    expect(find.text('Démarrer en local'), findsOneWidget);
  });
}
