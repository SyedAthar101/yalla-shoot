// Smoke test for the Yalla Shoot app: the app builds and shows its title.
import 'package:flutter_test/flutter_test.dart';

import 'package:yalla_shoot/main.dart';

void main() {
  testWidgets('Yalla Shoot app builds and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const YallaShootApp());
    expect(find.text('يلا شوت'), findsWidgets);
  });
}
