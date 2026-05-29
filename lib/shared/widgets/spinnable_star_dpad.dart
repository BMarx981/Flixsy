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

// Which half of the disc a clip should keep visible. Used by [_HalfClipper]
// to carve the full-disc layer into the two halves a rolodex flip pivots
// between.
enum _HalfSide { top, bottom, left, right }

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
  /// Time the user must stop interacting before the rolodex begins fading
  /// back to the upright Flixsy icon.
  static const Duration _idleFadeDelay = Duration(seconds: 3);

  /// Duration of the fade from current pose back to the upright icon.
  static const Duration _idleFadeDuration = Duration(milliseconds: 3500);

  // Controller driving the opacity fade from the rolodex (current frozen
  // pose) down to the static FlixsyLogo underlay. value 0 = rolodex fully
  // visible, 1 = fully faded out and the underlay shows through.
  late final AnimationController _fadeController;
  // Pending fire of the 3-second idle delay. Cancelled the moment the
  // user touches the disc again.
  Timer? _idleFadeTimer;

  _Region? _active;
  _GestureMode _mode = _GestureMode.idle;
  // The wheel spins like a ball: vertical and horizontal ticks fire
  // independently, so a diagonal drag emits both at once and the user can
  // curve from down → right without lifting the finger.
  //
  // `_visualAxis` and `_visualPixels` drive the rolodex pose. The visual
  // axle follows whichever direction the finger moved most in the latest
  // frame; when the axle flips, `_visualPixels` resets so the new axis
  // starts upright. Persists across gestures so the disc freezes on lift.
  _SpinAxis _visualAxis = _SpinAxis.none;
  double _visualPixels = 0;
  // Per-axis travel within the *current* drag, anchored at the moment the
  // gesture committed to a spin. Drives tick emission independently of
  // the visual — vertical ticks keep firing even while the visual axle
  // is pivoted to horizontal.
  double _vTravel = 0;
  double _hTravel = 0;
  double _vLastTick = 0;
  double _hLastTick = 0;
  Offset _panStart = Offset.zero;
  Offset _prevLocal = Offset.zero;
  bool _hasFiredTick = false;
  // True once the current drag has crossed the slop threshold and is
  // definitively a spin (not an OK tap). Until then no ticks fire and
  // the disc holds its previous pose.
  bool _spinCommitted = false;

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: _idleFadeDuration)
          ..addListener(() => setState(() {}))
          ..addStatusListener(_onFadeStatus);
  }

  // When the fade finishes, the rolodex is fully transparent over the
  // static underlay — collapse its pose so the next touch starts from
  // upright instead of resuming wherever the finger lifted.
  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _visualPixels = 0;
        _visualAxis = _SpinAxis.none;
      });
    }
  }

  // Arm the 3-second idle countdown. No-op if the disc is already at
  // rest (nothing to fade away from).
  void _scheduleIdleFade() {
    _idleFadeTimer?.cancel();
    if (_visualPixels == 0 && _visualAxis == _SpinAxis.none) return;
    _idleFadeTimer = Timer(_idleFadeDelay, () {
      if (!mounted) return;
      if (_mode == _GestureMode.idle && _visualPixels != 0) {
        _fadeController.forward(from: 0);
      }
    });
  }

  // Any touch cancels both the pending timer and an in-flight fade —
  // mid-fade the rolodex snaps back to full opacity over its current
  // pose, so the user can pick up where they left off.
  void _cancelIdleFade() {
    _idleFadeTimer?.cancel();
    if (_fadeController.value != 0) {
      _fadeController.value = 0;
    }
  }

  // Current visual rotation, in radians, derived from `_visualPixels`.
  double get _visualRotation =>
      _visualPixels *
      SpinnableStarDpad.tickAngle /
      SpinnableStarDpad.pixelsPerTick;

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
    _cancelIdleFade();
    _panStart = details.localPosition;
    _prevLocal = details.localPosition;
    _hasFiredTick = false;
    _spinCommitted = false;
    // Tick travel resets each gesture so a fresh drag ticks from 0. The
    // visual axis/pixels are NOT reset — the disc keeps whatever pose
    // the last gesture left it in until this drag's motion overrides it.
    _vTravel = 0;
    _hTravel = 0;
    _vLastTick = 0;
    _hLastTick = 0;

    final region = _hitTest(details.localPosition);
    if (region == null) {
      _mode = _GestureMode.cancelled;
      setState(() => _active = null);
      return;
    }
    if (region == _Region.ok) {
      // Centre touch: don't highlight or scale yet — we don't know whether
      // this is an OK tap or the start of a spin, and any visible press
      // feedback for the first few pixels of slop reads as a spurious
      // splash. We commit to OK feedback only on lift (in `_onPanEnd`) if
      // no spin actually started.
      _mode = _GestureMode.spin;
      setState(() => _active = null);
    } else {
      _mode = _GestureMode.tap;
      setState(() => _active = region);
    }
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
    // Hold OK-tap candidacy until the finger crosses tapSlop. Before that,
    // accumulate nothing — a still touch stays an OK tap.
    if (!_spinCommitted) {
      final fromStart = local - _panStart;
      if (fromStart.distanceSquared <
          SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
        return;
      }
      _spinCommitted = true;
      _hasFiredTick = true;
      _prevLocal = local;
      if (_active != null) setState(() => _active = null);
      return;
    }

    final delta = local - _prevLocal;
    _prevLocal = local;

    // Both axes accumulate independently — a diagonal drag emits ticks on
    // both at once. Positive vertical = down-drag = onScrollDown; positive
    // horizontal = right-drag = onScrollRight.
    _vTravel += delta.dy;
    _hTravel += delta.dx;

    while (_vTravel - _vLastTick >= SpinnableStarDpad.pixelsPerTick) {
      _vLastTick += SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onScrollDown();
    }
    while (_vLastTick - _vTravel >= SpinnableStarDpad.pixelsPerTick) {
      _vLastTick -= SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onScrollUp();
    }
    while (_hTravel - _hLastTick >= SpinnableStarDpad.pixelsPerTick) {
      _hLastTick += SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onScrollRight();
    }
    while (_hLastTick - _hTravel >= SpinnableStarDpad.pixelsPerTick) {
      _hLastTick -= SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onScrollLeft();
    }

    // Visual axle = whichever axis the finger moved more in this frame.
    // Sub-pixel jitter doesn't flip the axle (it would otherwise strobe).
    // When the axle does flip, the new axis starts upright — same snap
    // the previous code did on cross-axis lift+drag.
    final adx = delta.dx.abs();
    final ady = delta.dy.abs();
    if (adx >= 0.5 || ady >= 0.5) {
      final newAxis = ady >= adx ? _SpinAxis.vertical : _SpinAxis.horizontal;
      if (newAxis != _visualAxis) {
        _visualAxis = newAxis;
        _visualPixels = 0;
      }
      _visualPixels += newAxis == _SpinAxis.vertical ? delta.dy : delta.dx;
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    switch (_mode) {
      case _GestureMode.spin:
        if (!_hasFiredTick) {
          // Centre touch that never crossed the slop → OK tap. We held off
          // any press feedback during the gesture (see `_onPanStart`) so
          // confirm the press now with a brief highlight + scale before
          // firing the action.
          setState(() => _active = _Region.ok);
          _fire(_Region.ok);
        }
        // Intentionally do not reset _visualAxis or _visualPixels — the
        // disc freezes at whatever pose the finger left it in.
      case _GestureMode.tap:
        final region = _active;
        if (region != null) _fire(region);
      case _GestureMode.cancelled:
      case _GestureMode.idle:
        break;
    }
    // For OK we just set the highlight in the spin branch above — leave it
    // visible briefly so the press registers, then clear. Arm taps had
    // their highlight up throughout the press, so they clear immediately.
    if (_active == _Region.ok) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _active = null);
      });
    } else {
      setState(() => _active = null);
    }
    _hasFiredTick = false;
    _spinCommitted = false;
    _mode = _GestureMode.idle;
    _scheduleIdleFade();
  }

  void _onPanCancel() {
    // Same "freeze in place" behavior as a normal end — leave _visualAxis
    // and _visualPixels untouched.
    if (_active != null) setState(() => _active = null);
    _hasFiredTick = false;
    _spinCommitted = false;
    _mode = _GestureMode.idle;
    _scheduleIdleFade();
  }

  @override
  void dispose() {
    _idleFadeTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // Sign of the active drag along the locked axis. +1 means the leading
  // half is the *far* one along the axis (down for vertical, right for
  // horizontal); -1 means the *near* one. 0 when idle.
  int get _flipSign {
    if (_visualAxis == _SpinAxis.none || _visualRotation == 0) return 0;
    return _visualRotation > 0 ? 1 : -1;
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
              // Centre spin disc — a rolodex. At rest only the current card
              // shows (with a small ambient rock to hint scrollability). On
              // drag, the disc splits at the axle perpendicular to the drag,
              // and the leading half hinges around that axle. Behind the
              // flipping half sits the next identical card, hidden until the
              // flipping half passes 90°. After a full π of flip the leading
              // half lies flat against the trailing half and a new flip
              // begins — the user perceives an endless reel.
              Center(
                child: AnimatedScale(
                  scale: _active == _Region.ok ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: SizedBox.square(
                    dimension: discDiameter,
                    // Static underlay sits beneath the rolodex. After 3
                    // seconds of inactivity the rolodex fades over it, so
                    // whatever pose the user left the cards in gradually
                    // dissolves into the plain upright icon.
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FlixsyLogo(
                          size: discDiameter,
                          discColor: discColor,
                        ),
                        const IgnorePointer(
                          child: CustomPaint(
                            painter: _DomeShadingPainter(),
                          ),
                        ),
                        Opacity(
                          opacity: 1.0 - _fadeController.value,
                          child: _RolodexDisc(
                            diameter: discDiameter,
                            discColor: discColor,
                            axis: _visualAxis,
                            unwrappedRotation: _visualRotation.abs(),
                            flipSign: _flipSign,
                          ),
                        ),
                      ],
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

/// The rolodex assembly that lives inside the centre spin disc.
///
/// At rest ([axis] = none) renders a single upright card. During a drag it
/// composes three layers (back to front):
///
///   1. **Trailing static half** — the half opposite to the drag direction.
///      Stays put through every flip; on a continuous reel this is just the
///      bottom (or right) of the current card.
///   2. **Hidden next-card leading half** — a copy of the leading half at the
///      axle plane. Fully covered by layer 3 while the front half is still
///      tilted toward the viewer; once the flip passes 90° and layer 3 swings
///      away, this layer is what the user actually sees as the new card.
///   3. **Flipping leading half** — hinges on the axle from 0 → π, then the
///      flip wraps (since cards are identical the wrap is invisible) and the
///      next card begins.
class _RolodexDisc extends StatelessWidget {
  const _RolodexDisc({
    required this.diameter,
    required this.discColor,
    required this.axis,
    required this.unwrappedRotation,
    required this.flipSign,
  });

  final double diameter;
  final Color discColor;
  final _SpinAxis axis;

  /// Total accumulated rotation magnitude (radians), NOT wrapped into
  /// [0, π). Each card derives its own per-cycle flip angle by
  /// subtracting its phase offset before wrapping — that lets cards
  /// 1..N-1 stay collapsed at 0 until the user has scrolled far enough
  /// for them to enter the cycle (no pop-in on first drag).
  final double unwrappedRotation;

  /// +1 means the leading half is the *far* one along the axis (bottom for
  /// vertical drag, right for horizontal); -1 means the *near* one; 0 idle.
  final int flipSign;

  // The full upright card — logo + dome shading — sized to the disc. Reused
  // for each clipped half so a single source of pixels travels through every
  // layer.
  Widget _fullFace() => Stack(
    fit: StackFit.expand,
    children: [
      FlixsyLogo(size: diameter, discColor: discColor),
      IgnorePointer(child: CustomPaint(painter: const _DomeShadingPainter())),
    ],
  );

  // One half of the full face, clipped to the requested side. The clipped
  // layer is still full-size so logo geometry doesn't shift — only its
  // visible region is reduced.
  Widget _half(_HalfSide side) => ClipRect(
    clipper: _HalfClipper(side),
    child: SizedBox.square(dimension: diameter, child: _fullFace()),
  );

  // Build the matrix that rotates a half around the axle. The axle sits at
  // the centre of the full disc, so we translate the rotation origin to the
  // disc centre, rotate, and translate back. A small perspective entry sells
  // the depth.
  Matrix4 _flipMatrix({required bool vertical, required double angle}) {
    final centre = diameter / 2;
    final m = Matrix4.identity()..setEntry(3, 2, 0.001);
    m.translateByDouble(centre, centre, 0, 1);
    if (vertical) {
      m.rotateX(angle);
    } else {
      m.rotateY(angle);
    }
    m.translateByDouble(-centre, -centre, 0, 1);
    return m;
  }

  // Number of flip cards in flight at once. With N>1, card k lags card 0
  // by k·π/N in the flip cycle, so a fast scroll shows several pages
  // mid-flip stacked at different angles — like riffling a deck of
  // identical pages. When idle, all cards collapse to angle 0 so the
  // disc still reads as a single upright face.
  static const int _cardCount = 2;

  @override
  Widget build(BuildContext context) {
    // Pick the half assignment for the *current* drag direction, or a
    // default (top leading, bottom trailing — matches a down-drag) for the
    // idle case so the element tree shape is identical whether we're
    // flipping or at rest. Swapping subtrees between idle and active
    // remounts the SVG painters; that one-frame remount was the flash at
    // the end of every scroll.
    final vertical = axis != _SpinAxis.horizontal;
    final _HalfSide leading;
    final _HalfSide trailing;
    if (vertical) {
      if (flipSign >= 0) {
        leading = _HalfSide.top;
        trailing = _HalfSide.bottom;
      } else {
        leading = _HalfSide.bottom;
        trailing = _HalfSide.top;
      }
    } else {
      if (flipSign >= 0) {
        leading = _HalfSide.left;
        trailing = _HalfSide.right;
      } else {
        leading = _HalfSide.right;
        trailing = _HalfSide.left;
      }
    }
    final isIdle = axis == _SpinAxis.none || unwrappedRotation == 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Trailing half — static, always upright.
        _half(trailing),
        // 2. Next card's leading half — sits flat at the axle plane. Hidden
        //    by the flipping cards until at least one of them passes 90°,
        //    at which point this becomes the visible front.
        _half(leading),
        // 3. Up to N flipping cards on the axle. Card k lags card 0 by
        //    k·π/N and stays collapsed at angle 0 until the total
        //    rotation has caught up to its phase offset — so the first
        //    drag pulls only card 0 from the top, and cards 1..N-1 enter
        //    the riffle one at a time as the user keeps scrolling.
        //    Painted oldest-first (largest k on the bottom) so the most
        //    recently started card paints last.
        for (int k = _cardCount - 1; k >= 0; k--)
          _flipCard(
            k: k,
            vertical: vertical,
            leading: leading,
            trailing: trailing,
            isIdle: isIdle,
          ),
      ],
    );
  }

  // One flipping card in the N-card fan. k=0 matches the original
  // single-card behaviour; k>0 lags by k·π/N. Once a card rotates past
  // 90° its back faces the viewer, so we swap in a pre-mirrored copy of
  // the trailing half — the outer flipMatrix's rotation cancels the
  // pre-mirror and the trailing-half shading lands right-side up over
  // the static trailing layer, so each card's wrap from π back to 0 is
  // visually seamless.
  Widget _flipCard({
    required int k,
    required bool vertical,
    required _HalfSide leading,
    required _HalfSide trailing,
    required bool isIdle,
  }) {
    // Card k's "personal" accumulated rotation: total scroll minus the
    // k·π/N head start that card 0 has. Until the user has scrolled past
    // that head start the value is clamped to 0 and card k sits collapsed
    // at the leading position — invisible behind card 0. Once it goes
    // positive the card joins the riffle and cycles continuously.
    final cardUnwrapped = math.max(
      0.0,
      unwrappedRotation - k * math.pi / _cardCount,
    );
    final cardFlipAngle = isIdle ? 0.0 : cardUnwrapped % math.pi;
    double cardSignedAngle;
    if (vertical) {
      cardSignedAngle = flipSign >= 0 ? cardFlipAngle : -cardFlipAngle;
    } else {
      cardSignedAngle = flipSign >= 0 ? -cardFlipAngle : cardFlipAngle;
    }

    final showBack = cardSignedAngle.abs() > math.pi / 2;
    // Both faces stay mounted via IndexedStack so swapping them at π/2
    // doesn't churn render objects (the previous if/else remounted the
    // ClipRect/SVG subtree every time, which read as a hitch — same
    // problem the trailing/leading static-layer comment guards against).
    return Transform(
      alignment: Alignment.topLeft,
      transform: _flipMatrix(vertical: vertical, angle: cardSignedAngle),
      child: IndexedStack(
        alignment: Alignment.center,
        sizing: StackFit.expand,
        index: showBack ? 1 : 0,
        children: [
          _half(leading),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scaleByDouble(
                vertical ? 1.0 : -1.0,
                vertical ? -1.0 : 1.0,
                1.0,
                1.0,
              ),
            child: _half(trailing),
          ),
        ],
      ),
    );
  }
}

/// Clips a full-size square layer down to one of its halves. Used so the
/// rolodex can render the same logo widget four times (trailing, hidden
/// next, flipping front, optional back of the flipping card) and have each
/// instance only show the geometry the viewer should see.
class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper(this.side);

  final _HalfSide side;

  @override
  Rect getClip(Size size) {
    switch (side) {
      case _HalfSide.top:
        return Rect.fromLTWH(0, 0, size.width, size.height / 2);
      case _HalfSide.bottom:
        return Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);
      case _HalfSide.left:
        return Rect.fromLTWH(0, 0, size.width / 2, size.height);
      case _HalfSide.right:
        return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
    }
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.side != side;
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
