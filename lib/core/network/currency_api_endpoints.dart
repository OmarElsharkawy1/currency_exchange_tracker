/// URLs for the fawazahmed0 currency API, on both of its mirrors.
///
/// Every payload is the same document — all currencies quoted against EGP —
/// addressed by a *version*: either [latestVersion] or a `YYYY-MM-DD` date.
/// The two mirrors spell that version differently, which is why the fallback
/// is a URL rebuild rather than a host swap.
abstract final class CurrencyApiEndpoints {
  /// Version token for the most recent published rates.
  static const String latestVersion = 'latest';

  /// Host of the primary mirror.
  static const String primaryHost = 'cdn.jsdelivr.net';

  /// Domain suffix of the fallback mirror; the version is its subdomain.
  static const String fallbackHostSuffix = 'currency-api.pages.dev';

  static const String _basePath = 'v1/currencies/egp.json';

  static final RegExp _primaryVersionPattern = RegExp(
    r'^/npm/@fawazahmed0/currency-api@([^/]+)/v1/currencies/egp\.json$',
  );

  /// Primary (jsDelivr) URL for [version].
  static Uri primary(String version) => Uri.parse(
    'https://$primaryHost/npm/@fawazahmed0/'
    'currency-api@$version/$_basePath',
  );

  /// Fallback (pages.dev) URL for [version].
  static Uri fallback(String version) =>
      Uri.parse('https://$version.$fallbackHostSuffix/$_basePath');

  /// The fallback twin of [uri], or `null` when [uri] is not a primary
  /// currency-API URL.
  static Uri? fallbackFor(Uri uri) {
    if (uri.host != primaryHost) return null;
    final version = _primaryVersionPattern.firstMatch(uri.path)?.group(1);
    if (version == null) return null;
    return fallback(version);
  }
}
