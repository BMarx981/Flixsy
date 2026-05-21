import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Cityscape` skin's buttons
/// so they breathe together with the city's window glow without spinning up a
/// controller per button. Owned by `CityscapeRemoteSkin`; consumed via [of].
class CityscapePulseScope extends InheritedWidget {
  const CityscapePulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CityscapePulseScope>();
    assert(scope != null, 'No CityscapePulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(CityscapePulseScope old) => old.pulse != pulse;
}
