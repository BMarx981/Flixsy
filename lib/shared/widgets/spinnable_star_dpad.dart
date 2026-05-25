import 'dart:async';
import 'dart:math' as math;

// ignore: unnecessary_import — widgets.dart re-exports gesture types as
// meta-types only; we need direct access to PanGestureRecognizer /
// GestureDisposition for the eager-claim subclass.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/theming/skin_tokens.dart';
import 'package:flixsy/shared/widgets/flixsy_logo.dart';

/// A D-pad control that fuses four directional tap regions, an OK tap, and a
/// scroll-wheel spin into one surface.
///
/// The gesture mode is locked at touch-down by the start position:
///   * inside the centre disc → spin / OK (a still touch fires OK, a drag
///     tumbles the wheel and emits scroll ticks along the drag's dominant
///     axis: vertical drag → up/down, horizontal drag → left/right)
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
    required this.onScrollLeft,
    required this.onScrollRight,
  });

  /// Side length of the (square) D-pad in logical pixels.
  final double size;

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onOk;

  /// Fired once per tick of an upward scroll-wheel drag.
  final VoidCallback onScrollUp;

  /// Fired once per tick of a downward scroll-wheel drag.
  final VoidCallback onScrollDown;

  /// Fired once per tick of a leftward scroll-wheel drag.
  final VoidCallback onScrollLeft;

  /// Fired once per tick of a rightward scroll-wheel drag.
  final VoidCallback onScrollRight;

  /// Rotation between consecutive haptic ticks (~22° — iOS-picker feel).
  /// Applied to the visual tumble; one tick of drag = this much rotation.
  static const double tickAngle = 22 * math.pi / 180;

  /// Finger travel along the locked axis between consecutive haptic ticks.
  /// Tuned so a comfortable thumb-flick across the disc fires a few ticks.
  static const double pixelsPerTick = 32;

  /// Movement (px) past which a centre touch starts spinning rather than
  /// counting as an OK tap. Also the threshold at which the gesture's
  /// dominant axis is locked.
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

enum _SpinAxis { none, vertical, horizontal }

double _axisDegFor(_Region r) => switch (r) {
  _Region.up => -90,
  _Region.down => 90,
  _Region.left => 180,
  _Region.right => 0,
  _Region.ok => 0, // unused — centre is drawn as a disc, not a wedge
};

class _SpinnableStarDpadState extends State<SpinnableStarDpad>
    with TickerProviderStateMixin {
  late final AnimationController _resetController;
  // Slow, continuous controller that drives an ambient rock when the wheel
  // is otherwise still. Hints to the user that the disc rotates.
  late final AnimationController _idleController;

  /// Period of one full back-and-forth rock cycle.
  static const Duration _idleRockPeriod = Duration(milliseconds: 3600);

  /// Peak tilt of the ambient rock, in radians (~5°). Small enough to read
  /// as a hint, not as motion the user has to track.
  static const double _idleRockAmplitude = 15 * math.pi / 180;

  _Region? _active;
  _GestureMode _mode = _GestureMode.idle;
  _SpinAxis _axis = _SpinAxis.none;
  // Signed pixel offset of the current finger position relative to where the
  // axis lock latched, measured along the locked axis. Drives both the
  // visual tumble (radians = pixels * tickAngle / pixelsPerTick) and the
  // tick emitter.
  double _axisPixels = 0;
  // Pixel value at which the last haptic tick fired. Ticks fire whenever
  // `_axisPixels` crosses another `pixelsPerTick` increment past this anchor.
  double _lastTickPixels = 0;
  Offset _panStart = Offset.zero;
  Offset _axisLockOrigin = Offset.zero;
  bool _hasFiredTick = false;
  Timer? _resetTimer;

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: SpinnableStarDpad.resetDuration,
    )..addListener(_onResetTick);
    _idleController =
        AnimationController(vsync: this, duration: _idleRockPeriod)
          ..addListener(_onIdleTick)
          ..repeat();
  }

  // Repaint whenever the idle rock advances, but only while the wheel is
  // actually idle — during a real spin or reset, the gesture-driven rotation
  // is the source of truth and the rock is suppressed in `_tumbleMatrix`.
  void _onIdleTick() {
    if (_axisPixels == 0 && !_isResetting && _mode != _GestureMode.spin) {
      setState(() {});
    }
  }

  // Current visual rotation, in radians, derived from `_axisPixels` so the
  // wheel and the tick emitter share a single source of truth. Used only
  // while a spin is in progress; the reset animation uses `_resetVisual`.
  double get _visualRotation =>
      _axisPixels *
      SpinnableStarDpad.tickAngle /
      SpinnableStarDpad.pixelsPerTick;

  // Eased rotation written by the reset animation. Independent of
  // `_axisPixels` so we can fade out a tumble without snapping the source.
  double _resetVisual = 0;
  bool _isResetting = false;

  void _cancelReset() {
    _resetTimer?.cancel();
    _resetTimer = null;
    if (_resetController.isAnimating) _resetController.stop();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(SpinnableStarDpad.resetDelay, _startReset);
  }

  double _resetFrom = 0;

  void _startReset() {
    // Freeze the live spin value, hand it to the reset animation, and clear
    // the source so a new pan starts from zero.
    _resetFrom = _visualRotation;
    _axisPixels = 0;
    _lastTickPixels = 0;
    _isResetting = true;
    _resetVisual = _resetFrom;
    setState(() {});
    _resetController
      ..value = 0
      ..forward();
  }

  void _onResetTick() {
    final t = Curves.easeOutCubic.transform(_resetController.value);
    setState(() {
      _resetVisual = _resetFrom * (1 - t);
      if (_resetController.isCompleted) {
        _resetVisual = 0;
        _isResetting = false;
      }
    });
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
    _axisLockOrigin = details.localPosition;
    _hasFiredTick = false;
    _axis = _SpinAxis.none;
    _axisPixels = 0;
    _lastTickPixels = 0;
    // Reset visual is also cleared so we don't blend a half-finished ease
    // into a fresh tumble.
    _resetVisual = 0;
    _isResetting = false;

    final region = _hitTest(details.localPosition);
    if (region == null) {
      _mode = _GestureMode.cancelled;
      setState(() => _active = null);
      return;
    }
    if (region == _Region.ok) {
      _mode = _GestureMode.spin;
    } else {
      _mode = _GestureMode.tap;
    }
    setState(() => _active = region);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final local = details.localPosition;

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
    // Lock the spin axis at first significant motion, picking whichever
    // direction the user moved farther in. After lock, only motion along
    // that axis contributes — sideways drift is ignored, so the wheel feels
    // like a track instead of a free puck.
    if (_axis == _SpinAxis.none) {
      final fromStart = local - _panStart;
      if (fromStart.distanceSquared <
          SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
        return;
      }
      _axis = fromStart.dx.abs() >= fromStart.dy.abs()
          ? _SpinAxis.horizontal
          : _SpinAxis.vertical;
      // Anchor pixel travel to where the lock latched, not to the touch-down
      // point — otherwise the first tick fires after only a couple of pixels
      // of post-lock motion (the slop itself counts toward the tick).
      _axisLockOrigin = local;
      _axisPixels = 0;
      _lastTickPixels = 0;
      _hasFiredTick = true;
      if (_active != null) _active = null;
    }

    final fromLock = local - _axisLockOrigin;
    _axisPixels = _axis == _SpinAxis.vertical ? fromLock.dy : fromLock.dx;
    setState(() {});

    // Emit one tick for every `pixelsPerTick` of travel away from the last
    // anchor, in either direction. Positive vertical = down-drag = onScrollDown;
    // positive horizontal = right-drag = onScrollRight.
    while (_axisPixels - _lastTickPixels >= SpinnableStarDpad.pixelsPerTick) {
      _lastTickPixels += SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      if (_axis == _SpinAxis.vertical) {
        widget.onScrollDown();
      } else {
        widget.onScrollRight();
      }
    }
    while (_lastTickPixels - _axisPixels >= SpinnableStarDpad.pixelsPerTick) {
      _lastTickPixels -= SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      if (_axis == _SpinAxis.vertical) {
        widget.onScrollUp();
      } else {
        widget.onScrollLeft();
      }
    }
  }

  void _onPanEnd(DragEndDetails _) {
    switch (_mode) {
      case _GestureMode.spin:
        if (!_hasFiredTick && _active == _Region.ok) {
          // Centre touch with no real motion → OK tap.
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
    _hasFiredTick = false;
    _mode = _GestureMode.idle;
  }

  void _onPanCancel() {
    if (_mode == _GestureMode.spin) _scheduleReset();
    if (_active != null) setState(() => _active = null);
    _hasFiredTick = false;
    _mode = _GestureMode.idle;
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _resetController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  // The 3D tumble matrix: perspective + a rotation around whichever axis the
  // current spin is locked to. While resetting, we use the eased value and
  // the last-active axis so the wheel rolls back along the same path it
  // came in on (a vertical drag eases back through X-rotation, not Z).
  Matrix4 _tumbleMatrix() {
    final angle = _isResetting ? _resetVisual : _visualRotation;
    final m = Matrix4.identity()..setEntry(3, 2, 0.001);
    switch (_axis) {
      case _SpinAxis.vertical:
        m.rotateX(angle);
      case _SpinAxis.horizontal:
        m.rotateY(angle);
      case _SpinAxis.none:
        // No active spin and nothing to ease back — apply the ambient rock
        // so the wheel reads as scrollable even at rest. Suppressed the
        // moment a real spin or reset is in flight.
        final rock =
            math.sin(_idleController.value * 2 * math.pi) * _idleRockAmplitude;
        m.rotateX(rock);
    }
    return m;
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
              // Centre spin disc — the only thing that rotates. The tumble
              // is 3D: a vertical drag rolls the wheel forward/back around
              // the X axis; a horizontal drag spins it around the Y axis.
              // A perspective entry on the matrix gives the rotation depth so
              // it reads as a barrel turning instead of a squashed ellipse.
              Center(
                child: AnimatedScale(
                  scale: _active == _Region.ok ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: _tumbleMatrix(),
                    child: SizedBox.square(
                      dimension: discDiameter,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FlixsyLogo(size: discDiameter, discColor: discColor),
                          // Dome shading lives inside the tumble Transform so
                          // it rotates with the surface during a spin (selling
                          // it as a textured ball rolling) and returns to the
                          // upright dome look once the reset animation eases
                          // the wheel back to identity.
                          IgnorePointer(
                            child: CustomPaint(
                              painter: const _DomeShadingPainter(),
                            ),
                          ),
                        ],
                      ),
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

// Radius of the pink disc fill inside the Flixsy SVG, expressed as a
// fraction of the full SVG side. The SVG draws the disc at r=356 in a
// 1024-unit viewbox.
const double _logoDiscRadiusFraction = 356.0 / 1024.0;

// Radius of the dark outer ring in the same SVG (r=424 in 1024 units).
// The dome shading is clipped to this so highlight/shadow can softly
// reach the ring without spilling onto the surrounding D-pad.
const double _logoRingRadiusFraction = 424.0 / 1024.0;

/// Paints a fixed (non-rotating) dome shading on top of the spinning disc:
/// a top-side highlight, a bottom shadow, and a thin specular arc. Combined
/// with the underlying [Transform] tumble, this makes the disc read as a
/// 3D sphere instead of a flat circle.
class _DomeShadingPainter extends CustomPainter {
  const _DomeShadingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = side * _logoRingRadiusFraction;
    final discRadius = side * _logoDiscRadiusFraction;

    // Clip everything to the outer ring so shading never spills past the
    // logo into the surrounding D-pad sectors.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: ringRadius)),
    );

    // 1. Bottom shadow — a radial gradient anchored below the disc, darker
    //    at the bottom edge, fading out toward the centre.
    final shadowRect = Rect.fromCircle(
      center: center + Offset(0, discRadius * 0.55),
      radius: discRadius * 1.05,
    );
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.32),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(shadowRect);
    canvas.drawCircle(center, discRadius, shadowPaint);

    // 2. Top highlight — radial gradient anchored above the disc, brightest
    //    at the top edge, fading out toward the centre. Gives the dome its
    //    "lit from above" feel.
    final highlightRect = Rect.fromCircle(
      center: center + Offset(0, -discRadius * 0.55),
      radius: discRadius * 1.05,
    );
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(highlightRect);
    canvas.drawCircle(center, discRadius, highlightPaint);

    // 3. Specular arc — a thin crescent of brighter white near the top,
    //    selling the glossy-sphere illusion. Drawn by stroking an oval
    //    that's slightly smaller than the disc and offset upward.
    final specRect = Rect.fromCenter(
      center: center + Offset(0, -discRadius * 0.18),
      width: discRadius * 1.55,
      height: discRadius * 1.55,
    );
    final specPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = discRadius * 0.06
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55],
      ).createShader(specRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, discRadius * 0.04);
    // Sweep across the upper arc only (≈ 200° → 340°, going clockwise).
    const startRad = 200 * math.pi / 180;
    const sweepRad = 140 * math.pi / 180;
    canvas.drawArc(specRect, startRad, sweepRad, false, specPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DomeShadingPainter oldDelegate) => false;
}
