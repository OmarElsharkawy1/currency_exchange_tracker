# currency_exchange_tracker

Live exchange rates for USD, EUR, GBP, SAR and JPY against the Egyptian pound,
with a 7-day history chart, an offline cache and a "last updated" indicator.

## Data source

[fawazahmed0 currency-api](https://github.com/fawazahmed0/exchange-api). No auth,
no rate limits; one document carries every currency quoted against EGP.

The API is served from two mirrors, and the app uses both:

| Role         | Host                        | Latest                                                                     | Dated                                                                          |
| ------------ | --------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Primary**  | `cdn.jsdelivr.net`          | `/npm/@fawazahmed0/currency-api@latest/v1/currencies/egp.json`               | `/npm/@fawazahmed0/currency-api@{YYYY-MM-DD}/v1/currencies/egp.json`             |
| **Fallback** | `currency-api.pages.dev`    | `https://latest.currency-api.pages.dev/v1/currencies/egp.json`               | `https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/egp.json`             |

jsDelivr is primary: it is a CDN with wider edge coverage, and the pages.dev
mirror is the project's own origin. `HostFallbackInterceptor` retries a failed
primary request once against the fallback, rebuilding the URL because the two
mirrors spell the version differently (path segment vs. subdomain).

A `404` is **not** retried on the fallback: it means the dated snapshot does not
exist upstream, which is equally true on both mirrors. That case is handled by
the walk-back instead — step one day back, at most three extra days, then
surface `RateUnavailableFailure`.

## History window

The detail chart shows the **last 7 published rates, not the last 7 calendar
days** — the source publishes on business days, so a week of rates spans more
than a week of dates whenever a weekend or holiday intervenes. The repository
keeps stepping back until it has 7 distinct published dates (plus one more as
the oldest point's predecessor), and the axis labels are the real file dates.

## Rate direction

The API quotes EGP → foreign (`egp.usd = 0.019227`); the UI shows foreign → EGP
(`1 USD = 52.01 EGP`). All comparisons invert *before* they subtract. A rising
display rate means the pound buys less, so it is rendered as the pound
*weakening*.

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

## Cache

`hive_ce`, JSON strings, no adapters:

- `latest` — mutable, stamped with its fetch time, refreshed on pull-to-refresh
  and on reconnect, and served (with that timestamp) when the network fails.
  Served without a refetch for 15 minutes.
- `historical_{YYYY-MM-DD}` — written once and never rewritten. Historical rates
  cannot change, so a TTL on them would be a bug.

## Getting started

```bash
flutter pub get
flutter test
flutter run
```
