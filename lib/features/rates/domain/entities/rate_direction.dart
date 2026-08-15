/// Which way the Egyptian pound moved between two quotes of the same
/// currency.
///
/// The naming is deliberately about the pound rather than about the chart
/// line, because the two move in opposite directions: a *rising* display rate
/// means a foreign unit costs more pounds, which is the pound getting
/// *weaker*.
enum RateDirection {
  /// A foreign unit costs fewer pounds than before: the pound gained value.
  egpStrengthening,

  /// A foreign unit costs more pounds than before: the pound lost value.
  egpWeakening,

  /// The rate did not move.
  flat,
}
