/// Every route name in the app.
///
/// Navigation calls reference these constants; a route string typed at a call
/// site is a defect.
abstract final class AppRoutes {
  /// The rates list, the app's home.
  static const String ratesList = '/';

  /// One currency's detail screen.
  ///
  /// Takes the currency's `RateComparison` as its route argument: the detail
  /// screen renders the rate from it immediately instead of refetching.
  static const String currencyDetail = '/currency';
}
