import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// The rates list when the load succeeded but carried no currencies.
class RatesEmptyView extends StatelessWidget {
  /// Creates the empty view.
  const RatesEmptyView({required this.onRetry, super.key});

  /// Called when the user asks to load again.
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
              Icons.currency_exchange_outlined,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No rates to show right now.',
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
