import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Ocean` skin's buttons.
/// Owned by [OceanRemoteSkin]; consumed by its buttons via [of].
class OceanPulseScope extends InheritedWidget {
  const OceanPulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OceanPulseScope>();
    assert(scope != null, 'No OceanPulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(OceanPulseScope old) => old.pulse != pulse;
}
