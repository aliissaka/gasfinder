import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasSeen returns false on a fresh install', () async {
    expect(await OnboardingScreen.hasSeen(), isFalse);
  });

  test('markSeen flips the flag and persists', () async {
    expect(await OnboardingScreen.hasSeen(), isFalse);
    await OnboardingScreen.markSeen();
    expect(await OnboardingScreen.hasSeen(), isTrue);
  });

  testWidgets('Suivant advances pages and Commencer calls onDone', (tester) async {
    var doneCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onDone: () => doneCalled = true),
    ));

    // First page renders
    expect(find.text('Trouvez du gaz près de chez vous'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);

    // Advance through pages
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Pourquoi votre position ?'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Fonctionne hors ligne'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(doneCalled, isTrue);
    expect(await OnboardingScreen.hasSeen(), isTrue);
  });

  testWidgets('Passer dismisses the flow and marks seen', (tester) async {
    var doneCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onDone: () => doneCalled = true),
    ));

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(doneCalled, isTrue);
    expect(await OnboardingScreen.hasSeen(), isTrue);
  });
}
