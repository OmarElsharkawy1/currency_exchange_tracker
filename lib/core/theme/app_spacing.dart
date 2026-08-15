/// The app's spacing scale.
///
/// Screen-level insets live here so a header and the content under it line up
/// by construction rather than by two call sites happening to type the same
/// number.
abstract final class AppSpacing {
  /// Horizontal inset of every screen's content.
  ///
  /// The rates list rows, the detail header and the chart all use it, which is
  /// what puts the chart's first plotted point on the header's leading edge.
  static const double pageHorizontal = 16;

  /// Vertical breathing room above a screen's first element.
  static const double pageTop = 16;

  /// Vertical inset below a screen's last element.
  static const double pageBottom = 24;

  /// Gap between a heading and the content it introduces.
  static const double sectionGap = 8;
}
