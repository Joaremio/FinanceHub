import 'package:flutter_test/flutter_test.dart';

import 'package:financehub/main.dart';

void main() {
  testWidgets('FinanceHub app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceHubApp());

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });
}
