import 'package:currency_exchange_tracker/core/failures/failure.dart';

/// The outcome of an operation that can fail: exactly one side is non-null.
///
/// Used instead of throwing across layer boundaries, so callers cannot forget
/// to handle the failure path.
typedef Result<T> = (T? value, Failure? failure);

/// A successful [Result] carrying [value].
Result<T> success<T>(T value) => (value, null);

/// A failed [Result] carrying [failure].
Result<T> failed<T>(Failure failure) => (null, failure);
