# prompt

Read CLAUDE.md fully before writing anything. Create the Flutter project scaffold for the Currency Exchange Tracker. In this phase, build ONLY:

> 1. Folder structure per CLAUDE.md (`lib/core/...`, `lib/features/rates/...`) with placeholder barrel files where useful.
> 2. `analysis_options.yaml` with very_good_analysis (dev_dependencies) and `prefer_const_constructors` as error. Prove the include resolves by showing `flutter analyze` output.
> 3. `core/failures/` sealed Failure hierarchy per CLAUDE.md.
> 4. `core/clock/` — abstract `Clock` + system impl.
> 5. `core/theme/` — app theme + `TrendColors` ThemeExtension (strengthening/weakening), light + dark, plus `context.colors`, `context.textStyles`, `context.trendColors` extensions.
> 6. `core/di/injection.dart` with get_it wiring for what exists so far.
> 7. Debug-only `BlocObserver`.
> 8. `DateTime.toApiDate()` extension + unit test.
>
> No feature code, no network code yet. End with `flutter analyze` and `flutter test` output.

# used agent opus 5, effort high

# output

> Allow claude to write failures.dart
> lib/core/failures/failure.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/failures/failure.dart
> Allowed

> Allow claude to write clock.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/clock/clock.dart
> Allowed

> Allow claude to write date_time_extension.dart
> lib/core/extensions/date_time_extensions.dart
> Allowed

> Allow claude to write trend_colors.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/theme/trend_colors.dart
> Allowed

> Allow claude to write app_theme.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/theme/app_theme.dart
> allowed

> Allow claude to write context_extensions.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/extensions/context_extensions.dart
> allowed

> Allow claude to write app_bloc_observer.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/observers/app_bloc_observer.dart
> allowed

> Allow claude to write injection.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/core/di/injection.dart
> allowed

> Allow claude to write app.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/app.dart
> allowed

> Allow claude to write main.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/main.dart
> allowed

> Allow claude to create folder structure
> for d in core/cache core/network features/rates/data/data_sources features/rates/data/models features/rates/data/repositories features/rates/domain/entities features/rates/domain/repositories features/rates/presentation/blocs features/rates/presentation/pages features/rates/presentation/widgets; do mkdir -p lib/$d && touch lib/$d/.gitkeep; done && rm -f test/widget_test.dart && mkdir -p test/core/extensions test/core/theme && find lib -type d | sort
> allowed

> Allow claude to write date_time_extensions_test.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/test/core/extensions/date_time_extensions_test.dart
> allowed

> Allow claude to write app_theme_test.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/test/core/theme/app_theme_test.dart
> allowed

> Allow claude to run Format & analyze
> allowed
