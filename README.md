# currency_exchange_tracker

Live exchange rates for USD, EUR, GBP, SAR and JPY against the Egyptian pound,
with a 7-day history chart, an offline cache and a "last updated" indicator.

## Getting started

```bash
flutter pub get
flutter run
```

Tested against Flutter 3.35 / Dart 3.9. Runs on Android, iOS, web and desktop
targets — no platform-specific code beyond `connectivity_plus`.

### Tests

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

`flutter test` runs the whole suite (unit, bloc, widget). Every widget test
defaults to a phone-sized surface (`test/flutter_test_config.dart`) instead of
the framework's 800×600 default: a row that overflows on a real handset used to
lay out happily in a test, and now doesn't.

## Architecture

Feature-first clean architecture. One feature module, `rates`, containing
`data/`, `domain/` and `presentation/`; shared plumbing (network, cache,
theme, failures, clock, DI) lives in `lib/core/`.

```
lib/
├── core/                       shared infra, no feature imports
│   ├── clock/                  the only place DateTime.now / Timer live
│   ├── connectivity/           radio + reachability, merged and debounced
│   ├── di/injection.dart       composition root (the one core → features exception)
│   ├── failures/               sealed Failure hierarchy + Result tuple
│   ├── formatting/             RateFormatter (intl-only, no toStringAsFixed)
│   ├── network/                endpoints + host-fallback interceptor
│   └── theme/                  ThemeExtension, spacing, motion
└── features/rates/
    ├── domain/                 entities + repository contract, no Flutter
    ├── data/                   dtos, data sources, repository impl
    └── presentation/           blocs, pages, widgets, semantics formatting
```

Composition happens in `lib/main.dart` + `lib/app.dart` + `lib/core/di/injection.dart`.
Blocs and widgets receive collaborators through constructors or providers;
`getIt` is never touched below composition.

### Why no use-case classes

A use case that only forwards to a repository is a class that adds a filename
and takes a call. The rules the project actually cares about — cache policy,
mirror fallback, date anchoring, walk-back — belong to the repository, because
they cross both data sources. The bloc's job is state transitions. Adding a
`GetLatestRatesUseCase` between the two would give us a `.call()` that
literally reads `return _repository.getLatestRates();`, and would split rules
that must move together across two files. So blocs call the repository
directly.

### Why the cache has two policies, not one

`latest` and dated snapshots are different kinds of data and get different
treatment:

- **`latest`** is mutable. It is refetched on pull-to-refresh and on reconnect,
  and served (with its original fetch timestamp — the "last updated"
  indicator) when the network fails. A 15-minute TTL keeps repeated cold
  opens from hammering the API without hiding actual moves.
- **`historical_{YYYY-MM-DD}`** is written once and never rewritten.
  Historical rates cannot change — that day's number is what it was — so
  refetching them would be a waste, and applying a TTL to them would be a
  bug. This also lets the 7-day walk-back get faster the longer the app is
  used: yesterday's fetched history is tomorrow's cache hit.

The two policies live in the repository, not in the data source, because they
are a domain decision (what does "cache" mean for this kind of data?) that
happens to be implemented on top of one Hive box.

### Why dates are anchored on the API response

The obvious way to build a 7-day history is `DateTime.now()` and subtract.
The obvious way is wrong for this API:

- The device clock can be off by hours, or in a wildly different time zone,
  or wrong entirely.
- The API publishes on business days — a weekend or a holiday leaves a hole
  where a file simply does not exist. `date - 1 day` from a Monday points at
  a Sunday that never had a snapshot.

So the app fetches `latest` first, reads the `date` field out of the response
body, and walks back from _that_ date. When a dated fetch 404s (weekend /
missing file), the remote data source steps one calendar day back and
retries, up to 3 extra steps per point; the repository walks up to
`days + 7` calendar dates looking for `days + 1` distinct published files.
The extra published day is the oldest plotted point's predecessor, so every
day the chart shows has a movement to report.

The `DateTime.now()` ban is enforced by the CLAUDE.md audit — the only place
it appears is inside `SystemClock`. Same for `Timer`.

### Why the direction semantics are inverted from what a stock app suggests

The API quotes EGP → foreign (`egp.usd = 0.019227` means 1 EGP buys
0.019227 USD). The UI shows foreign → EGP (`1 USD = 52.01 EGP`). The two
views move in opposite directions:

- Display rate **up** ⇒ more EGP per foreign unit ⇒ **EGP weakening** ⇒
  painted in the weakening (red) trend colour.
- Display rate **down** ⇒ **EGP strengthening** ⇒ painted in the
  strengthening (green) trend colour.

The colour never comes from an arrow reading of the chart line — it comes
from `ExchangeRate.direction`, resolved through the `TrendColors` theme
extension. A `Colors.green` at a call site would be a bug.

The other rate-math trap is inversion order: every comparison inverts
**before** it subtracts. Subtracting the raw quotes and then inverting the
delta gives a completely different, plausible-looking number.

## Data source

[fawazahmed0 currency-api](https://github.com/fawazahmed0/exchange-api). No
auth, no rate limits; one document carries every currency quoted against EGP.

The API is served from two mirrors, and the app uses both:

| Role         | Host                     | Latest                                                         | Dated                                                                |
| ------------ | ------------------------ | -------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Primary**  | `cdn.jsdelivr.net`       | `/npm/@fawazahmed0/currency-api@latest/v1/currencies/egp.json` | `/npm/@fawazahmed0/currency-api@{YYYY-MM-DD}/v1/currencies/egp.json` |
| **Fallback** | `currency-api.pages.dev` | `https://latest.currency-api.pages.dev/v1/currencies/egp.json` | `https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/egp.json` |

jsDelivr is primary: it is a CDN with wider edge coverage, and the pages.dev
mirror is the project's own origin. `HostFallbackInterceptor` retries a failed
primary request once against the fallback, rebuilding the URL because the two
mirrors spell the version differently (path segment vs. subdomain).

A `404` is **not** retried on the fallback: it means the dated snapshot does
not exist upstream, which is equally true on both mirrors. That case is
handled by the walk-back (above).

## History window

The detail chart shows the **last 7 published rates, not the last 7 calendar
days** — the source publishes on business days, so a week of rates spans more
than a week of dates whenever a weekend or holiday intervenes. The repository
keeps stepping back until it has 7 distinct published dates (plus one more as
the oldest point's predecessor), and the axis labels are the real file dates.

## Connectivity

`connectivity_plus` reports the radio only — airport wifi with no route still
reports `wifi` — so `ConnectivityCubit` merges it with a reachability probe and
debounces the result by 2 seconds, giving exactly one auto-refresh per
reconnect. The probe is pointed at the currency API itself rather than the
checker's default third-party hosts, and it probes both mirrors, so **"online"
here means "at least one mirror the data source can actually use answered a
HEAD request", not "some DNS somewhere resolved"** — a network that blocks the
API reads as offline, and one that blocks only jsDelivr still reads as online
because the host-fallback interceptor can serve from `pages.dev`.

## State management

`flutter_bloc`. Three, and no more: `RatesListBloc`, `CurrencyDetailBloc`,
`ConnectivityCubit`. No app-wide god bloc. Blocs contain state transitions
and nothing else — no arithmetic, no formatting, no clock, no colours. Every
number a widget shows was already computed by the domain layer; every string
was already formatted by `RateFormatter`; every colour was already keyed off
`ExchangeRate.direction` through the theme.

The detail screen receives the `ExchangeRate` for the tapped row through the
route argument and paints it on the first frame. Only the 7-day history is
loaded, and only the chart has a loading state — the header is not blank for
a moment after tap.

## Loading, error, empty

Every content-area loading state is a `skeletonizer` shimmer built from the
real widgets it replaces (rate rows, chart silhouette). No
`CircularProgressIndicator` in content areas. Error and offline screens map
the sealed `Failure` hierarchy to human copy at a single site
(`failure_messages.dart`); a raw exception message never reaches the user.

## Packages

Runtime: `dio`, `flutter_bloc`, `equatable`, `hive_ce`, `hive_ce_flutter`,
`connectivity_plus`, `internet_connection_checker_plus`, `fl_chart`,
`skeletonizer`, `flutter_animate`, `intl`, `get_it`.

Dev: `very_good_analysis`, `bloc_test`, `mocktail`, `flutter_test`.

No code generation, no `freezed`, no `build_runner`, no Hive adapters. The
cache holds the API's own JSON as strings.
