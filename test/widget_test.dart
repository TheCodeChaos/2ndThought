import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurogate/app.dart';

void main() {
  testWidgets('NeuroGate app starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NeuroGateApp(showOnboarding: true),
      ),
    );

    // Verify the app renders
    expect(find.text('Break the Loop'), findsOneWidget);
  });
}
