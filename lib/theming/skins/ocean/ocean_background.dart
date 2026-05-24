import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flixsy/theming/skins/ocean/ocean_palette.dart';

/// Sky-and-water backdrop for the `Ocean` skin: a horizon line, a sun that
/// arcs across by day and a moon that does the same by night, plus a few
/// slow ripples that scroll on the water surface. The day cycle runs on a
/// long ticker; the ripples run on a short one with integer-multiple speeds
/// so they wrap without a visible jump.
class OceanBackground extends StatefulWidget {
  const OceanBackground({super.key});

  @override
  State<OceanBackground> createState() => _OceanBackgroundState();
}

class _OceanBackgroundState extends State<OceanBackground>
    with TickerProviderStateMixin {
  late final AnimationController _dayCycle;
  late final AnimationController _ripples;

  @override
  void initState() {
    super.initState();
    // 3-minute day cycle: slow enough to feel peaceful, short enough that a
    // user actually sees the sky change during a remote session.
    _dayCycle = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 3),
    )..repeat();
    _ripples = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _dayCycle.dispose();
    _ripples.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_dayCycle, _ripples]),
        builder: (_, _) => CustomPaint(
          painter: _OceanPainter(
            skyT: _dayCycle.value,
            rippleT: _ripples.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _OceanPainter extends CustomPainter {
  _OceanPainter({required this.skyT, required this.rippleT});

  final double skyT;
  final double rippleT;

  // Surface ripples — each is a horizontal wavy line composed of three sine
  // harmonics at integer-multiple speeds. The integer constraint keeps the
  // controller wrap seamless; the layered harmonics keep the shape chaotic.
  // Parameters are generated once at startup from a fixed RNG seed so each
  // ripple has its own character but the scene is reproducible.
  static final List<_Ripple> _ripples = _buildRipples();

  static List<_Ripple> _buildRipples() {
    final rng = math.Random(7);
    final out = <_Ripple>[];
    for (var i = 0; i < 9; i++) {
      final yBase = 0.04 + i * 0.105;
      final yJitter = (rng.nextDouble() - 0.5) * 0.06;
      out.add(
        _Ripple(
          yFraction: (yBase + yJitter).clamp(0.02, 0.96),
          speed: 1 + rng.nextInt(2),
          amplitude: 0.006 + rng.nextDouble() * 0.012,
          components: [
            _RippleComponent(
              wavelength: 0.30 + rng.nextDouble() * 0.30,
              phaseOffset: rng.nextDouble() * math.pi * 2,
              weight: 0.55 + rng.nextDouble() * 0.20,
              speedMultiplier: 1,
            ),
            _RippleComponent(
              wavelength: 0.12 + rng.nextDouble() * 0.10,
              phaseOffset: rng.nextDouble() * math.pi * 2,
              weight: 0.25 + rng.nextDouble() * 0.15,
              speedMultiplier: 2,
            ),
            _RippleComponent(
              wavelength: 0.05 + rng.nextDouble() * 0.05,
              phaseOffset: rng.nextDouble() * math.pi * 2,
              weight: 0.10 + rng.nextDouble() * 0.10,
              speedMultiplier: 3,
            ),
          ],
        ),
      );
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final state = oceanSkyStateAt(skyT);
    final w = size.width;
    final h = size.height;
    final horizonY = oceanHorizonFraction * h;

    _paintSky(canvas, size, horizonY, state);
    _paintLuminary(
      canvas,
      size,
      state.sunPos,
      state.sunColor,
      state.sunAlpha,
      isSun: true,
    );
    _paintLuminary(
      canvas,
      size,
      state.moonPos,
      state.moonColor,
      state.moonAlpha,
    );
    _paintHorizonGlow(canvas, size, horizonY, state);
    _paintWater(canvas, size, horizonY, state);
    _paintReflection(canvas, size, horizonY, state);
    _paintRipples(canvas, size, horizonY, state);
    // A soft horizon line on top of everything, very thin, so the eye reads
    // the boundary between air and water.
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      Paint()
        ..color = state.skyHorizon.withAlpha(70)
        ..strokeWidth = 1,
    );
  }

  void _paintSky(Canvas canvas, Size size, double horizonY, OceanSkyState s) {
    final rect = Rect.fromLTRB(0, 0, size.width, horizonY);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [s.skyTop, s.skyHorizon],
        ).createShader(rect),
    );
  }

  void _paintWater(Canvas canvas, Size size, double horizonY, OceanSkyState s) {
    final rect = Rect.fromLTRB(0, horizonY, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [s.waterTop, s.waterDeep],
        ).createShader(rect),
    );
  }

  void _paintLuminary(
    Canvas canvas,
    Size size,
    Offset posFraction,
    Color color,
    double alpha, {
    bool isSun = false,
  }) {
    if (alpha <= 0) return;
    final w = size.width;
    final h = size.height;
    final centre = Offset(posFraction.dx * w, posFraction.dy * h);
    final radius = math.min(w, h) * (isSun ? 0.055 : 0.045);

    if (isSun) {
      // Outer warm halo, broad and soft.
      canvas.drawCircle(
        centre,
        radius * 4.0,
        Paint()
          ..color = color.withAlpha((alpha * 110).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
      // Mid halo — adds visible glow density.
      canvas.drawCircle(
        centre,
        radius * 2.2,
        Paint()
          ..color = color.withAlpha((alpha * 180).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      // Sun disc — crisper edge so it reads as a bright body.
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = color.withAlpha((alpha * 255).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Bright near-white core for that hot midday feel.
      canvas.drawCircle(
        centre,
        radius * 0.6,
        Paint()
          ..color = Color.lerp(
            color,
            Colors.white,
            0.6,
          )!.withAlpha((alpha * 255).round()),
      );
      return;
    }

    // Moon: soft halo + disc.
    canvas.drawCircle(
      centre,
      radius * 3.0,
      Paint()
        ..color = color.withAlpha((alpha * 80).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = color.withAlpha((alpha * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _paintHorizonGlow(
    Canvas canvas,
    Size size,
    double horizonY,
    OceanSkyState s,
  ) {
    if (s.horizonGlowAlpha <= 0) return;
    final h = size.height;
    final band = h * 0.18;
    final rect = Rect.fromLTRB(0, horizonY - band, size.width, horizonY + band);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            s.horizonGlow.withAlpha(0),
            s.horizonGlow.withAlpha((s.horizonGlowAlpha * 255).round()),
            s.horizonGlow.withAlpha(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
  }

  /// Vertical streak of moonlight on the water, anchored under the moon.
  /// Only visible at night since the day half has no luminary.
  void _paintReflection(
    Canvas canvas,
    Size size,
    double horizonY,
    OceanSkyState s,
  ) {
    if (s.moonAlpha <= 0) return;
    final w = size.width;
    final h = size.height;
    final streakX = s.moonPos.dx * w;

    final rect = Rect.fromLTRB(
      streakX - w * 0.10,
      horizonY,
      streakX + w * 0.10,
      h,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            s.moonColor.withAlpha((s.moonAlpha * 150).round()),
            s.moonColor.withAlpha(0),
          ],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _paintRipples(
    Canvas canvas,
    Size size,
    double horizonY,
    OceanSkyState s,
  ) {
    final w = size.width;
    final h = size.height;
    final waterHeight = h - horizonY;
    if (waterHeight <= 0) return;

    for (final ripple in _ripples) {
      final centreY = horizonY + ripple.yFraction * waterHeight;
      final ampPx = ripple.amplitude * waterHeight;

      final path = Path();
      const steps = 96;
      for (var i = 0; i <= steps; i++) {
        final xNorm = i / steps;
        final dy = _rippleOffset(ripple, xNorm, rippleT) * ampPx;
        final x = w * xNorm;
        final y = centreY + dy;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      // Closing back along the same curve translated downward gives the
      // ripple a thin body. Thickness varies with ripple amplitude so larger
      // ripples read as a slightly thicker band.
      final thickness = ampPx * 0.5 + waterHeight * 0.002;
      for (var i = steps; i >= 0; i--) {
        final xNorm = i / steps;
        final dy = _rippleOffset(ripple, xNorm, rippleT) * ampPx;
        path.lineTo(w * xNorm, centreY + dy + thickness);
      }
      path.close();

      // Brighter near the horizon, fading with depth — light from above
      // catches the surface unevenly.
      final fade = 1 - ripple.yFraction;
      canvas.drawPath(
        path,
        Paint()
          ..color = s.skyHorizon.withAlpha((46 * fade).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  /// Sum of a ripple's sine harmonics evaluated at normalised x in [0, 1].
  /// All component speeds are integer multiples of the ripple's base speed,
  /// so the composite wraps seamlessly with the controller.
  double _rippleOffset(_Ripple ripple, double xNorm, double t) {
    var sum = 0.0;
    for (final c in ripple.components) {
      final phase =
          t * ripple.speed * c.speedMultiplier * math.pi * 2 + c.phaseOffset;
      sum += math.sin(xNorm * math.pi * 2 / c.wavelength + phase) * c.weight;
    }
    return sum;
  }

  @override
  bool shouldRepaint(covariant _OceanPainter old) =>
      old.skyT != skyT || old.rippleT != rippleT;
}

class _Ripple {
  const _Ripple({
    required this.yFraction,
    required this.speed,
    required this.amplitude,
    required this.components,
  });

  final double yFraction;

  /// Integer base speed (full cycles per controller period). Component
  /// multipliers further scale this — all must be integer for seamless wrap.
  final int speed;

  /// Peak vertical displacement, fraction of water height. The components'
  /// weighted sine sum is multiplied by this before painting.
  final double amplitude;

  final List<_RippleComponent> components;
}

class _RippleComponent {
  const _RippleComponent({
    required this.wavelength,
    required this.phaseOffset,
    required this.weight,
    required this.speedMultiplier,
  });

  /// Wavelength in fractions of canvas width — smaller values give faster
  /// horizontal oscillation across the screen.
  final double wavelength;

  /// Per-component phase shift; randomising it across ripples prevents
  /// neighbouring ripples from looking aligned.
  final double phaseOffset;

  /// Contribution of this harmonic to the final sum. Components are not
  /// normalised — the ripple's [_Ripple.amplitude] absorbs the total range.
  final double weight;

  /// Integer multiple of the ripple's base speed. Higher multipliers give
  /// faster, finer chop layered on top of the slow base swell.
  final int speedMultiplier;
}
