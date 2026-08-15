import 'package:currency_exchange_tracker/core/theme/app_motion.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/rolling_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRate(WidgetTester tester, double displayRate) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RollingRate(currencyCode: 'USD', displayRate: displayRate),
        ),
      ),
    );
  }

  testWidgets('shows its figure immediately on the first frame', (
    tester,
  ) async {
    await pumpRate(tester, 52.3560);

    // No roll up from zero on arrival: the first paint is the real number.
    expect(find.text('1 USD = 52.36 EGP'), findsOneWidget);
  });

  testWidgets('rolls from the old figure to the new one', (tester) async {
    await pumpRate(tester, 52);
    await pumpRate(tester, 53);

    await tester.pump(const Duration(milliseconds: 150));
    final midway = tester.widget<Text>(find.textContaining('1 USD =')).data!;
    expect(midway, isNot('1 USD = 52.00 EGP'));
    expect(midway, isNot('1 USD = 53.00 EGP'));

    await tester.pump(AppMotion.value);
    expect(find.text('1 USD = 53.00 EGP'), findsOneWidget);
  });

  testWidgets('settles within the motion budget', (tester) async {
    await pumpRate(tester, 52);
    await pumpRate(tester, 53);

    await tester.pump(AppMotion.value);

    expect(find.text('1 USD = 53.00 EGP'), findsOneWidget);
    expect(
      AppMotion.value,
      lessThanOrEqualTo(const Duration(milliseconds: 400)),
    );
  });
}
