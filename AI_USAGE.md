# prompt1

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

# prompt2

Implement `ExchangeRate` in `features/rates/domain/` exactly per the "Rate math" section of CLAUDE.md, plus a `RateDirection` enum (`egpStrengthening`, `egpWeakening`, `flat`).

> Pure Dart only — importing anything from Flutter in this file is a failure.
>
> Write tests FIRST, then the implementation. Required fixtures:
>
> 1. rawYesterday = 0.019227, rawToday = 0.019100 → display goes 52.01 → 52.36 (UP), direction = egpWeakening. Assert change and percent are computed on INVERTED values (use `closeTo`).
> 2. The mirror case: raw rises → display falls → egpStrengthening.
> 3. Prove invert-before-diff ≠ diff-then-invert: assert the correct change value and assert it differs from `1/(rawToday − rawYesterday)`-style math.
> 4. JPY small-magnitude case (display ≈ 0.33 EGP): percentage still correct.
> 5. Equal rates → flat, zero change.
>
> Also: `Currency` enum or value type for the five currencies (code, English name, response key `usd`/`eur`/`gbp`/`sar`/`jpy`).

> allow claude to Read existing test and core conventions?
> rtk read test/core/extensions/date_time_extensions_test.dart && echo "=== failures ===" && rtk read lib/core/failures/failure.dart && echo "=== analysis ===" && rtk read analysis_options.yaml
> allowed

> Allow claude to write currency_test.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/test/features/rates/domain/currency_test.dart
> allowed

> Allow claude to write exchange_rate_test.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/test/features/rates/domain/exchange_rate_test.dart
> allowed

> Allow claude to Run domain tests, expect failure?
> flutter test test/features/rates/domain/ 2>&1 | tail -20
> allowed
> RED confirmed

> Allow claude to write currency.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/features/rates/domain/currency.dart
> allowed

> Allow claude to write rate_direction.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/features/rates/domain/rate_direction.dart
> allowed

> Allow claude to write exchange_rate.dart
> /Users/omarelsharkawy/Dev/projects/currency_exchange_tracker/lib/features/rates/domain/exchange_rate.dart
> allowed

> Allow claude to run domain tests?
> flutter test test/features/rates/domain/ 2>&1 | tail -25
> allowed
> +28: All tests passed!

> Allow claude to run Format, analyze, full tests?
> allowed
> +40: All tests passed!

> Allow claude to run List analyzer issues?
> flutter analyze 2>&1 | grep -E "error|info|warning" | head -10
> allowed
> error • Use 'const' for final variables initialized to a constant value • test/features/rates/domain/exchange_rate_test.dart:80:7 • prefer_const_declarations
> error • Use 'const' for final variables initialized to a constant value • test/features/rates/domain/exchange_rate_test.dart:87:7 • prefer_const_declarations
> error • Use 'const' for final variables initialized to a constant value • test/features/rates/domain/exchange_rate_test.dart:99:7 • prefer_const_declarations
> info • Unnecessary use of a 'double' literal • test/features/rates/domain/exchange_rate_test.dart:113:26 • prefer_int_literals
