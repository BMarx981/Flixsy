import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Honkytonk` skin's buttons
/// so they breathe together with the neon sign and bulb glow without spinning
/// up a controller per button. Owned by `HonkytonkRemoteSkin`; consumed via
/// [of].
class HonkytonkPulseScope extends InheritedWidget {
  const HonkytonkPulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HonkytonkPulseScope>();
    assert(scope != null, 'No HonkytonkPulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(HonkytonkPulseScope old) => old.pulse != pulse;
}
