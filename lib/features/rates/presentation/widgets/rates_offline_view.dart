import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Shown when the device is offline and nothing has ever been cached.
///
/// Deliberately not the error view: nothing failed, there is simply nothing
/// saved to fall back on yet.
class RatesOfflineView extends StatelessWidget {
  /// Creates the view.
  const RatesOfflineView({required this.onRetry, super.key});

  /// Called when the user asks to try again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Scrollable so a short screen — a phone in the chart slot, or one with
    // large text — can still reach the button instead of clipping it.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No connection, and no saved rates yet.',
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Rates will load as soon as you are back online.',
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
