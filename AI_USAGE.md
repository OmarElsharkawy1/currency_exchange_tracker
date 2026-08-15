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

# 2026-08-15 — Phase 4: Detail screen & 7-day chart

Prompt: Build CurrencyDetailBloc + detail screen. Route contract: the list passes the ExchangeRate entity (plus previous-day data) through the route; the detail screen renders current rate, change, direction color and last-update date immediately from that entity — no fetch, no loading state for it. The bloc fetches only the 7-day history via getHistory, anchored per CLAUDE.md. Chart: fl_chart line chart, gradient fill, animates on data arrival; Robinhood-style touch-scrub showing the touched point's value + date in the header and reverting on release; Skeletonizer shimmer while history loads — chart-shaped skeleton, not a box; history failure → friendly message + retry while the header rate stays visible. Hero on the currency code/flag between list row and detail header. bloc_test for history transitions.

Output: Detail bloc + sealed event/state families documented as covering the chart only, a stateful page holding scrub state, header, chart, and a chart-shaped skeleton. Chart plots displayRate with curved line, gradient fill and a 450ms ease-out on data arrival; scrub reports the touched day upward and the header swaps to its value + date, reverting on release. Named routes added (AppRoutes + onGenerateRoute), so the composition root is the only place touching getIt; Hero on the currency code both ends. 207 tests green (9 bloc, 17 detail widget, 1 new route-contract test), analyzer clean, format clean. Five decisions flagged.

Verdict: Accepted

Why: [draft] The route contract is enforced by tests, not just implemented: the header renders the rate while state is HistoryLoadInProgress, is asserted to sit outside the skeletonized subtree, and survives HistoryLoadFailure with the retry beside it — so "no loading state for the header" can't silently regress. A chart test pins spots.last.y ≈ 52.36, meaning a raw-quote regression fails loudly rather than rendering a plausible wrong line, which is the same inversion trap CLAUDE.md flags as highest-risk. Widget-layer rules held: scrub state resolves through pattern switches (switch (scrubbedPoint) { null => …, final point => … }), never an if or a ??, and colors still key only off direction. Two duplications got caught and removed rather than shipped: the header printed the currency name the AppBar already showed, and the bloc re-declared a 7 the repository contract already owned.

Follow-ups: None issued yet.

2026-08-15 — Phase 5: Connectivity & offline
Prompt: Build ConnectivityCubit in core merging connectivity_plus radio events with an internet_connection_checker_plus reachability probe — radio "wifi" without internet must read offline — debouncing transitions ~2s so flapping doesn't stampede. Wire in: offline → persistent banner "Offline — last updated {timestamp}" from cache metadata using relative time via intl; reconnect → exactly one automatic RatesRefreshed; cold start offline → serve cache silently with banner; empty cache + offline → dedicated state, not a generic error. Tests: cubit debounce/merge with faked streams, repository offline paths, refresh-on-reconnect fires once per reconnect.

Output: Cubit taking two plain Stream<bool>s (package types confined to an adapter file), three-state sealed family with ConnectivityUnknown for cold start, 11 tests including airport-wifi and a 10-flap storm settling on one emission. Bloc gained RatesConnectivityChanged and RatesUnavailableOffline; the reconnect refresh keys off the transition, so [off, on, off, on] yields exactly two refreshes. Dedicated offline view, banner rewritten to relative time via Intl.plural, clock provided by context. Four named repository offline-path tests. 240 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] The hard parts were right: the cubit is genuinely package-free and testable with two controllers, "exactly one refresh per reconnect" is a bloc-level assertion rather than a property of widget wiring, and the offline-empty case got its own sealed state instead of being mislabelled an error. Five decisions were surfaced rather than buried, and one of them — changing a phase-3 assertion that conflated "from cache" with "offline" — was flagged specifically because it altered already-accepted behavior. What the fix pass caught was not wrongness so much as three unfinished edges: tests that slept on a real clock, a relative-time label that never ticked, and a probe pointed at the wrong servers. All three were consequences I had named in the summary without treating as defects.

Follow-ups: A six-item fix pass (Phase 5b, below).

2026-08-15 — Phase 5b: Connectivity & banner fixes
Prompt: Fix pass, no new scope, six items in order: (1) add fake_async to the whitelist and remove every real-time wait from tests, restoring the 2s debounce default; (2) make the relative-time label tick — extend Clock with a periodic tick source, extract a \_RelativeTimeLabel StatefulWidget scoped to one Text, handle AppLifecycleState.resumed, test with a fake Clock, keep the ticker out of the bloc; (3) make a failed refresh visible via RatesLoadSuccess.refreshFailure + a SnackBar on the null→non-null edge, reusing the existing Failure→message mapping; (4) point the reachability probe at the API through the endpoints builder; (5) prove by grep that no arithmetic leaked into presentation/; (6) a do-not-change list. Stop and ask rather than pick silently on anything uncovered.

Output: All six delivered. fake_async added, cubit tests moved onto fake time at the shipped 2s default, and the six Future.delayed(Duration.zero) calls deleted outright once shown unnecessary. Clock.ticks added; \_RelativeTimeLabel subscribes in initState, cancels in dispose, observes lifecycle, and exists only on the offline branch. refreshFailure threaded through state, bloc and a record-pattern listenWhen. Probe repointed at CurrencyApiEndpoints. All four greps returned zero. Then two follow-up rounds: Clock.after + Clock injection into the cubit (fakeAsync dropped entirely, 0 references), both mirrors probed, an end-to-end bridge test added, and fake_async finally removed from pubspec and whitelist. 263 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] Two moments decided this entry. First: item 2's CLAUDE.md edit ("the only real timer is SystemClock.ticks") was false the instant it was written, because the cubit builds a Timer for its debounce — and item 6 forbade the API change that would fix the code. Rather than ship a rule the codebase violates, the contradiction was surfaced with both options priced; the ruling lifted item 6 and the rule is now true, with one Timer( in the entire codebase. Second: item 4 said "the latest URL", singular, which would have made a jsDelivr-only block read as offline even though the fallback interceptor could still serve rates — flagged rather than silently widened, then widened on instruction. The verification asked for in item 5 also did real work: it was the grep that exposed the timer contradiction, not a rubber stamp.

The bridge-delivery question was answered with evidence (zero cubit references in the bloc test; all six deletions sat between direct bloc.add calls) and then went further than asked — the check revealed that the bridge test used a mock bloc while the bloc tests used direct adds, so nothing joined real cubit → page → real bloc → repository. That seam is now covered by three tests driven purely by pushing booleans into the source streams.

Follow-ups: Three fix rounds issued and closed
