import 'dart:async';
import 'dart:math' as math;

// ignore: unnecessary_import — widgets.dart re-exports gesture types as
// meta-types only; we need direct access to PanGestureRecognizer /
// GestureDisposition for the eager-claim subclass.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/l10n_extensions.dart';
import '../../theming/skin_tokens.dart';
import 'flixsy_logo.dart';

/// A D-pad control that fuses four directional tap regions, an OK tap, and a
/// scroll-wheel spin into one surface.
///
/// The gesture mode is locked at touch-down by the start position:
///   * inside the centre disc → spin / OK (a still touch fires OK, a circular
///     motion fires up/down ticks)
///   * inside an arm sector  → tap-only (no spin is possible; dragging off
///     the arm cancels the press)
///
/// This separation is what stops a tight scroll motion from accidentally
/// counting as an arm tap — arms only react to taps that *start* on them.
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

  /// Side length of the (square) D-pad in logical pixels.
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

  /// Movement (px) past which a centre touch starts spinning rather than
  /// counting as an OK tap.
  static const double tapSlop = 10;

  /// Idle time after the finger lifts before the wheel eases back upright.
  static const Duration resetDelay = Duration(milliseconds: 900);

  /// Duration of the ease-back-to-upright animation.
  static const Duration resetDuration = Duration(milliseconds: 450);

  @override
  State<SpinnableStarDpad> createState() => _SpinnableStarDpadState();
}

// Hit-test geometry as a fraction of [size] — resolution independent.
// The spin hit area fully encloses the visible logo (including its dark
// outer ring), so the arm sector never visually overlaps the wheel. Arms
// abut the logo's outer edge with no gap and extend out to the widget edge.
//
// Logo outer-ring edge sits at `_discRenderFraction * 0.4219` ≈ 0.304 of
// the widget, so `_centerRadius = 0.31` gives a hair of clearance.
const double _centerRadius = 0.31;
const double _armInnerRadius = 0.31;
const double _armOuterRadius = 0.50;
const double _guardDegrees = 5.0;

// Side length the Flixsy SVG is rendered at, as a fraction of widget side.
// Chosen so the logo's outermost feature (the dark outer ring at 42.19% of
// the SVG) lands just inside `_centerRadius` — wheel visuals stay inside
// the spin hit zone.
const double _discRenderFraction = 0.72;

enum _Region { up, down, left, right, ok }

enum _GestureMode { idle, spin, tap, cancelled }

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
  _GestureMode _mode = _GestureMode.idle;
  double _visualRotation = 0;
  double _resetFrom = 0;
  double _accumulatedDelta = 0;
  double? _spinLastAngle;
  Offset _panStart = Offset.zero;
  double _panDistanceSq = 0;
  bool _hasFiredTick = false;
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

    // No rotation compensation needed: only the centre disc rotates, the
    // arm chevrons are drawn statically.
    final deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (_withinWedge(deg, 0)) return _Region.right;
    if (_withinWedge(deg, 90)) return _Region.down;
    if (_withinWedge(deg, 180)) return _Region.left;
    if (_withinWedge(deg, -90)) return _Region.up;
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
    _hasFiredTick = false;
    _accumulatedDelta = 0;
    _spinLastAngle = null;

    final region = _hitTest(details.localPosition);
    if (region == null) {
      _mode = _GestureMode.cancelled;
      setState(() => _active = null);
      return;
    }
    if (region == _Region.ok) {
      _mode = _GestureMode.spin;
      _spinLastAngle = _angleAt(details.localPosition);
    } else {
      _mode = _GestureMode.tap;
    }
    setState(() => _active = region);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;
    _panDistanceSq = (local - _panStart).distanceSquared;

    switch (_mode) {
      case _GestureMode.spin:
        _updateSpin(local);
      case _GestureMode.tap:
        // An arm press is cancelled the moment the finger drifts off the
        // arm sector — same as a Material InkWell that you drag off of.
        final stillOnArm = _hitTest(local) == _active;
        if (!stillOnArm) {
          _mode = _GestureMode.cancelled;
          setState(() => _active = null);
        }
      case _GestureMode.cancelled:
      case _GestureMode.idle:
        break;
    }
  }

  void _updateSpin(Offset local) {
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

    // Once the user has clearly moved (linear distance or any tick fired),
    // suppress the OK fallback so a circular flick doesn't fire OK on release.
    if (!_hasFiredTick &&
        _panDistanceSq >
            SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
      _hasFiredTick = true;
      if (_active != null) _active = null;
    }

    _accumulatedDelta += delta;
    setState(() => _visualRotation += delta);

    while (_accumulatedDelta >= SpinnableStarDpad.tickAngle) {
      _accumulatedDelta -= SpinnableStarDpad.tickAngle;
      HapticFeedback.selectionClick();
      _hasFiredTick = true;
      if (_active != null) _active = null;
      widget.onScrollUp();
    }
    while (_accumulatedDelta <= -SpinnableStarDpad.tickAngle) {
      _accumulatedDelta += SpinnableStarDpad.tickAngle;
      HapticFeedback.selectionClick();
      _hasFiredTick = true;
      if (_active != null) _active = null;
      widget.onScrollDown();
    }
  }

  void _onPanEnd(DragEndDetails _) {
    switch (_mode) {
      case _GestureMode.spin:
        // Centre touch with no real motion → OK tap.
        if (!_hasFiredTick && _active == _Region.ok) {
          _fire(_Region.ok);
        }
        _scheduleReset();
      case _GestureMode.tap:
        final region = _active;
        if (region != null) _fire(region);
      case _GestureMode.cancelled:
      case _GestureMode.idle:
        break;
    }
    setState(() => _active = null);
    _spinLastAngle = null;
    _hasFiredTick = false;
    _mode = _GestureMode.idle;
  }

  void _onPanCancel() {
    if (_mode == _GestureMode.spin) _scheduleReset();
    if (_active != null) setState(() => _active = null);
    _spinLastAngle = null;
    _hasFiredTick = false;
    _mode = _GestureMode.idle;
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outline.withValues(alpha: 0.35);
    final highlightColor = scheme.primary.withValues(alpha: 0.20);
    final chevronColor = scheme.onSurface;
    final discColor = SkinTokens.of(context).accent;
    final discDiameter = s * _discRenderFraction;
    final chevronSize = s * 0.12;
    // Place chevrons at the midpoint of the arm ring. Alignment uses unit
    // half-widths, so radius r as a fraction of `s` maps to 2r.
    const chevronAlign = (_armInnerRadius + _armOuterRadius);

    return SizedBox.square(
      dimension: s,
      child: Semantics(
        label: context.l10n.mainRemoteSemanticLabel,
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Borders + active-region highlight (under the icons so the
              // chevrons / logo stay crisp on top).
              CustomPaint(
                painter: _DpadPainter(
                  borderColor: borderColor,
                  highlightColor: highlightColor,
                  active: _active,
                ),
              ),
              // Four static chevron icons — these don't rotate, so the
              // user can always tap the arrow they see.
              Align(
                alignment: Alignment(0, -chevronAlign),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ),
              Align(
                alignment: Alignment(0, chevronAlign),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ),
              Align(
                alignment: Alignment(-chevronAlign, 0),
                child: Icon(
                  Icons.keyboard_arrow_left,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ),
              Align(
                alignment: Alignment(chevronAlign, 0),
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ),
              // Centre spin disc — the only thing that rotates.
              Center(
                child: AnimatedScale(
                  scale: _active == _Region.ok ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Transform.rotate(
                    angle: _visualRotation,
                    child: FlixsyLogo(
                      size: discDiameter,
                      discColor: discColor,
                    ),
                  ),
                ),
              ),
            ],
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

/// Paints the thin borders around the spin disc and between the four arm
/// sectors, plus the press-highlight fill for the active region.
class _DpadPainter extends CustomPainter {
  const _DpadPainter({
    required this.borderColor,
    required this.highlightColor,
    required this.active,
  });

  final Color borderColor;
  final Color highlightColor;
  final _Region? active;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final r0 = _centerRadius * side;
    final rIn = _armInnerRadius * side;
    final rOut = _armOuterRadius * side;

    // Highlight first, under the lines.
    if (active != null) {
      final fill = Paint()..color = highlightColor;
      if (active == _Region.ok) {
        canvas.drawCircle(center, r0, fill);
      } else {
        final axisDeg = _axisDegFor(active!);
        const halfWedge = 45 - _guardDegrees;
        final startRad = (axisDeg - halfWedge) * math.pi / 180;
        final sweepRad = 2 * halfWedge * math.pi / 180;
        final inner = Rect.fromCircle(center: center, radius: rIn);
        final outer = Rect.fromCircle(center: center, radius: rOut);
        final path = Path()
          ..arcTo(outer, startRad, sweepRad, true)
          ..arcTo(inner, startRad + sweepRad, -sweepRad, false)
          ..close();
        canvas.drawPath(path, fill);
      }
    }

    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer arm boundary only — the Flixsy logo's own ring already serves
    // as the spin-disc border, so drawing another stroke at `_centerRadius`
    // would look like a doubled outline.
    canvas.drawCircle(center, rOut, stroke);

    // Four diagonal dividers between arms, from inner ring to outer ring.
    for (final degrees in const [45.0, 135.0, 225.0, 315.0]) {
      final rad = degrees * math.pi / 180;
      final unit = Offset(math.cos(rad), math.sin(rad));
      canvas.drawLine(center + unit * rIn, center + unit * rOut, stroke);
    }
  }

  @override
  bool shouldRepaint(_DpadPainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.highlightColor != highlightColor;
}
