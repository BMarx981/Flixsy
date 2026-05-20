import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Campfire` skin's buttons
/// so they breathe together with the fire's flicker without spinning up a
/// controller per button. Owned by `CampfireRemoteSkin`; consumed via [of].
class CampfirePulseScope extends InheritedWidget {
  const CampfirePulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CampfirePulseScope>();
    assert(scope != null, 'No CampfirePulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(CampfirePulseScope old) => old.pulse != pulse;
}
