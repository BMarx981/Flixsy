import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../remote_skin.dart';

/// The five interactive regions of the Flixsy logo remote.
///
/// The logo's 4-point sparkle star points exactly N/S/E/W; the points
/// converge at the centre. Each region carries the key code it sends.
enum _LogoRegion {
  up('UP'), // North point
  down('DOWN'), // South point
  next('NEXT'), // East point
  previous('PREVIOUS'), // West point
  ok('OK'); // Centre

  const _LogoRegion(this.keyCode);

  final String keyCode;
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

  void _handleTapDown(TapDownDetails details, double side) {
    final region = _hitTest(details.localPosition, side);
    if (region == null) return; // dead zone — ignore
    HapticFeedback.selectionClick();
    widget.onKeyPressed(region.keyCode);
    setState(() => _active = region);
  }

  void _clearActive() {
    if (_active != null) setState(() => _active = null);
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
    // The sparkle star carries the directional + OK keys; navigation and
    // transport keys live in the control bar below it.
    return Column(
      children: [
        Expanded(child: _buildLogoPad()),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: Icons.fast_rewind_outlined,
              label: 'Rewind',
              keyCode: 'REWIND',
              onKeyPressed: widget.onKeyPressed,
            ),
            _ControlButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              keyCode: 'BACK',
              onKeyPressed: widget.onKeyPressed,
            ),
            _ControlButton(
              icon: Icons.home_outlined,
              label: 'Home',
              keyCode: 'HOME',
              onKeyPressed: widget.onKeyPressed,
            ),
            _ControlButton(
              icon: Icons.fast_forward_outlined,
              label: 'Forward',
              keyCode: 'FAST_FORWARD',
              onKeyPressed: widget.onKeyPressed,
            ),
          ],
        ),
      ],
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTapDown(details, side),
              onTapUp: (_) => _clearActive(),
              onTapCancel: _clearActive,
              child: AnimatedScale(
                scale: _active == null ? 1.0 : 0.97,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SvgPicture.asset(
                      'assets/images/flixsy_logo.svg',
                      semanticsLabel: 'Flixsy remote',
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
          );
        },
      ),
    );
  }
}

/// A circular control button in the bar beneath the logo star. Sends its
/// [keyCode] through [onKeyPressed] — the same callback the star uses — so
/// it routes to the connected TV exactly like a directional key.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.keyCode,
    required this.onKeyPressed,
  });

  final IconData icon;
  final String label;
  final String keyCode;
  final void Function(String key) onKeyPressed;

  void _handleTap() {
    HapticFeedback.selectionClick();
    onKeyPressed(keyCode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
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
                padding: const EdgeInsets.all(14),
                child: Icon(icon, size: 24, color: scheme.onSurface),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.4,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
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
