/// A currency tracked against the Egyptian pound.
///
/// The [responseKey] is the lowercase key this currency appears under in the
/// `egp.json` payload of the fawazahmed0 currency API.
enum Currency {
  /// United States dollar.
  usd(code: 'USD', englishName: 'US Dollar', responseKey: 'usd'),

  /// Euro.
  eur(code: 'EUR', englishName: 'Euro', responseKey: 'eur'),

  /// British pound sterling.
  gbp(code: 'GBP', englishName: 'British Pound', responseKey: 'gbp'),

  /// Saudi riyal.
  sar(code: 'SAR', englishName: 'Saudi Riyal', responseKey: 'sar'),

  /// Japanese yen.
  jpy(code: 'JPY', englishName: 'Japanese Yen', responseKey: 'jpy')
  ;

  const Currency({
    required this.code,
    required this.englishName,
    required this.responseKey,
  });

  /// Uppercase ISO 4217 code, e.g. `USD`.
  final String code;

  /// Full English name, e.g. `US Dollar`.
  final String englishName;

  /// Key this currency is published under in the API response, e.g. `usd`.
  final String responseKey;

  /// The currency published under [responseKey], or `null` when the key is
  /// not one of the five tracked currencies.
  ///
  /// The lookup is case-sensitive: the API always emits lowercase keys, and
  /// silently accepting other casings would hide a wire-format change.
  static Currency? fromResponseKey(String responseKey) {
    for (final currency in Currency.values) {
      if (currency.responseKey == responseKey) return currency;
    }
    return null;
  }
}
