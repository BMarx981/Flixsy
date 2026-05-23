import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Punk` skin's buttons so
/// they breathe together with the spray-tag's hot-magenta glow without
/// spinning up a controller per button. Owned by `PunkRemoteSkin`; consumed
/// via [of].
class PunkPulseScope extends InheritedWidget {
  const PunkPulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PunkPulseScope>();
    assert(scope != null, 'No PunkPulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(PunkPulseScope old) => old.pulse != pulse;
}
