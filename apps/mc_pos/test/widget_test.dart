import 'package:flutter_test/flutter_test.dart';
import 'package:mc_pos/main.dart';

import 'auth_cubit_test.dart';

void main() {
  testWidgets('POS app renders auth screen', (tester) async {
    await tester.pumpWidget(McPosApp(authPort: FakeAuthPort()));
    await tester.pumpAndSettle();
    expect(find.text('Mercado Cercano'), findsOneWidget);
  });
}
