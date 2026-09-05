import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Kurogane App welcome flow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KuroganeApp(hasSeenWelcome: false),
      ),
    );
    await tester.pump();
    expect(find.byType(KuroganeApp), findsOneWidget);
  });
}
