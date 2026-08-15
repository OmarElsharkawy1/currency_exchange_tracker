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

# 2026-08-15 — Chart axis fix pass: bottom labels, insets, RTL

Prompt: Edge titles sit flush with the screen edge. Wrap each bottom title in SideTitleWidget(meta: meta, fitInside: SideTitleFitInsideData.fromTitleMeta(meta)) so first/last labels stay inside the chart bounds. Inset the whole chart with the same horizontal padding token the header uses (EdgeInsetsDirectional, no hardcoded numbers), so the first dot aligns with the header's leading edge. Show a label for every point — day-of-month, with the month shown once at the start or on a first-of-month change — formatted through intl, no string concatenation. Verify in RTL: labels must remain inside bounds and read right-to-left with the data.

Output: Every point now labelled (interval: 1), each wrapped in SideTitleWidget with fitInside. New AppSpacing token shared by header and chart padding; zero numeric insets left in the three detail-screen files. Month selection goes through two DateFormat patterns picked by a switch — no concatenation. Ten new tests covering label count, painted-text bounds, both month cases, the padding token, plot-area alignment, and four RTL cases. 273 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] Two corrections came out of the work rather than out of review, which is the point of writing the assertion before believing the implementation.

First, the bounds assertion was wrong in a way that would have failed a correct implementation. SideTitleWidget's own box stays centred on its tick and legitimately overhangs — the first label measured -15..47 against a 16..784 chart — while fitInside translates the child. Rather than accept the red as an implementation failure, I dumped the real geometry per frame: the painted Text sits at 22..84 and 765.6..778, comfortably inside. The test now measures the Text descendants, which is the thing that actually has to stay in bounds. Had I "fixed" the implementation to satisfy the original assertion, I'd have broken working behavior to please a bad test.

Second, the month rule had a hidden direction dependency. Keyed to plot order it named the month on the leftmost label, which under the mirrored reading was the newest day — the end of the reading direction, not the start. Making it chronological fixed it in both directions.

The RTL requirement was genuinely ambiguous — "read right-to-left with the data" supports either mirroring the series or only making the chrome directional — so it was implemented one way, flagged with the alternative priced at one line, and reversed on instruction. The reversal then removed more than it added: the plotted/chronological split, the date-keyed label map, and the index-space comment in the touch handler all disappeared, leaving \_labelAt(index) and a bare \_onTouch tear-off. That the weaker reading collapsed three indirections is decent evidence it was the right call.

Follow-ups: Two issued and closed — take the weaker RTL reading (drop the Directionality switch, keep the four RTL tests with inverted assertions, simplify the month rule now that oldest is always leftmost), and leave the widget fixture at 6 points rather than growing it to 7. The 7-day window stays pinned where it is actually decided, in the detail bloc test via captured arguments; the widget fixture only exercises label, bounds and scrub behavior.

# 2026-08-15 — Theme toggle: light / dark / system

Prompt: "add a button to change between dark and light modes." Then three follow-up changes: (1) persist ThemeMode under a theme_mode key in the existing Hive box, read before runApp, written on change, kept in core/ rather than the rates repository; (2) make it a three-way cycle — system → light → dark → system — with the icon reflecting the mode rather than the resolved brightness, a distinct icon for system, and a Semantics label reading the mode, removing platform-brightness sniffing entirely; (3) the same button on the detail screen AppBar. Tests for the persisted round-trip and the cycle order.

Output: ThemeModeController (a ValueNotifier, not a fourth bloc), ThemeModeScope (InheritedNotifier), ThemeModeStore (Hive, core/theme/), and ThemeModeButton on both AppBars. Restored mode is read in main.dart before runApp and passed into the app widget; every cycle step writes back. 295 tests green, analyzer clean, format clean, still exactly three blocs/cubits and zero platformBrightness references in lib/.

Verdict: Accepted

Why: [draft] The first decision was a constraint check, not a design one: CLAUDE.md says "Exactly: RatesListBloc, CurrencyDetailBloc, ConnectivityCubit. No AppBloc." A ThemeCubit is the obvious shape and would have broken that rule, so the state went into a ValueNotifier provided at composition — the same pattern Clock already uses — and the summary carried a grep proving the count unchanged. Choosing the compliant path meant the work didn't need to block on a question.

Two failures were informative rather than annoying. RepositoryProvider refuses Listenable subtypes by design — providers won't rebuild dependents for one — which pushed the design to InheritedNotifier, where the dependency mechanism both delivers the rebuild and scopes it to the button. And IconButton(tooltip:) populates the semantics tooltip property, not label, so find.bySemanticsLabel found nothing against a perfectly working button. Dumping the semantics tree rather than trusting either side settled it: the label is now explicit, with the tooltip excluded from semantics so assistive tech announces the mode once instead of twice.

Follow-ups: Three issued and closed in one pass (persistence, three-way cycle, detail-screen button). Twice in this work a new AppBar action broke existing page tests en masse — 29 on the list screen, then 27 on the detail screen — because the button requires a ThemeModeScope ancestor. Both times the fix was to give the tests the scope rather than to soften ThemeModeScope.of into a silent fallback: a missing scope means real wiring is broken and should stay loud.

# 2026-08-15 — Phase 4b: Detail header & chart interaction fixes

Prompt: Fix two symptoms on the detail screen: (a) touching a chart point loses the change and shifts the date style — resting and scrubbed headers are visibly different widgets; (b) the 7 history points are invisible, so the user has to hover to find them. Six items: RateHistoryPoint / RateHistory in domain delegating all math to ExchangeRate; getHistory fetching days + 1 so every displayed point has a change, newest point pinned to the anchored latest; selection as bloc state with tap/scrub/clear events and tap-selection surviving a drag; one \_RateHeader taking a RateHistoryPoint, em-dash in the same slot when change is null, plus a "Latest" chip; visible tappable dots with a 24dp threshold, indicator line, no built-in tooltip; a chart Semantics summary. Verify the dot count is 7. Report analyze/test/format and the presentation/ greps.

Output: Two domain value types, repository returning RateHistory with days + 1 fetching, bloc carrying RateHistory + selectedIndex with a \_pinnedIndex for scrub-then-release, one header widget (old currency_detail_header.dart deleted), and a chart with per-day dots, ring-highlighted selection, dashed indicator, and handleBuiltInTouches: false. Then two follow-ups: the screen-reader phrasing extracted to a shared function used by both screens, and the walk-back policy changed from "fewer dots is acceptable" to "keep stepping until days + 1 distinct published dates, bounded, else fail". 327 tests green, analyzer clean, format clean, all presentation/ greps zero.

Verdict: Accepted

Why: [draft] The dot-count question turned out to be the same defect as symptom (a): the old code fetched days dates and spent one as a predecessor, so it plotted 6 and left the oldest point with no change. Fetching days + 1 fixed the count and the missing movement in one move — worth noting because the prompt listed them as separate items.

Three things the tests caught that reasoning alone would not have:

The "Latest" chip shoved the rate line down 28px when it appeared. My first assertion had compared resting-without-chip against selected-with-chip, so the test was measuring the wrong pair — but the jump underneath was real. Fixed with a reserved-height action row, then split into two honest tests: em-dash vs real movement (both selected), and chip present vs absent.
The chart's Semantics label merged with the axis labels, announcing "…Egyptian pounds, Mar 1, 2, 3, 4…". Dumping the semantics tree showed the concatenation rather than guessing at it.
Two repository tests were stale under the new history policy and were replaced rather than patched: one asserted the collapse behavior the follow-up rejected, the other had stubbed every date to a single cached day and only passed because fewer dots used to be acceptable.
The layering flag I raised on the first follow-up proved half-right, which is the useful outcome: moving rate_semantics.dart into the feature module cleaned up the core → features edge, but running the confirming grep showed core/di/injection.dart importing six feature types. That is the composition root doing its job, not a violation — so the recorded rule carries its one exception explicitly instead of pretending the grep was clean.

Follow-ups: Three issued, all closed.

Consolidate the duplicated screen-reader phrasing (list-screen exclusion lifted) — one function, both call sites, two widget tests pumping the list row and the detail header with the same day and asserting identical bySemanticsLabel.
Change the walk-back policy so a weekend spans more calendar days rather than dropping dots — "last 7 published rates, not last 7 calendar days", bounded at 7 extra days then RateUnavailableFailure, documented in the README. Today being Saturday was the concrete trigger; a reviewer opening the app would have seen 5–6 points.
Move rate_semantics.dart out of core/ and record the layering grep.

# 2026-08-15 — Polish pass: motion, RTL, semantics, contrast

Prompt: No logic changes. Staggered list entrance via flutter_animate; TweenAnimationBuilder rolling the rate numbers old→new on refresh; refined skeleton layouts matching the loaded layout exactly; an RTL audit run under Directionality.rtl fixing any EdgeInsets/left/right leftovers; a semantics audit against TalkBack/VoiceOver phrasing; a dark-theme audit for TrendColors contrast. Every animation ≤400ms, curves consistent. Where flash and clarity conflict, pick clarity and note it.

Output: AppMotion as the single motion vocabulary — one curve, four durations, all ≤400ms, and no milliseconds: literal left anywhere else in lib/. Staggered row entrance keyed by currency, a RollingRate widget that starts on its real figure rather than rolling up from zero, and a chart skeleton reserving the same axis constant the real chart uses. Three audits run as measurements rather than inspections: contrast computed numerically, semantics dumped from the live tree, RTL exercised under Directionality. 343 tests green, analyzer clean, format clean, all five phase-7 greps zero.

Verdict: Accepted

Why: [draft] Each audit was run as a measurement, and each one returned something other than what the brief predicted.

The contrast audit failed on the light theme, not the dark one. Dark measured 10.60 and 6.68 against its surface — never in question. Light green measured 4.37, under the 4.5 AA floor for body text, and was darkened to clear at 5.16. Had this been a visual inspection rather than a computation, the pass would have concluded "dark looks fine" and shipped the failing theme. My own first "distinguishable" assertion then used the wrong instrument — contrast ratio measures luminance, so a red and a green can match on it while being obviously different — and was replaced with hue separation plus a note that colour is never the sole signal.

The semantics dump found rows announcing without an isButton flag — a screen reader would read the rate and give no indication the row opens anything. The first fix wrapped the row in MergeSemantics, which worked in the tree but made the assertion unreachable, so the flag moved onto RateRow itself and the merge disappeared: one node by construction rather than two stitched together.

The animation removed rows from the semantics tree. The dump showed no row nodes at all mid-fade — Flutter drops semantics for fully transparent subtrees. It resolves in 260ms, so it would never have been caught by looking at the screen. The fix respects MediaQuery.disableAnimationsOf, which is the right answer for a reduce-motion user regardless.

The explicit clarity-over-flash calls: numbers roll on refresh only, never during a chart scrub, because rolling would lag the finger and display intermediate values that were never that day's rate; and RollingRate omits its tween begin so a first paint shows the real figure instead of counting up from zero.

Follow-ups: None issued.

# 2026-08-15 — Hero fix: badge instead of text

Prompt: The Hero on the currency code clips to "US" mid-flight and pops to "USD" at the end — text snapshot at destination size, intermediate layouts truncate. Move the Hero tag off the code Text and onto a fixed-size currency badge, same tag list→detail; let the code and name in the detail header appear via the normal route fade with no Hero. Remove the text Hero entirely. Create a badge widget if none exists and use it on both screens. Verify by pushing and popping repeatedly — nothing may clip, snap or flash. Widget test: the same Hero tag exists exactly once on each screen. Stop and say so if a text Hero should be kept.

Output: CurrencyBadge, a const 40×40 disc, is now the only thing either screen puts inside a Hero; both text Heroes are gone, along with the detail header's code line and the list row's separate code text. 6 tests on a real two-route app: tag present exactly once per screen, the Hero's child asserted to be a CurrencyBadge by type, identical measured size at both ends, a single distinct size across every mid-flight frame, and three push/pop round trips with no exception. 349 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] Your diagnosis was right, and there was a second instance of the same defect one layer up that only measuring found. After moving the Hero onto the badge the whole suite passed — but the badge measured 40×40 on the list and 40×36 on the detail screen, because the header's top row still carried a fixed 36px height from the earlier chip-jump fix, quietly squeezing it. Unequal end rects are precisely what the Hero interpolates, so the fix would have shipped looking done while still clipping. The row is now sized by CurrencyBadge.size, which keeps the chip-doesn't-shove-the-layout property for free since the badge is the tallest always-present element; the orphaned headerActionRow token was deleted rather than left behind.

The mid-flight test is the one that actually encodes the root cause: it collects the badge's size on every frame of the transition into a Set and asserts the set has exactly one member. A constant rect is what removes the interpolation, so that assertion fails the moment someone puts text back in the Hero or changes one screen's sizing.

Follow-ups: None issued.

# 2026-08-15 — Chart: value axis, curve tokens, padded range

Prompt: On RateHistoryChart's LineChartBarData: keep isCurved, set preventCurveOverShooting: true and curveSmoothness to ~0.2 via a named constant in AppMotion or a chart-style token — no literals in the widget. Add a y-axis: left titles showing the range minimum and maximum (and the midpoint if it fits), formatted through intl at the same precision as the header, reserved width via a constant, SideTitleWidget with fitInside like the bottom axis. Pad the plotted y-range ~10% above and below the data. Update the skeleton to reserve the same left width. Widget test asserting the min/max labels equal the series extremes at display precision.

Output: Style tokens (curveSmoothness, verticalHeadroom, axisValueWidth, minHeightForMidpointLabel) sit as named constants on the chart beside the existing touchThreshold / axisLabelHeight. Left axis renders low / midpoint / high through RateFormatter.spokenRate, wrapped in SideTitleWidget with fitInside. Frame padded 10% each side, with a separate absolute margin for a flat series. Skeleton reserves the same left width and its tree is now const. 8 new chart tests. 355 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] The interesting constraint was that "labels show the range minimum and maximum" fights "pad the range 10%" — fl_chart generates ticks from the axis frame, so naive settings would have labelled the padded bounds, printing two numbers that appear nowhere in the data. Reading iterateThroughAxis in the package rather than guessing gave the mechanism: baselineY: dataMin with interval: range / 2 and minIncluded/maxIncluded: false makes the ticks measure from the data while the frame sits outside them. The test asserts the label text equals spokenRate of the real series extremes and that minY/maxY fall outside those values, so the two requirements are pinned against each other.

"Midpoint if it fits" was implemented as an actual measurement — a LayoutBuilder drops to a two-label interval below 160px — rather than assumed to fit. The flat-series case was handled explicitly because a zero range makes both the padding and the tick interval degenerate.

I put the curve token on the chart rather than in AppMotion as offered: that class is durations and curves for animation, and line smoothing is not motion. Flagged rather than assumed.

Follow-ups: None issued.

# 2026-08-15 — Skeleton overflow at phone widths, phone surface as test default

Prompt: rate_history_chart_skeleton.dart:101 overflows by 64 on device — seven fixed 60-wide children (420) in a 356-wide row after axisValueWidth. Replace the fixed widths with Expanded (or fractions from a LayoutBuilder) so the placeholder row fits any constraints. Then fix the test gap: pump the skeleton and the real chart at 360×640 and 320×568, assert takeException() is null and the skeleton's plot-area left edge equals the loaded chart's. Add a phone-sized surface helper in test/support/ and use it in skeleton, chart, list and detail tests — the 800×600 default is what hid this. Report which tests changed size and whether any of them fail at 320 before the fix.

Output: RateHistoryChartSkeleton bars and label bones now sit inside Expanded + FractionallySizedBox, widths driven by named fractions (columnWidthFactor, labelWidthFactor). MainAxisAlignment.spaceBetween is gone — the flexible slots do the spacing. PhoneSurface (medium 360×640, small 320×568) plus a usePhoneSurface tester extension in test/support/. New chart_phone_sizes_test.dart runs the skeleton and the chart at both, asserts no exception, and asserts the two plot areas share left edge and width. 361 tests green, analyzer clean, format clean.

Verdict: Accepted

Why: [draft] The report you asked for was the important part of this pass, not the fix. Before the fix the existing detail-page and list-page tests failed 49 times at 320 with a RenderFlex overflowed by 184 pixels cascading from the skeleton (144 at 360). After the fix they still failed 49 times — from two different, smaller overflows the skeleton bug had been masking: 19px in the detail header's movement row, and 39px in the list row's contents. Reporting that rather than shipping "green at medium" is what the pass was actually for. The skeleton widths were only the loudest instance of a class of defect.

The one place I used more care than the prompt required was the mid-flight assertion: the phone-sizes test collects the skeleton's plot rect and the chart's plot rect and compares both left and width, so nothing subtle can drift them apart later.

Tests changed to phone size: the two page suites via the shared helper, plus the new chart-sizes file at both widths. currency_badge_hero_test.dart was deliberately not moved this pass — you would ask me to next.

Did anything fail at 320 before the fix: 49 tests, all cascades of a single skeleton RenderFlex overflow: 184px. After: still 49, from two unrelated production overflows now newly visible.

Follow-ups: One issued as the next pass — fix both, pin the page tests at 320.

# 2026-08-15 — 320px layout: header wrap, row ellipsis, state views scrollable, phone surface global

Prompt: Fix both narrow-screen overflows. Detail header movement row: don't ellipsize the date — let it wrap below change/percent (Wrap or two-line). Verify the "Latest" chip fits at 320 with a selection active. List row: Expanded on the name/code column with the name ellipsizing; rate column keeps natural width, no FittedBox on numbers. If any currency's name + rate + badge still can't fit at 320, stop and tell me — that's a design call. Pin page tests at 320 (medium as a second run if cheap), move currency_badge_hero_test.dart to the phone surface, and make the phone surface the default in shared test setup so desktop width is opt-in. Report which tests changed and confirm 320 is green with no takeException.

Output: Detail header movement is now a Wrap — the date drops beneath change + percent when it doesn't fit, chip verified. Name column ellipsizes on one line. A third overflow surfaced along the way: the three state views (error / empty / offline) at short chart-slot heights, wrapped in SingleChildScrollView. test/flutter_test_config.dart makes PhoneSurface.medium the default for every test; useDesktopSurface() is the opt-out. Detail page pinned at 320 and green. Stopped on the list row and reported measurements. 361/365 tests green — the 4 red are the badge-hero cases hitting the list-row overflow, awaiting the design call.

Verdict: Accepted

Why: [draft] The list-row block was the useful outcome. Measured at 320: the rate sentence alone is 275pt in an available 288pt content strip; the badge (40) plus its gap (12) cost 52pt, so the sentence has nowhere to go regardless of what the name column does. Ellipsizing the name — which the prompt suggested — doesn't help, because it's not the name that pushes the row wide. Stopping there was the correct answer; four options were priced without picking one, with a recommendation (shorten the sentence to 52.36 EGP on narrow screens, since the code lives inside the badge and the name sits next to it, so 1 USD = is redundant).

Two implementation notes worth carrying:

The global surface default cannot be applied through setSurfaceSize — that method asserts it is running inside a test body, so a global setUp fails every pure-Dart test with "'inTest': is not true". The fix was to resize platformDispatcher.implicitView.physicalSize directly with devicePixelRatio = 1, which works from anywhere. Debugging why 200-odd pure-Dart tests suddenly went red gave the answer; guessing another mechanism would have taken longer.

The state-view overflow (18px vertical) was a genuine third defect that only appeared once the header stopped clipping. Applied identically to all three views — mechanical, no design tradeoff.

Follow-ups:
