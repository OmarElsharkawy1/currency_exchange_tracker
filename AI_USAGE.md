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

# Prompt3:

> Build the data layer per CLAUDE.md: (1) RatesResponseDto parsing {date, egp:{~200 rates}} down to the five tracked currencies with a ParseFailure path for malformed/missing keys; (2) RatesRemoteDataSource on Dio with the jsDelivr↔pages.dev host-fallback interceptor, all exceptions mapped to Failures at that boundary; (3) date anchoring off the latest response's date field plus 404 walk-back (max 3 extra steps); (4) RatesLocalDataSource on hive_ce storing JSON strings under a dual policy — latest timestamped/refreshable, historical write-once immutable; (5) RatesRepository abstract in domain + RatesRepositoryImpl with getLatestRates() (latest + yesterday attached) and getHistory(currency, {days = 7}) checking the immutable cache per date first. Tests with mocktail covering fallback trigger, historical cache-hit never touching network, latest-cache staleness, 404 walk-back, exception→Failure mapping table. Inject Clock, no real time in tests.

# Output:

11 production files (DTO, both data sources, repository impl, RateComparison/RatesSnapshot/RatesRepository in domain, CurrencyApiEndpoints + HostFallbackInterceptor + Result typedef in core), DI wired, README documenting jsDelivr as primary. Tests written before each implementation, RED verified per component. 136 tests green, flutter analyze 0 issues, dart format clean. Six under-specified decisions flagged for sign-off rather than silently chosen: Result tuples over throws, 404 skipping the fallback, 15-min latest TTL, best-effort previous day rendering as flat/0, historical entries keyed by the payload's own date (with dedup), and getHistory propagating a per-day failure instead of a partial chart.

Verdict: Accepted

Why: [draft] Hard constraints held: no codegen, no use-case classes, DTO confined to the data layer, 1 / nowhere near presentation, DateTime.now() only in Clock, walk-back capped at 3, dual cache policy real (write-once verified by verifyNever(put)). Tests are behavioral, not mock-shaped — the interceptor and remote source are exercised through a real Dio with a faked HttpClientAdapter, so the fallback and the mapping table are proven against actual transport behavior rather than a stubbed client. Gaps are judgment calls the spec did not cover, surfaced as questions instead of buried defaults.

# Follow-ups:

One issued — a structural correction, not a functional one. Domain files had been written flat in domain/; the follow-up added the canonical tree to CLAUDE.md and required the code to match it: entities into domain/entities/, the abstract contract into domain/repositories/, data/models/ deleted, one type per file. Applied across lib and test (test tree mirrored path for path), imports rewritten, 136 tests still green, analyzer clean.

Two things surfaced during it worth recording:

The tree as written named only three entity files; rate_comparison.dart and rates_snapshot.dart also exist, so they were filed under entities/ and added to the CLAUDE.md listing rather than left undocumented. Still open if you want them separated (e.g. a value_objects/ sibling).
First move attempt used git mv and failed — the files were never committed, so they weren't under version control. Imports were rewritten before the moves landed, leaving the tree briefly broken; redone with plain mv in the same turn. Root cause is that none of this work is committed yet.
The six sign-off decisions from the original output remain unanswered — no follow-up touched them.

# 2026-08-15 — Phase 3: Rates list feature

# Prompt:

Build RatesListBloc + the list screen per CLAUDE.md. Bloc: RatesRequested / RatesRefreshed events, sealed RatesLoadInProgress / RatesLoadSuccess / RatesLoadFailure states, success carrying entities + lastUpdated + isFromCache, no math or formatting in the bloc. UI: five rows with currency name, code, display rate as "1 USD = 52.01 EGP" via NumberFormat, absolute + percentage change, color from context.trendColors keyed off direction; Skeletonizer rows while loading; pull-to-refresh; failure state mapped to a friendly message per Failure type with retry; empty state handled; Semantics label per row; every extracted piece a private widget class, zero \_build methods. bloc_test coverage for all transitions including refresh-while-loaded.

# Output:

Bloc + sealed event/state families, a page whose body is one exhaustive switch, and five widget-class files (row, skeleton list, error view, empty view, last-updated banner), plus RateFormatter (all intl) and a Failure→copy extension so no widget reasons about failure types. Skeleton rows are real RateRows under Skeletonizer, so the shimmer matches the loaded shape exactly. Wired into app.dart and DI as a factory. 178 tests green (13 bloc_test, 15 widget, 14 formatter), analyzer clean, format clean. Five decisions flagged for sign-off rather than silently taken.

# Verdict: Accepted

# Why:

[draft] Every hard constraint held: no \_build methods, widget logic is a single sealed switch with no stray conditionals (the cache banner picks copy via switch (isFromCache), not a ternary), colors resolve only through context.trendColors keyed on direction, all numbers go through NumberFormat, EdgeInsetsDirectional throughout, no CircularProgressIndicator anywhere. The bloc stays a transition machine — the pass-through test asserts identical(state.rates, repositoryRates), so it provably computes nothing. Tests caught two real design gaps rather than rubber-stamping the code: a JPY day-move rounds to +0.00 at two decimals (formatter now widens to four below 0.01), and the semantics label had to encode CLAUDE.md's counterintuitive rule — egpWeakening announces "up 0.66 percent" while painted in the weakening color. Two failures during the run were test-harness bugs, not product bugs, and were fixed on the test side: Skeletonizer is abstract so find.byType misses its subclass, and BlocBuilder latches state from the stream so re-pumping with a changed state stub silently kept showing the first state — that one would have made three assertions pass vacuously.

# Follow-ups:

None issued yet.
