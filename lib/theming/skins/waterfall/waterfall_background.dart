import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flixsy/theming/skins/waterfall/waterfall_theme.dart';

/// Slow-moving wavy blue bands that drift downward — the ambient backdrop
/// for the `Waterfall` skin. Self-contained: owns its ticker and clips its
/// repaints to a [RepaintBoundary] so the foreground buttons don't redraw.
class WaterfallBackground extends StatefulWidget {
  const WaterfallBackground({super.key});

  @override
  State<WaterfallBackground> createState() => _WaterfallBackgroundState();
}

class _WaterfallBackgroundState extends State<WaterfallBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          painter: _WaterfallPainter(t: _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Stream {
  const _Stream({
    required this.baseX,
    required this.width,
    required this.speed,
    required this.phaseSeed,
    required this.amplitude,
    required this.wavelengthY,
    required this.color,
  });

  // All distances are fractions of the canvas, so the painter scales to
  // whatever box the background ends up in. The stream is a vertical column
  // whose centre sways left/right; [speed] is how many full screen-heights
  // the wave pattern travels per controller cycle.
  final double baseX;
  final double width;
  final double speed;
  final double phaseSeed;
  final double amplitude;
  final double wavelengthY;
  final Color color;
}

class _WaterfallPainter extends CustomPainter {
  _WaterfallPainter({required this.t});

  /// Normalised animation time (0..1, wraps).
  final double t;

  // Vertical streams of falling water, staggered across the width. Each
  // streams's wave pattern scrolls downward at [speed] full screens per
  // controller cycle — that's what reads as "falling."
  //
  // [speed] **must be an integer** so the phase wraps cleanly when the
  // controller resets t from 1→0; non-integer speeds leave residual phase
  // and produce a visible jump on every cycle boundary.
  static const List<_Stream> _streams = [
    _Stream(
      baseX: 0.12,
      width: 0.16,
      speed: 1,
      phaseSeed: 0.00,
      amplitude: 0.025,
      wavelengthY: 0.45,
      color: Color(0x55B8E0F0),
    ),
    _Stream(
      baseX: 0.30,
      width: 0.22,
      speed: 2,
      phaseSeed: 0.27,
      amplitude: 0.030,
      wavelengthY: 0.55,
      color: Color(0x553EA8D4),
    ),
    _Stream(
      baseX: 0.52,
      width: 0.19,
      speed: 2,
      phaseSeed: 0.55,
      amplitude: 0.028,
      wavelengthY: 0.50,
      color: Color(0x552C7FB8),
    ),
    _Stream(
      baseX: 0.72,
      width: 0.24,
      speed: 3,
      phaseSeed: 0.82,
      amplitude: 0.035,
      wavelengthY: 0.42,
      color: Color(0x55154A78),
    ),
    _Stream(
      baseX: 0.90,
      width: 0.14,
      speed: 2,
      phaseSeed: 0.41,
      amplitude: 0.020,
      wavelengthY: 0.60,
      color: Color(0x559FD4EA),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Top-to-bottom depth gradient: surface light, abyss dark.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WaterfallTheme.deep, WaterfallTheme.abyss],
        ).createShader(rect),
    );

    for (final stream in _streams) {
      _paintStream(canvas, size, stream);
    }
  }

  void _paintStream(Canvas canvas, Size size, _Stream stream) {
    final w = size.width;
    final h = size.height;
    final baseX = stream.baseX * w;
    final halfWidth = (stream.width * w) / 2;
    final amp = stream.amplitude * w;
    final yWavelen = stream.wavelengthY * h;

    // Subtracting the time term scrolls the same wave value to a larger y
    // as t increases — the pattern flows downward.
    final timePhase = (t * stream.speed + stream.phaseSeed) * math.pi * 2;

    final path = Path();
    const steps = 64;

    // Left edge, top → bottom.
    for (var i = 0; i <= steps; i++) {
      final y = h * i / steps;
      final phi = (y / yWavelen) * math.pi * 2 - timePhase;
      final cx = baseX + math.sin(phi) * amp;
      final x = cx - halfWidth;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // Right edge, bottom → top. A small phase offset gives the column a
    // slightly-uneven width as it falls instead of a rigid mirror.
    for (var i = steps; i >= 0; i--) {
      final y = h * i / steps;
      final phi = (y / yWavelen) * math.pi * 2 - timePhase + 0.5;
      final cx = baseX + math.sin(phi) * amp;
      final x = cx + halfWidth;
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = stream.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  @override
  bool shouldRepaint(covariant _WaterfallPainter old) => old.t != t;
}
