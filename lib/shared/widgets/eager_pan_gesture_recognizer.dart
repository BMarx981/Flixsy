// ignore: unnecessary_import — widgets.dart re-exports gesture types as
// meta-types only; we need direct access to PanGestureRecognizer /
// GestureDisposition for the eager-claim subclass.
import 'package:flutter/gestures.dart';

/// A [PanGestureRecognizer] that wins the local gesture arena the instant a
/// finger touches it, instead of waiting for `kTouchSlop` movement.
///
/// Without this, any ancestor scrollable — `PageView` (the skin-picker
/// carousel), `SingleChildScrollView` (the home-screen scroll wrap), or
/// anything else with a drag recognizer — can steal the gesture mid-spin as
/// soon as the user's motion lines up with its drag axis. The remote D-pads
/// then "stop spinning after a little while."
///
/// Because the eager claim is scoped to the widget that mounts this
/// recognizer, taps outside the D-pad's surface never enter its arena and
/// parent scrollables continue to work normally everywhere else.
class EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
