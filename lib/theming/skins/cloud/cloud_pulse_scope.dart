import 'package:flutter/widgets.dart';

/// Exposes a single shared pulse animation to the `Cloud` skin's buttons so
/// the skin doesn't spin up a controller per button. Owned by
/// [CloudRemoteSkin]; consumed by its buttons via [of].
class CloudPulseScope extends InheritedWidget {
  const CloudPulseScope({
    super.key,
    required this.pulse,
    required super.child,
  });

  final Animation<double> pulse;

  static Animation<double> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CloudPulseScope>();
    assert(scope != null, 'No CloudPulseScope above this widget.');
    return scope!.pulse;
  }

  @override
  bool updateShouldNotify(CloudPulseScope old) => old.pulse != pulse;
}
