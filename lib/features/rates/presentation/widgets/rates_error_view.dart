import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/failures/failure.dart';
import 'package:currency_exchange_tracker/core/failures/failure_messages.dart';
import 'package:flutter/material.dart';

/// The rates list when there is nothing to show and something went wrong.
class RatesErrorView extends StatelessWidget {
  /// Creates the error view for [failure].
  const RatesErrorView({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  /// What went wrong.
  final Failure failure;

  /// Called when the user asks to try again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              failure.userMessage,
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
