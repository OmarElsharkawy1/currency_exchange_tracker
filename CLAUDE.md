# Currency Exchange Tracker — CLAUDE.md

Flutter take-home assessment for a senior role. Every rule in this file is a hard
constraint. If a task prompt conflicts with this file, stop and ask before writing code.
Do not "improve" on these rules with your defaults.

## Product

Live exchange rates for USD, EUR, GBP, SAR, JPY against EGP. Two screens: rates list
and currency detail (7-day line chart). Offline cache with a "last updated" indicator
and auto-refresh on reconnect.

API: fawazahmed0 currency-api.

- Latest: `https://latest.currency-api.pages.dev/v1/currencies/egp.json`
- Historical: `https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/egp.json`
- One call returns all currencies against EGP. No auth, no rate limits.

## Architecture

- Feature-first clean architecture. One feature module `rates` containing
  `data/`, `domain/`, `presentation/` (presentation holds both pages and both blocs —
  they share one repository and one domain). Shared infra in `lib/core/`
  (network, cache, theme, failures, clock, di).
- **No use-case classes.** Blocs call the repository directly. A class that only
  forwards to a repository is banned ceremony.
- Repository contract is abstract in `domain/`; `RatesRepositoryImpl` in `data/`.
- DTOs (`Dto` suffix) never leave the data layer. Domain types have no suffix.
- No code generation anywhere: no freezed, no build_runner, no hive adapters.
  Sealed classes + `equatable` for states; JSON stored as strings in cache.
- DI via `get_it`, composed in `lib/core/di/injection.dart`. Constructor injection
  everywhere; no service-locator calls inside widgets or blocs (only at composition).

### Tree — the feature module matches this exactly. One type per file.

```
features/rates/
  domain/
    entities/         exchange_rate.dart, currency.dart, rate_direction.dart,
                      rate_comparison.dart, rates_snapshot.dart
    repositories/     rates_repository.dart (abstract)
  data/
    dtos/             rates_response_dto.dart
    data_sources/     rates_remote_data_source.dart, rates_local_data_source.dart
    repositories/     rates_repository_impl.dart
  presentation/
    blocs/ pages/ widgets/
```

No `models/` directory: wire types live in `dtos/`, domain types in `entities/`.
The test tree mirrors this path for path.

## Rate math — the highest-risk correctness area. Read twice.

The API returns EGP→foreign (`egp.usd = 0.019227` means 1 EGP = 0.019227 USD).
The UI displays foreign→EGP (`1 USD = 52.01 EGP`), i.e. the **inverted** value.

- `ExchangeRate` is a value object in `domain/`. It stores the **raw** rate and the
  rate date, and exposes: `displayRate` (1/raw), `changeFrom(previous)`,
  `percentChangeFrom(previous)`, and `direction`.
- **Invert before you diff.** `change = (1/todayRaw) − (1/yesterdayRaw)`.
  Percentage is computed on the inverted values. Never diff raw rates and invert
  the delta — that produces a wrong number that looks plausible.
- **Direction semantics (do not trust stock-app intuition):**
  - display value UP ⇒ more EGP per foreign unit ⇒ **EGP weakening ⇒ red / down**
  - display value DOWN ⇒ **EGP strengthening ⇒ green / up**
  - (Equivalently: raw `egp.usd` UP ⇒ EGP stronger ⇒ green. The two views move
    opposite ways. All color decisions key off `ExchangeRate.direction`, nowhere else.)
- The characters `1 /` applied to a rate must never appear under `presentation/`.
  If a widget needs a number, the value object already computed it.

## Dates & time

- **Never derive API dates from device local time.** Fetch `latest` first, read the
  `date` field from the response body, and anchor all historical dates from it.
- Historical walk-back: if a date 404s (weekend/missing file), step back one day,
  max 3 extra steps per data point, then surface `RateUnavailableFailure`.
- `DateTime.now()` is banned everywhere except inside the injected `Clock`
  implementation in `core/`. Everything time-dependent takes a `Clock`.
- `DateTime.toApiDate()` extension for `YYYY-MM-DD` formatting lives in `core/`.

## Network

- `dio`. Primary host `cdn.jsdelivr.net` (fawazahmed0 currency-api mirror), automatic
  fallback to `currency-api.pages.dev` via a Dio interceptor when the primary fails.
  Document which is primary in the README.
- Map **every** `DioException` / `SocketException` / parse error to a sealed `Failure`
  **at the data-source boundary**. Raw exceptions must never reach a bloc.
- Sealed hierarchy in `core/failures/`: `NetworkFailure`, `TimeoutFailure`,
  `CacheMissFailure`, `ParseFailure`, `RateUnavailableFailure`.

## Cache (two policies, not one)

- `hive_ce` (+ `hive_ce_flutter`). Not hive v2. Store JSON strings, no adapters.
- `latest` rates → stored with fetch timestamp; refreshed on pull-to-refresh and on
  reconnect; served when offline with the stored timestamp exposed for the banner.
- Historical `{date}` rates → **immutable, write-once, never refetched** if present.
  Historical data cannot change; a TTL on it is a bug.

## Connectivity

- `connectivity_plus` gives radio state only — airport WiFi with no internet still
  reports `wifi`. Pair it with a real reachability probe
  (`internet_connection_checker_plus`). `ConnectivityCubit` in `core/` merges both.
- Debounce the reconnect stream; exactly one auto-refresh per reconnect, no stampede
  when connectivity flaps.

## State management

- `flutter_bloc`. Exactly: `RatesListBloc`, `CurrencyDetailBloc`, `ConnectivityCubit`.
  No `AppBloc`, no god-bloc.
- The detail screen receives the `ExchangeRate` entity **through the route** and
  fetches only the 7-day history. It must never refetch or show a loading state for
  the current rate the list already has in memory.
- States: sealed base class + `equatable`, outcome suffixes:
  `RatesLoadInProgress`, `RatesLoadSuccess`, `RatesLoadFailure`.
- Events: subject + past-tense verb: `RatesRequested`, `RatesRefreshed`.
- Blocs contain state transitions and nothing else: no arithmetic, no string
  formatting, no `DateTime.now()`, no color decisions.

## Widgets

- **Never `Widget _buildX()` methods.** Extract `class _X extends StatelessWidget`
  with a `const` constructor. No exceptions, including small headers.
- Widget layer logic: `switch` on sealed state only. No other conditionals.
- Up/down semantic colors come from a `ThemeExtension` (`TrendColors` with
  `strengthening` / `weakening`). Hardcoded `Colors.green` / `Colors.red` at a call
  site is a defect.
- RTL-safe: `EdgeInsetsDirectional`, `start`/`end`, `AlignmentDirectional`.
  Never `left`/`right`.
- Numbers via `NumberFormat` (`intl`), never `toStringAsFixed` + string concatenation.
- `Semantics` labels on rate rows, e.g.
  "US Dollar, 57.88 Egyptian pounds, down 0.3 percent".
- Context extensions in `core/`: `context.colors`, `context.textStyles`,
  `context.trendColors`.

## Loading / error / empty

- `skeletonizer` for all content loading states (list rows AND chart). The chart
  requirement says shimmer, not spinner — no `CircularProgressIndicator` in content
  areas anywhere.
- Error states: user-friendly message mapped from the `Failure` type + retry action.
  Never show exception text to the user.

## Packages — whitelist

`dio`, `flutter_bloc`, `equatable`, `hive_ce`, `hive_ce_flutter`,
`connectivity_plus`, `internet_connection_checker_plus`, `fl_chart`,
`skeletonizer`, `flutter_animate`, `intl`, `get_it`.
Dev: `very_good_analysis`, `bloc_test`, `mocktail`, `flutter_test`.
Anything not on this list: stop and ask.

## Lints & hygiene

- `analysis_options.yaml` includes `very_good_analysis`, and the package is declared
  in `dev_dependencies` (verify the include actually resolves — a silently no-oping
  include ships zero lints).
- `prefer_const_constructors` escalated to `error`.
- A `BlocObserver` logging transitions, active in debug builds only.
- Zero analyzer warnings, `dart format` clean, all tests green **at every commit**.

## Testing

- Rule: if it can't be unit-tested without importing `flutter_test`, it's in the
  wrong layer.
- Required coverage: `ExchangeRate` (fixtures covering the inversion asymmetry and a
  small-magnitude JPY case), repository (dual cache policy, host fallback, date
  walk-back — mocked Dio/Hive), all blocs via `bloc_test` with mocked repository.
- Time-dependent tests use an injected fake `Clock`; no real clocks in tests.

## Naming reference

| Thing              | Convention                         | Example                                   |
| ------------------ | ---------------------------------- | ----------------------------------------- |
| Files              | snake_case, role suffix            | `rates_remote_data_source.dart`           |
| Repo contract/impl | abstract in domain, `Impl` in data | `RatesRepository` / `RatesRepositoryImpl` |
| Domain type        | no suffix                          | `ExchangeRate`                            |
| Wire type          | `Dto` suffix                       | `RatesResponseDto`                        |
| Bloc events        | subject + past-tense verb          | `RatesRequested`, `RatesRefreshed`        |
| Bloc states        | sealed + outcome suffix            | `RatesLoadSuccess`, `RatesLoadFailure`    |
| Booleans           | `is` / `has` / `should`            | `isStale`, `hasCachedData`                |

No abbreviations except domain-standard ones (EGP, USD, API, DTO, JSON).
No `curRate`, `hist`, `resp`, `prev`.

## Definition of done — every phase

1. `flutter analyze` → zero issues
2. `flutter test` → all green
3. `dart format .` → no diff
4. No silent TODOs; unresolved questions go back to me in the summary
