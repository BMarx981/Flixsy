import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Desert-night backdrop for the `Campfire` skin: a starlit sky with a
/// crescent moon, two layered mesa silhouettes on the horizon, a warm dirt
/// foreground, and a small animated campfire at the bottom centre with
/// rising embers. Stars twinkle on a slow drift controller and the flames
/// flicker on a fast one — both are seeded so the scene is reproducible.
class CampfireBackground extends StatefulWidget {
  const CampfireBackground({super.key});

  @override
  State<CampfireBackground> createState() => _CampfireBackgroundState();
}

class _CampfireBackgroundState extends State<CampfireBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _flicker;

  @override
  void initState() {
    super.initState();
    // Slow controller drives star twinkle + ember vertical drift.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    // Flame flicker controller. The period is the slowest cycle in the
    // scene; per-flame integer multipliers in `_CampfirePainter` pick how
    // many full sine cycles each flame completes per wrap. Integer
    // multipliers are what makes the wrap seamless (sin(2πn) == sin(0)).
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_drift, _flicker]),
        builder: (_, _) => CustomPaint(
          painter: _CampfirePainter(
            driftT: _drift.value,
            flickerT: _flicker.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CampfirePainter extends CustomPainter {
  _CampfirePainter({required this.driftT, required this.flickerT});

  final double driftT;
  final double flickerT;

  // Fraction of canvas height where the far horizon (back of the mesas) sits.
  static const double _horizonY = 0.58;
  // Where the ground line begins (after the mesas drop down).
  static const double _groundY = 0.80;
  // Campfire base in canvas-fraction coords.
  static const Offset _fireBase = Offset(0.50, 0.94);

  static final List<_Star> _stars = _buildStars();
  static final List<_Ember> _embers = _buildEmbers();

  // One integer multiplier per flame (outer, middle, inner). Each is the
  // number of full sine cycles that flame completes per `_flicker` wrap, so
  // higher = faster flicker. 10 matches the original 900 ms cadence (the
  // controller is now 9000 ms); lower values give each flame its own
  // slower rhythm. Integer values are what keeps the wrap discontinuity-
  // free; randomising once at class init means the three flames dance
  // out of sync without churning per frame.
  static final List<int> _flameMultipliers = _buildFlameMultipliers();
  // Glow multiplier is fixed at the max (matches the original cadence) so
  // the overall fire warmth keeps a steady, recognisable heartbeat behind
  // the flames' individual flickers.
  static const int _glowMultiplier = 10;

  static List<int> _buildFlameMultipliers() {
    final rng = math.Random(17);
    return [
      4 + rng.nextInt(7), // 4..10
      4 + rng.nextInt(7),
      4 + rng.nextInt(7),
    ];
  }

  static List<_Star> _buildStars() {
    final rng = math.Random(11);
    final out = <_Star>[];
    for (var i = 0; i < 90; i++) {
      out.add(
        _Star(
          // Stars are confined to the sky region (above the horizon).
          pos: Offset(
            rng.nextDouble(),
            rng.nextDouble() * (_horizonY - 0.04),
          ),
          radiusPx: 0.5 + rng.nextDouble() * 1.4,
          baseAlpha: 0.35 + rng.nextDouble() * 0.50,
          twinkleSpeed: 1 + rng.nextInt(3),
          twinklePhase: rng.nextDouble() * math.pi * 2,
          // A few stars get a warm tint so the field isn't uniformly cold.
          warm: rng.nextDouble() < 0.18,
        ),
      );
    }
    return out;
  }

  static List<_Ember> _buildEmbers() {
    final rng = math.Random(23);
    final out = <_Ember>[];
    for (var i = 0; i < 14; i++) {
      out.add(
        _Ember(
          // Ember stagger: each one starts at a different lifecycle offset so
          // they're never all at the same height. Confined to a small column
          // above the fire.
          phaseOffset: rng.nextDouble(),
          // Horizontal offset from fire centre, in canvas-fraction units.
          xOffset: (rng.nextDouble() - 0.5) * 0.08,
          // Per-ember horizontal sway frequency.
          swaySpeed: 1 + rng.nextInt(3),
          swayAmplitude: 0.005 + rng.nextDouble() * 0.012,
          swayPhase: rng.nextDouble() * math.pi * 2,
          // Lifetime as a fraction of the drift controller's period.
          // Smaller = quicker rise. Spread across 0.3..0.6 so embers don't
          // all arrive at the top at the same instant.
          lifetime: 0.30 + rng.nextDouble() * 0.30,
          riseFraction: 0.18 + rng.nextDouble() * 0.10,
          radiusPx: 0.8 + rng.nextDouble() * 1.4,
        ),
      );
    }
    return out;
  }

  // A short, continuous row of low buttes along the horizon. Drawn with the
  // hazy-purple "far" colour and `extendBelow: true` so the silhouette also
  // fills the midground band — this gives the scene a sense of distant
  // ground at the horizon, instead of leaving a flat sky-to-foreground jump.
  static final _MesaSilhouette _horizonRow = _MesaSilhouette(const [
    _Mesa(
      left: 0.00,
      right: 0.26,
      topY: _horizonY - 0.025,
      bottomY: _horizonY + 0.04,
      topWidthRatio: 0.50,
      topShift: 0.02,
    ),
    _Mesa(
      left: 0.22,
      right: 0.48,
      topY: _horizonY - 0.045,
      bottomY: _horizonY + 0.04,
      topWidthRatio: 0.55,
      topShift: -0.02,
    ),
    _Mesa(
      left: 0.44,
      right: 0.74,
      topY: _horizonY - 0.030,
      bottomY: _horizonY + 0.04,
      topWidthRatio: 0.52,
      topShift: 0.03,
    ),
    _Mesa(
      left: 0.70,
      right: 1.00,
      topY: _horizonY - 0.055,
      bottomY: _horizonY + 0.04,
      topWidthRatio: 0.58,
      topShift: -0.03,
    ),
  ]);

  // The mid mesa standing closer to the viewer on the left. Sits on the
  // foreground floor (bottomY = groundY); ~33% smaller than the right mesa
  // in both width and height so the two foreground forms don't read as
  // matching twins. Colour is shifted toward the near mesa's dark tone —
  // only the horizon row carries the hazy purple now.
  static final _MesaSilhouette _leftMesa = _MesaSilhouette(const [
    _Mesa(
      left: 0.10,
      right: 0.34,
      topY: _horizonY + 0.006,
      bottomY: _groundY,
      topWidthRatio: 0.50,
      topShift: 0.02,
    ),
  ]);

  // The foreground mesa on the right. Tallest of the three layers; its
  // base meets the ground line.
  static final _MesaSilhouette _rightMesa = _MesaSilhouette(const [
    _Mesa(
      left: 0.58,
      right: 0.98,
      topY: _horizonY - 0.13,
      bottomY: _groundY,
      topWidthRatio: 0.55,
      topShift: -0.04,
      roughness: 0.30,
    ),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintStars(canvas, size);
    _paintMoon(canvas, size);
    _paintHorizonGlow(canvas, size);
    _paintHorizonRow(canvas, size);
    _paintLeftMesa(canvas, size);
    _paintRightMesa(canvas, size);
    _paintGround(canvas, size);
    _paintFireGlow(canvas, size);
    _paintLogs(canvas, size);
    _paintFlames(canvas, size);
    _paintEmbers(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, _horizonY * size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0612),
            Color(0xFF1A1230),
            Color(0xFF3A1A38),
            Color(0xFF5A2030),
          ],
          stops: [0.0, 0.40, 0.78, 1.0],
        ).createShader(rect),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const coolStar = Color(0xFFE8ECFA);
    const warmStar = Color(0xFFFFD8A8);
    for (final star in _stars) {
      // Twinkle modulates alpha on a sine; amplitude is half the base alpha
      // so stars never blink out entirely.
      final phase =
          driftT * star.twinkleSpeed * math.pi * 2 + star.twinklePhase;
      final wobble = (math.sin(phase) + 1) / 2; // 0..1
      final alpha = (star.baseAlpha * (0.55 + 0.45 * wobble)).clamp(0.0, 1.0);
      final color = star.warm ? warmStar : coolStar;
      final centre = Offset(star.pos.dx * w, star.pos.dy * h);
      // Tiny halo for the brighter stars so they read as light, not just dots.
      if (star.radiusPx > 1.2) {
        canvas.drawCircle(
          centre,
          star.radiusPx * 2.2,
          Paint()
            ..color = color.withAlpha((alpha * 60).round())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawCircle(
        centre,
        star.radiusPx,
        Paint()..color = color.withAlpha((alpha * 255).round()),
      );
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Upper-right, comfortably inside the sky region.
    final centre = Offset(w * 0.78, h * 0.16);
    final r = math.min(w, h) * 0.055;

    // Soft halo behind the moon.
    canvas.drawCircle(
      centre,
      r * 2.4,
      Paint()
        ..color = const Color(0xFFFFE8C0).withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Full moon body in shadow — a faint dark disc that reads as a complete
    // circle behind the crescent (earthshine effect), slightly lighter than
    // the surrounding night sky.
    canvas.drawCircle(
      centre,
      r,
      Paint()..color = const Color(0xFF221A2C),
    );
    // A thin terminator highlight along the moon's outline gives the dark
    // body a soft rim so it reads as a sphere, not just a flat hole.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = const Color(0xFFE8D0A8).withAlpha(50),
    );

    // Lit crescent: path difference of the full disc minus an offset disc.
    // Whatever the cutout covers stays as the dark moon body underneath, so
    // the unlit portion remains a visible circle.
    final fullDisc = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: r));
    final cutoutDisc = Path()
      ..addOval(
        Rect.fromCircle(
          center: centre.translate(r * 0.42, -r * 0.08),
          radius: r * 0.92,
        ),
      );
    final crescent = Path.combine(
      PathOperation.difference,
      fullDisc,
      cutoutDisc,
    );
    canvas.drawPath(
      crescent,
      Paint()..color = const Color(0xFFF4E0B8),
    );
  }

  void _paintHorizonGlow(Canvas canvas, Size size) {
    // A warm wash sitting along the back horizon — gives the far mesas a
    // glowing rim, as if the last embers of dusk are still showing.
    final h = size.height;
    final band = h * 0.10;
    final horizonPx = _horizonY * h;
    final rect = Rect.fromLTRB(0, horizonPx - band, size.width, horizonPx + band);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE85A30).withAlpha(0),
            const Color(0xFFE85A30).withAlpha(85),
            const Color(0xFFE85A30).withAlpha(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
  }

  void _paintHorizonRow(Canvas canvas, Size size) {
    // Hazy purple silhouette + a midground band beneath it (extendBelow).
    final path = _horizonRow.buildPath(size, extendBelow: true);
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF2A1830),
    );
  }

  void _paintLeftMesa(Canvas canvas, Size size) {
    // Mid-distance: trapezoid only (no band), tone shifted toward the near
    // mesa so atmospheric perspective reads correctly — closer is darker.
    final path = _leftMesa.buildPath(size);
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF1A0E20),
    );
  }

  void _paintRightMesa(Canvas canvas, Size size) {
    // Foreground: trapezoid only, the darkest tone of the three layers.
    final path = _rightMesa.buildPath(size);
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF120814),
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      0,
      _groundY * size.height,
      size.width,
      size.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120814), Color(0xFF08040C)],
        ).createShader(rect),
    );
  }

  void _paintFireGlow(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(_fireBase.dx * w, _fireBase.dy * h);
    final r = math.min(w, h) * 0.30;
    // Glow breathes with the flicker so the surrounding scene pulses warm.
    final flickerPhase = math.sin(flickerT * math.pi * 2 * _glowMultiplier);
    final intensity = 0.65 + 0.20 * flickerPhase;

    canvas.drawCircle(
      centre,
      r * 1.1,
      Paint()
        ..color = const Color(0xFFFF7A2C).withAlpha((intensity * 90).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    canvas.drawCircle(
      centre.translate(0, -r * 0.10),
      r * 0.55,
      Paint()
        ..color = const Color(0xFFFFC070).withAlpha((intensity * 80).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  void _paintLogs(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(_fireBase.dx * w, _fireBase.dy * h);
    final logLength = math.min(w, h) * 0.085;
    final logThickness = logLength * 0.18;

    // Two logs crossed at the base of the fire — keep them visible and small.
    final logPaint = Paint()..color = const Color(0xFF1A0E0A);
    final emberPaint = Paint()
      ..color = const Color(0xFFFF6A22).withAlpha(160)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    void drawLog(double angleRad) {
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(angleRad);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: logLength,
        height: logThickness,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(logThickness / 2)),
        logPaint,
      );
      // Ember band along the top edge of the log.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(logThickness * 0.25),
          Radius.circular(logThickness / 3),
        ),
        emberPaint,
      );
      canvas.restore();
    }

    drawLog(-0.30);
    drawLog(0.30);
  }

  void _paintFlames(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(_fireBase.dx * w, _fireBase.dy * h);
    final flameHeight = math.min(w, h) * 0.16;
    final flameWidth = flameHeight * 0.55;

    // Three stacked flames: outer (broadest, dim red), middle (orange),
    // inner (yellow core). Each one's tip wavers on its own integer-rate
    // sine from `_flameMultipliers` so they flicker at independently
    // randomised speeds (max == the original cadence).
    _drawFlame(
      canvas,
      base: base,
      width: flameWidth * 1.10,
      height: flameHeight * 1.00,
      tipPhase: flickerT * math.pi * 2 * _flameMultipliers[0],
      sway: 0.012,
      color: const Color(0xFFD83820),
      blurSigma: 8,
    );
    _drawFlame(
      canvas,
      base: base,
      width: flameWidth * 0.78,
      height: flameHeight * 0.78,
      tipPhase:
          flickerT * math.pi * 2 * _flameMultipliers[1] + math.pi * 0.6,
      sway: 0.020,
      color: const Color(0xFFFF8A30),
      blurSigma: 4,
    );
    _drawFlame(
      canvas,
      base: base,
      width: flameWidth * 0.45,
      height: flameHeight * 0.55,
      tipPhase:
          flickerT * math.pi * 2 * _flameMultipliers[2] + math.pi * 1.3,
      sway: 0.028,
      color: const Color(0xFFFFE38A),
      blurSigma: 2,
    );
  }

  /// Draws one teardrop-shaped flame anchored at [base], reaching upward to
  /// [height]. The tip drifts side-to-side on a sine driven by [tipPhase];
  /// [sway] is the lateral amplitude as a fraction of the canvas width.
  void _drawFlame(
    Canvas canvas, {
    required Offset base,
    required double width,
    required double height,
    required double tipPhase,
    required double sway,
    required Color color,
    required double blurSigma,
  }) {
    final tipDx = math.sin(tipPhase) * (sway * 600);
    final tip = Offset(base.dx + tipDx, base.dy - height);
    final leftBase = Offset(base.dx - width / 2, base.dy);
    final rightBase = Offset(base.dx + width / 2, base.dy);
    // Mid-height swell — slightly wider than the base, so the flame reads as
    // teardrop rather than straight cone.
    final leftMidY = base.dy - height * 0.55;
    final rightMidY = base.dy - height * 0.55;
    final leftMid = Offset(base.dx - width * 0.62, leftMidY);
    final rightMid = Offset(base.dx + width * 0.62, rightMidY);

    final path = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..cubicTo(
        leftMid.dx,
        leftMid.dy,
        tip.dx - width * 0.20,
        tip.dy + height * 0.10,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        tip.dx + width * 0.20,
        tip.dy + height * 0.10,
        rightMid.dx,
        rightMid.dy,
        rightBase.dx,
        rightBase.dy,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
    );
  }

  void _paintEmbers(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(_fireBase.dx * w, _fireBase.dy * h);
    final fireHeight = math.min(w, h) * 0.16;

    for (final ember in _embers) {
      // Each ember's life position is (driftT + phaseOffset) % lifetime,
      // normalised to 0..1 over its lifetime. life=0 starts at the flame
      // tip; life=1 finishes at riseFraction of canvas height above the fire.
      final cycle = ((driftT + ember.phaseOffset) % ember.lifetime) /
          ember.lifetime;
      final riseDistance = ember.riseFraction * h;
      final cy = base.dy - fireHeight * 0.85 - cycle * riseDistance;
      final swayPhase =
          driftT * ember.swaySpeed * math.pi * 2 + ember.swayPhase;
      final swayDx = math.sin(swayPhase) * (ember.swayAmplitude * w);
      final cx = base.dx + ember.xOffset * w + swayDx;

      // Embers fade in at birth and out as they rise: a triangular envelope
      // peaking around mid-life.
      final envelope = (cycle < 0.15)
          ? cycle / 0.15
          : (1.0 - cycle);
      final alpha = (envelope.clamp(0.0, 1.0) * 0.95);

      // Colour shifts from yellow at the bottom to deep orange as they cool.
      final color = Color.lerp(
        const Color(0xFFFFD060),
        const Color(0xFFE85A20),
        cycle,
      )!;

      canvas.drawCircle(
        Offset(cx, cy),
        ember.radiusPx * 1.8,
        Paint()
          ..color = color.withAlpha((alpha * 80).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        ember.radiusPx,
        Paint()..color = color.withAlpha((alpha * 255).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CampfirePainter old) =>
      old.driftT != driftT || old.flickerT != flickerT;
}

class _Star {
  const _Star({
    required this.pos,
    required this.radiusPx,
    required this.baseAlpha,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.warm,
  });

  final Offset pos;
  final double radiusPx;
  final double baseAlpha;
  final int twinkleSpeed;
  final double twinklePhase;
  final bool warm;
}

class _Ember {
  const _Ember({
    required this.phaseOffset,
    required this.xOffset,
    required this.swaySpeed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.lifetime,
    required this.riseFraction,
    required this.radiusPx,
  });

  final double phaseOffset;
  final double xOffset;
  final int swaySpeed;
  final double swayAmplitude;
  final double swayPhase;
  final double lifetime;
  final double riseFraction;
  final double radiusPx;
}

/// Pre-computed mesa silhouettes. Each mesa is positioned explicitly in
/// canvas-fraction coords and scaled to the canvas at paint time.
class _MesaSilhouette {
  _MesaSilhouette(this._mesas);

  final List<_Mesa> _mesas;

  /// Builds the silhouette path.
  ///
  /// When [extendBelow] is true, the path also fills the band stretching
  /// across the canvas under the mesa bases — used by the horizon row so
  /// its colour doubles as the midground fill. When false, only the
  /// trapezoid shapes are filled (closing along bottomY between mesas),
  /// which is what a standalone mesa wants.
  Path buildPath(Size size, {bool extendBelow = false}) {
    final w = size.width;
    final h = size.height;
    final sorted = [..._mesas]..sort((a, b) => a.left.compareTo(b.left));

    final path = Path();
    if (extendBelow) {
      path.moveTo(-1, h + 1);
    }

    var first = true;
    for (final m in sorted) {
      final left = m.left * w;
      final right = m.right * w;
      final topY = m.topY * h;
      final bottomY = m.bottomY * h;
      final mesaH = bottomY - topY;
      final topWidth = (m.right - m.left) * m.topWidthRatio * w;
      final topCentre = (left + right) / 2 + m.topShift * w;
      final topLeft = topCentre - topWidth / 2;
      final topRight = topCentre + topWidth / 2;

      // Corner radius — softens the top edges. Capped so the rounding never
      // eats more than a fraction of the top edge or the mesa's height.
      final cornerR = math.max(
        1.0,
        math.min(
          math.min(topWidth * 0.22, mesaH * 0.18),
          math.min(topLeft - left, right - topRight) * 0.6,
        ),
      );
      // Jitter amplitude scales with mesa height so distortion reads at any
      // canvas size, but it's clamped low — the silhouette should still feel
      // like a clean mesa shape, just with eroded edges. `roughness` lets
      // foreground mesas dial back so they don't look noisier than the
      // distant ones.
      final jitter = math.min(mesaH * 0.018, 4.5) * m.roughness;
      // Stable seed derived from the mesa's position so the noise doesn't
      // shimmer between frames.
      final rng = math.Random(
        (m.left * 10000).round() ^ ((m.topY * 10000).round() << 1),
      );

      if (!extendBelow && first) {
        path.moveTo(left, bottomY);
      } else {
        path.lineTo(left, bottomY);
      }
      first = false;
      // Left slope up to the start of the top-left corner arc.
      _addJitteredEdge(
        path,
        Offset(left, bottomY),
        Offset(topLeft, topY + cornerR),
        jitter,
        rng,
      );
      // Rounded top-left corner.
      path.quadraticBezierTo(topLeft, topY, topLeft + cornerR, topY);
      // Top edge — slightly less jitter so the plateau still reads as flat.
      _addJitteredEdge(
        path,
        Offset(topLeft + cornerR, topY),
        Offset(topRight - cornerR, topY),
        jitter * 0.55,
        rng,
      );
      // Rounded top-right corner.
      path.quadraticBezierTo(topRight, topY, topRight, topY + cornerR);
      // Right slope down to the base.
      _addJitteredEdge(
        path,
        Offset(topRight, topY + cornerR),
        Offset(right, bottomY),
        jitter,
        rng,
      );
    }

    if (extendBelow) {
      path.lineTo(w + 1, h + 1);
    }
    path.close();
    return path;
  }

  /// Appends a jittered line from [a] to [b]. Each subdivision is offset
  /// perpendicular to the edge by a random amount up to [amp], tapering to
  /// zero at the endpoints so corners stay anchored.
  static void _addJitteredEdge(
    Path path,
    Offset a,
    Offset b,
    double amp,
    math.Random rng,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1.5) {
      path.lineTo(b.dx, b.dy);
      return;
    }
    final nx = -dy / len;
    final ny = dx / len;
    final segments = math.max(6, (len / 7).round());
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      final taper = math.sin(t * math.pi);
      final j = (rng.nextDouble() * 2 - 1) * amp * taper;
      path.lineTo(a.dx + dx * t + nx * j, a.dy + dy * t + ny * j);
    }
  }
}

class _Mesa {
  const _Mesa({
    required this.left,
    required this.right,
    required this.topY,
    required this.bottomY,
    required this.topWidthRatio,
    required this.topShift,
    this.roughness = 1.0,
  });

  final double left;
  final double right;
  final double topY;
  final double bottomY;
  final double topWidthRatio;
  final double topShift;
  // Per-mesa multiplier on edge jitter amplitude. The foreground mesa uses a
  // lower value so its silhouette stays crisper than the distant layers.
  final double roughness;
}
