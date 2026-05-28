import 'dart:math' as math;

// ignore: unnecessary_import — needed for PanGestureRecognizer subclassing
// and GestureDisposition, which material.dart re-exports only as meta-types
// (the analyzer's hint is wrong here).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/shared/widgets/spinnable_star_dpad.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/remote_skin.dart';

/// The five interactive regions of the Flixsy logo remote.
///
/// The logo's 4-point sparkle star points exactly N/S/E/W; the points
/// converge at the centre. Each region carries the [RemoteKey] it sends.
enum _SpinAxis { none, vertical, horizontal }

// Which half of the disc a clip should keep visible — used by the rolodex
// layers to render the SVG split at the active axle.
enum _HalfSide { top, bottom, left, right }

enum _LogoRegion {
  up(RemoteKey.up), // North point
  down(RemoteKey.down), // South point
  next(RemoteKey.next), // East point
  previous(RemoteKey.previous), // West point
  ok(RemoteKey.ok); // Centre

  const _LogoRegion(this.action);

  final RemoteKey action;
}

// Hit-test geometry, expressed as a fraction of the (square) widget side so
// the layout is resolution independent. The logo SVG fills the square 1:1.
//
//  • r <= _centerRadius            -> centre 'OK' button
//  • _centerRadius < r < _armInner -> dead zone (gap so the centre stays
//                                     distinct from the arms)
//  • _armInner <= r <= _armOuter   -> a directional arm, picked by angle
//  • r > _armOuter                 -> dead zone (taps off the logo)
//
// Each directional wedge is (90 - 2*_guardDegrees) wide, leaving a dead band
// along the diagonals so adjacent arms can't be fat-fingered into each other.
const double _centerRadius = 0.166;
const double _armInnerRadius = 0.190;
const double _armOuterRadius = 0.440;
const double _guardDegrees = 9.0;

/// Logo-shaped remote skin: the Flixsy sparkle star *is* the control surface.
class MainRemoteSkin extends StatefulWidget implements RemoteSkin {
  const MainRemoteSkin({super.key, required this.onKeyPressed});

  @override
  final void Function(String key) onKeyPressed;

  @override
  State<MainRemoteSkin> createState() => _MainRemoteSkinState();
}

class _MainRemoteSkinState extends State<MainRemoteSkin> {
  /// The region currently held down, used only for press feedback.
  _LogoRegion? _active;

  // Spin state — see `SpinnableStarDpad` for the full rationale behind the
  // axis-lock + linear-drag design. This skin owns its own copy because its
  // hit-test geometry and highlight overlay are bound to the logo SVG.
  //
  // `_axisPixels` *persists* across gestures: when the finger lifts mid-flip
  // the disc freezes at its current pose, and the next gesture continues
  // from there. `_basePixels` anchors the live drag delta against that
  // carried-over rotation so each pan contributes only its own travel.
  _SpinAxis _axis = _SpinAxis.none;
  double _axisPixels = 0;
  double _basePixels = 0;
  double _lastTickPixels = 0;
  Offset _panStart = Offset.zero;
  Offset _axisLockOrigin = Offset.zero;
  bool _isSpinning = false;
  // True between touch-down and the moment a fresh axis lock latches. While
  // set, the renderer keeps showing the previous gesture's pose; once the
  // new drag picks an axis we either continue (same axis) or snap to a
  // fresh card on the new axle (cross-axis).
  bool _pendingRelock = false;

  double get _visualRotation =>
      _axisPixels * SpinnableStarDpad.tickAngle / SpinnableStarDpad.pixelsPerTick;

  // Current flip angle, wrapped into [0, π) so each π of accumulated
  // rotation reads as one full card flip and the next card starts fresh.
  double get _flipAngle {
    if (_axis == _SpinAxis.none) return 0;
    return _visualRotation.abs() % math.pi;
  }

  // Sign of accumulated rotation along the locked axis. Picks which half
  // hinges; 0 when idle.
  int get _flipSign {
    if (_axis == _SpinAxis.none || _visualRotation == 0) return 0;
    return _visualRotation > 0 ? 1 : -1;
  }

  void _clearActive() {
    if (_active != null) setState(() => _active = null);
  }

  // Pan handlers cover *both* the arm-tap (a short pan that never crosses
  // the spin threshold) and the spin gesture. Using a single eager pan
  // recognizer — instead of separate tap + pan — stops ancestor scrollables
  // (the skin-picker `PageView`) from stealing the gesture mid-spin.
  void _onPanStart(DragStartDetails details, double side) {
    _panStart = details.localPosition;
    _axisLockOrigin = details.localPosition;
    _isSpinning = false;
    // Carry the previous gesture's rotation forward — don't touch _axis or
    // _axisPixels. The renderer keeps the disc in its frozen pose until a
    // new drag direction nudges it.
    _pendingRelock = true;
    final region = _hitTest(details.localPosition, side);
    setState(() => _active = region);
  }

  void _onPanUpdate(DragUpdateDetails details, double _) {
    final local = details.localPosition;

    if (_pendingRelock) {
      final fromStart = local - _panStart;
      if (fromStart.distanceSquared <
          SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
        return;
      }
      final newAxis = fromStart.dx.abs() >= fromStart.dy.abs()
          ? _SpinAxis.horizontal
          : _SpinAxis.vertical;
      // Cross-axis transition: the prior pose was rotated around a
      // different axle, so carrying its angle onto the new axle would look
      // arbitrary. Snap to a fresh upright card on the new axle instead.
      if (_axis != _SpinAxis.none && newAxis != _axis) {
        _axisPixels = 0;
      }
      _axis = newAxis;
      _axisLockOrigin = local;
      _basePixels = _axisPixels;
      _lastTickPixels = _axisPixels;
      _pendingRelock = false;
      _isSpinning = true;
      // Lock-in: the highlight on the arm we started over no longer matches
      // what the gesture will do, so clear it.
      if (_active != null) _active = null;
    }

    final fromLock = local - _axisLockOrigin;
    final delta = _axis == _SpinAxis.vertical ? fromLock.dy : fromLock.dx;
    _axisPixels = _basePixels + delta;
    setState(() {});

    // Map ticks to this skin's east/west semantics: horizontal scroll is
    // track skip (previous/next), not arrow left/right — matches the arm
    // tap mapping on the same star points.
    while (_axisPixels - _lastTickPixels >= SpinnableStarDpad.pixelsPerTick) {
      _lastTickPixels += SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onKeyPressed(
        _axis == _SpinAxis.vertical
            ? RemoteKey.down.code
            : RemoteKey.next.code,
      );
    }
    while (_lastTickPixels - _axisPixels >= SpinnableStarDpad.pixelsPerTick) {
      _lastTickPixels -= SpinnableStarDpad.pixelsPerTick;
      HapticFeedback.selectionClick();
      widget.onKeyPressed(
        _axis == _SpinAxis.vertical
            ? RemoteKey.up.code
            : RemoteKey.previous.code,
      );
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isSpinning) {
      final region = _active;
      if (region != null) {
        HapticFeedback.selectionClick();
        widget.onKeyPressed(region.action.code);
      }
    }
    setState(() => _active = null);
    _isSpinning = false;
    _pendingRelock = false;
    // Intentionally do NOT touch _axis or _axisPixels — the disc freezes
    // at whatever pose the finger left it in, and the next gesture picks
    // up from there.
  }

  void _onPanCancel() {
    _clearActive();
    _isSpinning = false;
    _pendingRelock = false;
  }

  /// Maps a local tap position to a [_LogoRegion], or `null` for dead zones.
  _LogoRegion? _hitTest(Offset position, double side) {
    final v = position - Offset(side / 2, side / 2);
    final r = v.distance / side;

    if (r <= _centerRadius) return _LogoRegion.ok;
    if (r < _armInnerRadius || r > _armOuterRadius) return null;

    // 0 deg = East, 90 = South, -90 = North (screen y grows downward).
    final deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    if (_withinWedge(deg, 0)) return _LogoRegion.next;
    if (_withinWedge(deg, 90)) return _LogoRegion.down;
    if (_withinWedge(deg, 180)) return _LogoRegion.previous;
    if (_withinWedge(deg, -90)) return _LogoRegion.up;
    return null; // diagonal dead band
  }

  /// True when [deg] is inside the guarded wedge centred on [axisDeg].
  bool _withinWedge(double deg, double axisDeg) {
    var delta = (deg - axisDeg).abs() % 360;
    if (delta > 180) delta = 360 - delta;
    return delta < 45 - _guardDegrees;
  }

  @override
  Widget build(BuildContext context) {
    // The sparkle star carries the directional + OK keys. System / transport
    // keys sit in a top bar, volume + channel rockers flank the star, and
    // navigation + remaining transport keys live in the bottom bar.
    //
    // The remote is a physical control surface: its geometry is fixed to LTR
    // so the star's points and the surrounding buttons never mirror with an
    // RTL UI language. The button labels themselves are still localized.
    final onKey = widget.onKeyPressed;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.power_settings_new,
                action: RemoteKey.power,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.settings_outlined,
                action: RemoteKey.settings,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.volume_off_outlined,
                action: RemoteKey.mute,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.play_arrow_outlined,
                action: RemoteKey.playPause,
                onKeyPressed: onKey,
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.volume_up_outlined,
                        action: RemoteKey.volumeUp,
                        onKeyPressed: onKey,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                      _ControlButton(
                        icon: Icons.volume_down_outlined,
                        action: RemoteKey.volumeDown,
                        onKeyPressed: onKey,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildLogoPad()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.keyboard_arrow_up,
                        action: RemoteKey.channelUp,
                        onKeyPressed: onKey,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                      _ControlButton(
                        icon: Icons.keyboard_arrow_down,
                        action: RemoteKey.channelDown,
                        onKeyPressed: onKey,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.fast_rewind_outlined,
                action: RemoteKey.rewind,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.arrow_back_rounded,
                action: RemoteKey.back,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.home_outlined,
                action: RemoteKey.home,
                onKeyPressed: onKey,
              ),
              _ControlButton(
                icon: Icons.fast_forward_outlined,
                action: RemoteKey.fastForward,
                onKeyPressed: onKey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The logo star control surface — kept self-contained so its hit-test
  /// geometry doesn't depend on the control bar's height.
  Widget _buildLogoPad() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final side = available.isFinite ? available : 360.0;
          return SizedBox(
            key: const ValueKey('flixsyLogoPad'),
            width: side,
            height: side,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                _EagerPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _EagerPanGestureRecognizer
                    >(
                      () => _EagerPanGestureRecognizer(),
                      (instance) {
                        instance.onStart = (d) => _onPanStart(d, side);
                        instance.onUpdate = (d) => _onPanUpdate(d, side);
                        instance.onEnd = _onPanEnd;
                        instance.onCancel = _onPanCancel;
                      },
                    ),
              },
              child: AnimatedScale(
                scale: _active == null ? 1.0 : 0.97,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _RolodexLogo(
                      side: side,
                      axis: _axis,
                      flipAngle: _flipAngle,
                      flipSign: _flipSign,
                      semanticsLabel: context.l10n.mainRemoteSemanticLabel,
                    ),
                    // Press highlight stays on top of the rolodex and does
                    // not flip — it's UI feedback, anchored to the screen.
                    CustomPaint(
                      painter: _HighlightPainter(
                        region: _active,
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A circular control button in the bar beneath the logo star. Sends its
/// [action] through [onKeyPressed] — the same callback the star uses — so
/// it routes to the connected TV exactly like a directional key.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.action,
    required this.onKeyPressed,
    this.compact = false,
  });

  final IconData icon;
  final RemoteKey action;
  final void Function(String key) onKeyPressed;
  final bool compact;

  void _handleTap() {
    HapticFeedback.selectionClick();
    onKeyPressed(action.code);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.remoteKeyLabel(action);
    return Tooltip(
      message: label,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: CircleBorder(
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 18),
            child: Icon(
              icon,
              size: compact ? 18 : 24,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a translucent overlay over the region currently pressed.
class _HighlightPainter extends CustomPainter {
  const _HighlightPainter({required this.region, required this.color});

  final _LogoRegion? region;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final region = this.region;
    if (region == null) return;

    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;

    if (region == _LogoRegion.ok) {
      canvas.drawCircle(center, _centerRadius * side, paint);
      return;
    }

    final axisDeg = switch (region) {
      _LogoRegion.next => 0.0,
      _LogoRegion.down => 90.0,
      _LogoRegion.previous => 180.0,
      _LogoRegion.up => -90.0,
      _LogoRegion.ok => 0.0, // unreachable — handled above
    };

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

    // A donut sector: out along the wedge, then back along the inner radius.
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

/// The Flixsy logo SVG rendered as a rolodex.
///
/// At rest the three layers stack to look like a single upright card; during
/// a drag the leading half hinges around the active axle (horizontal for a
/// vertical drag, vertical for a horizontal drag) while a hidden duplicate
/// of the leading half waits behind it, becoming visible the moment the
/// flipping half rotates past edge-on. Because every card is identical, an
/// angle that wraps past π reads as a fresh card starting its drop — the
/// reel feels endless.
///
/// The layer tree shape is the same whether the disc is idle or flipping;
/// only the `signedAngle` differs. Keeping the shape stable across states
/// stops the SVG painters from remounting at the moment a scroll ends,
/// which previously caused a one-frame flash.
class _RolodexLogo extends StatelessWidget {
  const _RolodexLogo({
    required this.side,
    required this.axis,
    required this.flipAngle,
    required this.flipSign,
    required this.semanticsLabel,
  });

  final double side;
  final _SpinAxis axis;
  final double flipAngle;
  final int flipSign;
  final String semanticsLabel;

  // One instance of the full-disc SVG. Reused for each clipped layer so the
  // three halves come from the same vector source. Only the trailing layer
  // carries semantics — the others duplicate the same image and would
  // otherwise be announced three times.
  Widget _card({required bool labelled}) => SvgPicture.asset(
    'assets/images/flixsy_logo.svg',
    width: side,
    height: side,
    semanticsLabel: labelled ? semanticsLabel : null,
    excludeFromSemantics: !labelled,
  );

  Widget _half(_HalfSide hSide, {required bool labelled}) => ClipRect(
    clipper: _HalfClipper(hSide),
    child: SizedBox.square(
      dimension: side,
      child: _card(labelled: labelled),
    ),
  );

  // Rotate around the axle that passes through the disc centre. Translate
  // origin to centre, rotate, translate back; a small perspective entry
  // sells the depth.
  Matrix4 _flipMatrix({required bool vertical, required double angle}) {
    final centre = side / 2;
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

  @override
  Widget build(BuildContext context) {
    // Default to a vertical-axle split when idle (matches a down-drag). The
    // signedAngle collapses to 0 for the idle case so the layers stack into
    // a single upright card — same element tree shape as the flipping case.
    final vertical = axis != _SpinAxis.horizontal;
    final _HalfSide leading;
    final _HalfSide trailing;
    double signedAngle;
    if (vertical) {
      if (flipSign >= 0) {
        // Drag down → top half folds down onto the bottom half.
        leading = _HalfSide.top;
        trailing = _HalfSide.bottom;
        signedAngle = flipAngle;
      } else {
        // Drag up → bottom half folds up onto the top half.
        leading = _HalfSide.bottom;
        trailing = _HalfSide.top;
        signedAngle = -flipAngle;
      }
    } else {
      if (flipSign >= 0) {
        // Drag right → left half folds rightward onto the right half.
        leading = _HalfSide.left;
        trailing = _HalfSide.right;
        signedAngle = -flipAngle;
      } else {
        // Drag left → right half folds leftward onto the left half.
        leading = _HalfSide.right;
        trailing = _HalfSide.left;
        signedAngle = flipAngle;
      }
    }
    if (axis == _SpinAxis.none || flipSign == 0 || flipAngle == 0) {
      signedAngle = 0;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _half(trailing, labelled: true),
        _half(leading, labelled: false),
        Transform(
          alignment: Alignment.topLeft,
          transform: _flipMatrix(vertical: vertical, angle: signedAngle),
          child: _half(leading, labelled: false),
        ),
      ],
    );
  }
}

/// Clips a full-size square layer down to one of its halves. The clipped
/// layer is still full-size so the SVG's interior geometry doesn't shift —
/// only its visible region is reduced.
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

/// A [PanGestureRecognizer] that wins the gesture arena the instant a finger
/// touches it, instead of waiting for kTouchSlop movement.
///
/// Without this, an ancestor `PageView` (the skin-picker carousel) steals the
/// gesture mid-spin whenever the user's motion happens to align with its
/// horizontal drag axis — the wheel "stops spinning after a little while."
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
