import 'package:corejourney/features/onboarding/presentation/widgets/pre_payoff_step_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fills dots up to the 1-based currentStep', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrePayoffStepDots(currentStep: 2),
        ),
      ),
    );

    final dots = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(dots.length, 4);

    Color? fillOf(AnimatedContainer c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) return decoration.color;
      return null;
    }

    // Steps 1–2 filled, 3–4 hollow (transparent).
    expect(fillOf(dots.elementAt(0)), isNot(equals(Colors.transparent)));
    expect(fillOf(dots.elementAt(1)), isNot(equals(Colors.transparent)));
    expect(fillOf(dots.elementAt(2)), Colors.transparent);
    expect(fillOf(dots.elementAt(3)), Colors.transparent);
  });
}
