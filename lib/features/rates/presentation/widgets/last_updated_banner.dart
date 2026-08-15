import 'dart:async';

import 'package:currency_exchange_tracker/core/clock/clock.dart';
import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// When the rates on screen were fetched, and where they came from.
///
/// Offline it speaks in relative time — "5 minutes ago" answers "can I trust
/// this number?" better than a clock time does — and it keeps counting, so a
/// screen left open does not freeze on the figure it was born with.
class LastUpdatedBanner extends StatelessWidget {
  /// Creates the banner.
  const LastUpdatedBanner({
    required this.lastUpdated,
    required this.isFromCache,
    required this.isOffline,
    super.key,
  });

  /// When the payload behind these rates was fetched.
  final DateTime lastUpdated;

  /// Whether the rates were served from the cache.
  final bool isFromCache;

  /// Whether the device currently has no route to the network.
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.bodySmall?.copyWith(
      color: switch (isOffline) {
        true => context.colors.onErrorContainer,
        false => context.colors.onSurfaceVariant,
      },
    );

    return Container(
      width: double.infinity,
      color: switch (isOffline) {
        true => context.colors.errorContainer,
        false => context.colors.surfaceContainerHighest,
      },
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      // Only the offline copy is time-relative, so only it carries a ticker;
      // the absolute variants are plain text that never needs rebuilding.
      child: switch ((isOffline, isFromCache)) {
        (true, _) => _RelativeTimeLabel(
          lastUpdated: lastUpdated,
          prefix: 'Offline — last updated ',
          style: style,
        ),
        (false, true) => Text(
          'Showing saved rates from ${RateFormatter.timestamp(lastUpdated)}',
          style: style,
        ),
        (false, false) => Text(
          'Last updated ${RateFormatter.timestamp(lastUpdated)}',
          style: style,
        ),
      },
    );
  }
}

/// A label that re-reads the clock every minute.
///
/// Its own widget so the rebuild stops here: the banner container, the list
/// and everything else stay put while this one `Text` re-renders.
class _RelativeTimeLabel extends StatefulWidget {
  const _RelativeTimeLabel({
    required this.lastUpdated,
    required this.prefix,
    required this.style,
  });

  /// The moment being described.
  final DateTime lastUpdated;

  /// Copy placed before the elapsed time.
  final String prefix;

  /// Style for the rendered line.
  final TextStyle? style;

  @override
  State<_RelativeTimeLabel> createState() => _RelativeTimeLabelState();
}

class _RelativeTimeLabelState extends State<_RelativeTimeLabel>
    with WidgetsBindingObserver {
  /// The label's finest granularity is a minute, so ticking faster would
  /// rebuild for nothing.
  static const Duration _tickInterval = Duration(minutes: 1);

  late final Clock _clock;
  StreamSubscription<void>? _ticks;

  @override
  void initState() {
    super.initState();
    _clock = context.read<Clock>();
    _ticks = _clock.ticks(_tickInterval).listen((_) => _reread());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ticks do not accrue while backgrounded, so a returning app would show
    // its pre-background figure until the next one lands.
    switch (state) {
      case AppLifecycleState.resumed:
        _reread();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _reread() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // `dispose` cannot await; the subscription is dropped either way.
    unawaited(_ticks?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = RateFormatter.relativeTime(
      widget.lastUpdated,
      now: _clock.now(),
    );
    return Text('${widget.prefix}$elapsed', style: widget.style);
  }
}
