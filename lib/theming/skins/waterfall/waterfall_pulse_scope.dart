import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to descendant buttons so the
/// `Waterfall` skin doesn't spin up a controller per button. Owned by
/// [WaterfallRemoteSkin]; consumed by its buttons via [of].
class WaterfallPulseScope extends InheritedWidget {
  const WaterfallPulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WaterfallPulseScope>();
    assert(scope != null, 'No WaterfallPulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(WaterfallPulseScope old) => old.pulse != pulse;
}
