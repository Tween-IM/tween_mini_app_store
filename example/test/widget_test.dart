import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_store_example/main.dart';

void main() {
  testWidgets('mini app store example starts', (WidgetTester tester) async {
    await tester.pumpWidget(const HostDemo());
    await tester.pumpAndSettle();
    expect(find.text('Tween Mini Apps'), findsOneWidget);
  });
}
