import 'package:flutter_test/flutter_test.dart';

void main() {
  // Smoke test: verify the test framework initialises correctly for this app.
  // Full widget integration is covered by timer_50_cycles_test.dart and
  // session_repository_test.dart; the original counter-app test no longer
  // applies to this Pomodoro codebase.
  testWidgets('flutter test binding initialises', (WidgetTester tester) async {
    expect(tester.binding, isNotNull);
  });
}
