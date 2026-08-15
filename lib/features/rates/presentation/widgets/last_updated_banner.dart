import 'package:currency_exchange_tracker/core/extensions/context_extensions.dart';
import 'package:currency_exchange_tracker/core/formatting/rate_formatter.dart';
import 'package:flutter/material.dart';

/// When the rates on screen were fetched, and whether they came from cache.
class LastUpdatedBanner extends StatelessWidget {
  /// Creates the banner.
  const LastUpdatedBanner({
    required this.lastUpdated,
    required this.isFromCache,
    super.key,
  });

  /// When the payload behind these rates was fetched.
  final DateTime lastUpdated;

  /// Whether the rates were served from the cache.
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    final timestamp = RateFormatter.timestamp(lastUpdated);
    return Container(
      width: double.infinity,
      color: context.colors.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Text(
        switch (isFromCache) {
          true => 'Offline — showing rates saved $timestamp',
          false => 'Last updated $timestamp',
        },
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
