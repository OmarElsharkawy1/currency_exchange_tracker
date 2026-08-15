import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/theme/app_theme.dart';
import 'package:currency_exchange_tracker/features/rates/presentation/widgets/last_updated_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_clock.dart';

void main() {
  late FakeClock clock;

  final lastUpdated = DateTime(2024, 3, 6, 9, 5);

  setUp(() {
    clock = FakeClock(DateTime(2024, 3, 6, 9, 10));
  });

  tearDown(() => clock.dispose());

  Future<void> pumpBanner(
    WidgetTester tester, {
    required bool isOffline,
    bool isFromCache = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RepositoryProvider<Clock>.value(
          value: clock,
          child: Scaffold(
            body: LastUpdatedBanner(
              lastUpdated: lastUpdated,
              isFromCache: isFromCache,
              isOffline: isOffline,
            ),
          ),
        ),
      ),
    );
  }

  group('offline — relative and ticking', () {
    testWidgets('reads the elapsed time from the clock', (tester) async {
      await pumpBanner(tester, isOffline: true);

      expect(find.text('Offline — last updated 5 minutes ago'), findsOneWidget);
    });

    testWidgets('re-reads it on every tick', (tester) async {
      await pumpBanner(tester, isOffline: true);

      clock.advance(const Duration(minutes: 1));
      await tester.pump();

      expect(find.text('Offline — last updated 6 minutes ago'), findsOneWidget);
      expect(find.text('Offline — last updated 5 minutes ago'), findsNothing);
    });

    testWidgets('keeps ticking', (tester) async {
      await pumpBanner(tester, isOffline: true);

      for (var minute = 0; minute < 3; minute++) {
        clock.advance(const Duration(minutes: 1));
        await tester.pump();
      }

      expect(find.text('Offline — last updated 8 minutes ago'), findsOneWidget);
    });

    testWidgets('ticks once a minute', (tester) async {
      await pumpBanner(tester, isOffline: true);

      expect(clock.requestedPeriod, const Duration(minutes: 1));
    });

    testWidgets('cancels the tick subscription when disposed', (tester) async {
      await pumpBanner(tester, isOffline: true);
      expect(clock.hasTickListener, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(clock.hasTickListener, isFalse);
    });

    testWidgets('re-reads the clock when the app is resumed', (tester) async {
      await pumpBanner(tester, isOffline: true);

      // Backgrounded for a while: no ticks were delivered.
      clock.instant = clock.instant.add(const Duration(minutes: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        find.text('Offline — last updated 35 minutes ago'),
        findsOneWidget,
      );
    });
  });

  group('online — absolute and static', () {
    testWidgets('shows a cache timestamp without claiming offline', (
      tester,
    ) async {
      await pumpBanner(tester, isOffline: false);

      expect(
        find.text('Showing saved rates from Mar 6, 09:05'),
        findsOneWidget,
      );
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('shows a live timestamp', (tester) async {
      await pumpBanner(tester, isOffline: false, isFromCache: false);

      expect(find.text('Last updated Mar 6, 09:05'), findsOneWidget);
    });

    testWidgets('starts no ticker when there is nothing relative to show', (
      tester,
    ) async {
      await pumpBanner(tester, isOffline: false);

      expect(clock.hasTickListener, isFalse);
    });
  });
}
