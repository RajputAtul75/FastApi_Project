import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nyayaai_mobile/main.dart';
import 'package:nyayaai_mobile/state/app_state.dart';

void main() {
  testWidgets('Smoke test - landing page renders brand name', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const NyayaAIApp(),
      ),
    );

    // Verify that the title NyayaAI is rendered on the screen.
    expect(find.text('NyayaAI'), findsWidgets);
  });
}
