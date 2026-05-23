import 'dart:async';
import 'dart:math' as math;

// ignore: unnecessary_import — needed for PanGestureRecognizer subclassing
// and GestureDisposition, which material.dart re-exports only as meta-types
// (the analyzer's hint is wrong here).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../shared/widgets/spinnable_star_dpad.dart';
import '../../icons/remote_key_l10n.dart';
import '../../remote_key.dart';
import '../../remote_skin.dart';

/// The five interactive regions of the Flixsy logo remote.
///
/// The logo's 4-point sparkle star points exactly N/S/E/W; the points
/// converge at the centre. Each region carries the [RemoteKey] it sends.
enum _SpinAxis { none, vertical, horizontal }

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

class _MainRemoteSkinState extends State<MainRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController = AnimationController(
    vsync: this,
    duration: SpinnableStarDpad.resetDuration,
  )..addListener(_onResetTick);

  /// The region currently held down, used only for press feedback.
  _LogoRegion? _active;

  // Spin state — see `SpinnableStarDpad` for the full rationale behind the
  // axis-lock + linear-drag design. This skin owns its own copy because its
  // hit-test geometry and highlight overlay are bound to the logo SVG.
  _SpinAxis _axis = _SpinAxis.none;
  double _axisPixels = 0;
  double _lastTickPixels = 0;
  double _resetFrom = 0;
  double _resetVisual = 0;
  bool _isResetting = false;
  Offset _panStart = Offset.zero;
  Offset _axisLockOrigin = Offset.zero;
  bool _isSpinning = false;
  Timer? _resetTimer;

  double get _visualRotation =>
      _axisPixels * SpinnableStarDpad.tickAngle / SpinnableStarDpad.pixelsPerTick;

  void _clearActive() {
    if (_active != null) setState(() => _active = null);
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
    _resetFrom = _visualRotation;
    _axisPixels = 0;
    _lastTickPixels = 0;
    _resetVisual = _resetFrom;
    _isResetting = true;
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

  // Pan handlers cover *both* the arm-tap (a short pan that never crosses
  // the spin threshold) and the spin gesture. Using a single eager pan
  // recognizer — instead of separate tap + pan — stops ancestor scrollables
  // (the skin-picker `PageView`) from stealing the gesture mid-spin.
  void _onPanStart(DragStartDetails details, double side) {
    _cancelReset();
    _panStart = details.localPosition;
    _axisLockOrigin = details.localPosition;
    _axis = _SpinAxis.none;
    _axisPixels = 0;
    _lastTickPixels = 0;
    _resetVisual = 0;
    _isResetting = false;
    _isSpinning = false;
    final region = _hitTest(details.localPosition, side);
    setState(() => _active = region);
  }

  void _onPanUpdate(DragUpdateDetails details, double _) {
    final local = details.localPosition;

    if (_axis == _SpinAxis.none) {
      final fromStart = local - _panStart;
      if (fromStart.distanceSquared <
          SpinnableStarDpad.tapSlop * SpinnableStarDpad.tapSlop) {
        return;
      }
      _axis = fromStart.dx.abs() >= fromStart.dy.abs()
          ? _SpinAxis.horizontal
          : _SpinAxis.vertical;
      _axisLockOrigin = local;
      _axisPixels = 0;
      _lastTickPixels = 0;
      _isSpinning = true;
      // Lock-in: the highlight on the arm we started over no longer matches
      // what the gesture will do, so clear it.
      if (_active != null) _active = null;
    }

    final fromLock = local - _axisLockOrigin;
    _axisPixels = _axis == _SpinAxis.vertical ? fromLock.dy : fromLock.dx;
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
    _scheduleReset();
  }

  void _onPanCancel() {
    _clearActive();
    _isSpinning = false;
    _scheduleReset();
  }

  Matrix4 _tumbleMatrix() {
    final angle = _isResetting ? _resetVisual : _visualRotation;
    final m = Matrix4.identity()..setEntry(3, 2, 0.001);
    switch (_axis) {
      case _SpinAxis.vertical:
        m.rotateX(angle);
      case _SpinAxis.horizontal:
        m.rotateY(angle);
      case _SpinAxis.none:
        break;
    }
    return m;
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _resetController.dispose();
    super.dispose();
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
          final side = (available.isFinite ? available : 360.0) * 0.9;
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
              child: Transform(
                alignment: Alignment.center,
                transform: _tumbleMatrix(),
                child: AnimatedScale(
                  scale: _active == null ? 1.0 : 0.97,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
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
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                    ],
                  ),
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
