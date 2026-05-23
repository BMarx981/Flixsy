import 'dart:async';
import 'dart:math' as math;

// ignore: unnecessary_import — widgets.dart re-exports gesture types as
// meta-types only; we need direct access to PanGestureRecognizer /
// GestureDisposition for the eager-claim subclass.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/extensions/l10n_extensions.dart';

/// A large Flixsy-star control that combines a D-pad's directional taps, the
/// OK action, and a scroll-wheel spin into a single surface. The four points
/// are tap regions (N=up, S=down, E=right, W=left), the centre disc is OK,
/// and any rotational gesture fires haptic up/down ticks.
///
/// After the finger lifts, the star eases back to upright. The hit-test
/// compensates for the current rotation so taps always land on the arm the
/// user *sees* — not where it would have been in its un-rotated origin.
class SpinnableStarDpad extends StatefulWidget {
  const SpinnableStarDpad({
    super.key,
    required this.size,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onOk,
    required this.onScrollUp,
    required this.onScrollDown,
  });

  /// Side length of the (square) star in logical pixels.
  final double size;

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onOk;

  /// Fired once per clockwise tick of a spin gesture.
  final VoidCallback onScrollUp;

  /// Fired once per counter-clockwise tick of a spin gesture.
  final VoidCallback onScrollDown;

  /// Rotation between consecutive haptic ticks (~22° — iOS-picker feel).
  static const double tickAngle = 22 * math.pi / 180;

  /// Movement (px) past which a gesture is a spin rather than a tap.
  static const double tapSlop = 10;

  /// Idle time after the finger lifts before the star eases back upright.
  static const Duration resetDelay = Duration(milliseconds: 900);

  /// Duration of the ease-back-to-upright animation.
  static const Duration resetDuration = Duration(milliseconds: 450);

  @override
  State<SpinnableStarDpad> createState() => _SpinnableStarDpadState();
}

// Hit-test geometry as a fraction of [size] — resolution independent.
// Matches the geometry of the Flixsy logo's 4-point sparkle star, lifted
// from `MainRemoteSkin` (where the same regions also serve as keys).
const double _centerRadius = 0.166;
const double _armInnerRadius = 0.190;
const double _armOuterRadius = 0.440;
const double _guardDegrees = 9.0;

enum _Region { up, down, left, right, ok }

double _axisDegFor(_Region r) => switch (r) {
  _Region.up => -90,
  _Region.down => 90,
  _Region.left => 180,
  _Region.right => 0,
  _Region.ok => 0, // unused — centre is drawn as a disc, not a wedge
};

class _SpinnableStarDpadState extends State<SpinnableStarDpad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController = AnimationController(
    vsync: this,
    duration: SpinnableStarDpad.resetDuration,
  )..addListener(_onResetTick);

  _Region? _active;
  double _visualRotation = 0;
  double _resetFrom = 0;
  double _accumulatedDelta = 0;
  double? _spinLastAngle;
  Offset _panStart = Offset.zero;
  double _panDistanceSq = 0;
  bool _isSpinning = false;
  Timer? _resetTimer;

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  double _angleAt(Offset local) {
    final v = local - _center;
    return math.atan2(v.dy, v.dx);
  }

  double _wrap(double a) {
    var x = a % (2 * math.pi);
    if (x > math.pi) x -= 2 * math.pi;
    if (x <= -math.pi) x += 2 * math.pi;
    return x;
  }

  void _cancelReset() {
    _resetTimer?.cancel();
    _resetTimer = null;
    if (_resetController.isAnimating) _resetController.stop();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(SpinnableStarDpad.resetDelay, _startReset);
  }

  void _startReset() {
    _resetFrom = _wrap(_visualRotation);
    setState(() => _visualRotation = _resetFrom);
    _resetController
      ..value = 0
      ..forward();
  }

  void _onResetTick() {
    final t = Curves.easeOutCubic.transform(_resetController.value);
    setState(() => _visualRotation = _resetFrom * (1 - t));
  }

  bool _withinWedge(double deg, double axisDeg) {
    var delta = (deg - axisDeg).abs() % 360;
    if (delta > 180) delta = 360 - delta;
    return delta < 45 - _guardDegrees;
  }

  _Region? _hitTest(Offset position) {
    final side = widget.size;
    final v = position - _center;
    final r = v.distance / side;

    if (r <= _centerRadius) return _Region.ok;
    if (r < _armInnerRadius || r > _armOuterRadius) return null;

    // Subtract the current visual rotation so the user lands on the arm
    // they see, even mid-reset when the star isn't perfectly upright.
    final rawDeg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    final adjustedDeg = rawDeg - _visualRotation * 180 / math.pi;

    if (_withinWedge(adjustedDeg, 0)) return _Region.right;
    if (_withinWedge(adjustedDeg, 90)) return _Region.down;
    if (_withinWedge(adjustedDeg, 180)) return _Region.left;
    if (_withinWedge(adjustedDeg, -90)) return _Region.up;
    return null;
  }

  void _fire(_Region r) {
    HapticFeedback.selectionClick();
    switch (r) {
      case _Region.up:
        widget.onUp();
      case _Region.down:
        widget.onDown();
      case _Region.left:
        widget.onLeft();
      case _Region.right:
        widget.onRight();
      case _Region.ok:
        widget.onOk();
    }
  }

  void _onPanStart(DragStartDetails details) {
    _cancelReset();
    _panStart = details.localPosition;
    _panDistanceSq = 0;
    _isSpinning = false;
    _spinLastAngle = _angleAt(details.localPosition);
    _accumulatedDelta = 0;
    setState(() => _active = _hitTest(details.localPosition));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;
    _panDistanceSq = (local - _panStart).distanceSquared;

    final current = _angleAt(local);
    final last = _spinLastAngle;
    if (last == null) {
      _spinLastAngle = current;
      return;
    }
    var delta = current - last;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    _spinLastAngle = current;

    if (!_isSpinning &&
        _panDistanceSq >
            SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
      _isSpinning = true;
      // Crossed the spin threshold — drop the pressed-arm highlight; the
      // gesture is now a spin, not a tap on that arm.
      if (_active != null) _active = null;
    }

    _accumulatedDelta += delta;
    setState(() => _visualRotation += delta);

    while (_accumulatedDelta >= SpinnableStarDpad.tickAngle) {
      _accumulatedDelta -= SpinnableStarDpad.tickAngle;
      HapticFeedback.selectionClick();
      widget.onScrollUp();
    }
    while (_accumulatedDelta <= -SpinnableStarDpad.tickAngle) {
      _accumulatedDelta += SpinnableStarDpad.tickAngle;
      HapticFeedback.selectionClick();
      widget.onScrollDown();
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isSpinning) {
      final region = _active;
      if (region != null) _fire(region);
    }
    setState(() => _active = null);
    _spinLastAngle = null;
    _isSpinning = false;
    _scheduleReset();
  }

  void _onPanCancel() {
    if (_active != null) setState(() => _active = null);
    _spinLastAngle = null;
    _isSpinning = false;
    _scheduleReset();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          _EagerPanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                _EagerPanGestureRecognizer
              >(() => _EagerPanGestureRecognizer(), (instance) {
                instance.onStart = _onPanStart;
                instance.onUpdate = _onPanUpdate;
                instance.onEnd = _onPanEnd;
                instance.onCancel = _onPanCancel;
              }),
        },
        child: AnimatedScale(
          scale: _active == null ? 1.0 : 0.97,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: Transform.rotate(
            angle: _visualRotation,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  'assets/images/flixsy_logo.svg',
                  semanticsLabel: context.l10n.mainRemoteSemanticLabel,
                ),
                CustomPaint(
                  painter: _HighlightPainter(
                    region: _active,
                    color: const Color(0x4DFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A [PanGestureRecognizer] that wins the gesture arena the instant a finger
/// touches it — so an ancestor `PageView` (the skin-picker carousel) can't
/// steal the gesture mid-spin.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// Paints a translucent overlay over the region currently pressed.
class _HighlightPainter extends CustomPainter {
  const _HighlightPainter({required this.region, required this.color});

  final _Region? region;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final region = this.region;
    if (region == null) return;

    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;

    if (region == _Region.ok) {
      canvas.drawCircle(center, _centerRadius * side, paint);
      return;
    }

    final axisDeg = _axisDegFor(region);
    const halfWedge = 45 - _guardDegrees;
    final startRad = (axisDeg - halfWedge) * math.pi / 180;
    final sweepRad = 2 * halfWedge * math.pi / 180;
    final innerRect = Rect.fromCircle(
      center: center,
      radius: _armInnerRadius * side,
    );
    final outerRect = Rect.fromCircle(
      center: center,
      radius: _armOuterRadius * side,
    );

    // Donut sector: out along the wedge, then back along the inner radius.
    final path = Path()
      ..arcTo(outerRect, startRad, sweepRad, true)
      ..arcTo(innerRect, startRad + sweepRad, -sweepRad, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) =>
      oldDelegate.region != region || oldDelegate.color != color;
}
