import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Night skyline backdrop for the `Cityscape` skin: a deep indigo sky with
/// scattered stars and a soft moon, three parallax bands of building
/// silhouettes (far → mid → near) speckled with lit windows, and a thin
/// street-glow band along the very bottom. A slow drift controller breathes
/// the city haze and nudges the moon halo; a fast controller blinks the
/// aircraft warning lights atop the tallest towers and flickers a handful of
/// windows. Everything is seeded so the scene is reproducible.
class CityscapeBackground extends StatefulWidget {
  const CityscapeBackground({super.key});

  @override
  State<CityscapeBackground> createState() => _CityscapeBackgroundState();
}

class _CityscapeBackgroundState extends State<CityscapeBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    // Slow controller: haze breath + moon shimmer + the occasional window
    // shift. Long period so the night feels still.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    // Fast controller: drives the red aircraft warning lights (one full blink
    // per ~1.4 s) and the brief window flickers.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
      _blink.stop();
    } else {
      if (!_drift.isAnimating) _drift.repeat();
      if (!_blink.isAnimating) _blink.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_drift, _blink]),
        builder: (_, _) => CustomPaint(
          painter: _CityscapePainter(
            driftT: _drift.value,
            blinkT: _blink.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CityscapePainter extends CustomPainter {
  _CityscapePainter({required this.driftT, required this.blinkT});

  final double driftT;
  final double blinkT;

  // Canvas-fraction landmarks. The horizon sits a little above middle so the
  // city occupies the lower portion and the sky breathes above.
  static const double _horizonY = 0.62;
  static const double _streetTop = 0.965;

  static const int _aircraftBlinkMultiplier = 4;

  static final List<_Star> _stars = _buildStars();
  static final List<_Building> _farBuildings = _buildBuildings(
    seed: 11,
    count: 18,
    minWidth: 0.04,
    maxWidth: 0.08,
    minHeight: 0.10,
    maxHeight: 0.20,
    baseY: _horizonY,
    windowDensity: 0.35,
  );
  static final List<_Building> _midBuildings = _buildBuildings(
    seed: 23,
    count: 12,
    minWidth: 0.06,
    maxWidth: 0.12,
    minHeight: 0.16,
    maxHeight: 0.30,
    baseY: _horizonY + 0.02,
    windowDensity: 0.55,
  );
  static final List<_Building> _nearBuildings = _buildBuildings(
    seed: 37,
    count: 8,
    minWidth: 0.10,
    maxWidth: 0.18,
    minHeight: 0.22,
    maxHeight: 0.40,
    baseY: _horizonY + 0.05,
    windowDensity: 0.75,
  );

  static List<_Star> _buildStars() {
    final rng = math.Random(7);
    final out = <_Star>[];
    for (var i = 0; i < 60; i++) {
      out.add(
        _Star(
          x: rng.nextDouble(),
          // Stars only appear in the upper sky band, well above the skyline.
          y: rng.nextDouble() * 0.55,
          radius: 0.4 + rng.nextDouble() * 1.1,
          baseAlpha: 80 + rng.nextInt(120),
          phase: rng.nextDouble(),
        ),
      );
    }
    return out;
  }

  static List<_Building> _buildBuildings({
    required int seed,
    required int count,
    required double minWidth,
    required double maxWidth,
    required double minHeight,
    required double maxHeight,
    required double baseY,
    required double windowDensity,
  }) {
    final rng = math.Random(seed);
    final out = <_Building>[];
    // March across the canvas placing buildings shoulder-to-shoulder with a
    // small random gap. Overrun the right edge so the parallax band fills.
    var x = -minWidth;
    while (x < 1.1) {
      final width = minWidth + rng.nextDouble() * (maxWidth - minWidth);
      final height = minHeight + rng.nextDouble() * (maxHeight - minHeight);
      // A handful of buildings get a rooftop antenna; only tall ones get the
      // blinking aircraft warning light.
      final hasAntenna = rng.nextDouble() < 0.35;
      final isTall = height > (minHeight + maxHeight) * 0.55;
      final hasBeacon = isTall && rng.nextDouble() < 0.55;
      // Window grid — pre-rolled so the windows are static between frames
      // (with a few flickering exceptions picked at paint time).
      final windowCols = math.max(2, (width / 0.018).round());
      final windowRows = math.max(3, (height / 0.024).round());
      final lit = <bool>[];
      final amber = <bool>[];
      for (var i = 0; i < windowCols * windowRows; i++) {
        lit.add(rng.nextDouble() < windowDensity);
        // ~30% of lit windows are warm amber; the rest are cool cyan-white.
        amber.add(rng.nextDouble() < 0.30);
      }
      out.add(
        _Building(
          x: x,
          width: width,
          top: baseY - height,
          windowCols: windowCols,
          windowRows: windowRows,
          lit: lit,
          amber: amber,
          hasAntenna: hasAntenna,
          hasBeacon: hasBeacon,
          beaconPhase: rng.nextDouble(),
          flickerSeed: rng.nextInt(1 << 20),
        ),
      );
      x += width + rng.nextDouble() * 0.005;
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintStars(canvas, size);
    _paintMoon(canvas, size);
    _paintHorizonGlow(canvas, size);
    _paintBuildingLayer(canvas, size, _farBuildings, _BuildingDepth.far);
    _paintBuildingLayer(canvas, size, _midBuildings, _BuildingDepth.mid);
    _paintBuildingLayer(canvas, size, _nearBuildings, _BuildingDepth.near);
    _paintStreetGlow(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050812),
            Color(0xFF0A1024),
            Color(0xFF142244),
            Color(0xFF2A2C58),
          ],
          stops: [0.0, 0.45, 0.80, 1.0],
        ).createShader(rect),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // A gentle twinkle: each star's alpha bobs on its own phase against the
    // slow drift controller. Tiny amplitude so it reads as breathing, not
    // strobing.
    for (final s in _stars) {
      final twinkle =
          0.85 + 0.15 * math.sin((driftT + s.phase) * math.pi * 2 * 3);
      final alpha = (s.baseAlpha * twinkle).clamp(0, 255).round();
      canvas.drawCircle(
        Offset(s.x * w, s.y * h),
        s.radius,
        Paint()..color = const Color(0xFFE8ECF8).withAlpha(alpha),
      );
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w * 0.78, h * 0.18);
    final r = math.min(w, h) * 0.045;
    // The moon halo breathes very slowly with the drift controller.
    final breath = 0.85 + 0.15 * math.sin(driftT * math.pi * 2);

    // Outer halo wash.
    canvas.drawCircle(
      centre,
      r * 4.5,
      Paint()
        ..color = const Color(0xFFEFEAD8).withAlpha((breath * 18).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
    // Inner halo.
    canvas.drawCircle(
      centre,
      r * 2.0,
      Paint()
        ..color = const Color(0xFFEFEAD8).withAlpha((breath * 60).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Moon disc.
    canvas.drawCircle(
      centre,
      r,
      Paint()..color = const Color(0xFFEFEAD8),
    );
    // Crater hint — a subtle off-centre darker disc gives the moon shape.
    canvas.drawCircle(
      centre.translate(r * 0.25, -r * 0.05),
      r * 0.92,
      Paint()..color = const Color(0xFFFFF6E0),
    );
    // Two tiny craters.
    canvas.drawCircle(
      centre.translate(-r * 0.35, r * 0.20),
      r * 0.12,
      Paint()..color = const Color(0xFFDCD3B8).withAlpha(180),
    );
    canvas.drawCircle(
      centre.translate(r * 0.10, r * 0.35),
      r * 0.08,
      Paint()..color = const Color(0xFFDCD3B8).withAlpha(160),
    );
  }

  void _paintHorizonGlow(Canvas canvas, Size size) {
    // A warm haze along the horizon — light pollution from the city below.
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTRB(
      0,
      (_horizonY - 0.10) * h,
      w,
      (_horizonY + 0.05) * h,
    );
    final breath = 0.85 + 0.15 * math.sin(driftT * math.pi * 2 * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            const Color(0xFFFFB060).withAlpha((40 * breath).round()),
            const Color(0xFFFF8040).withAlpha((28 * breath).round()),
          ],
          stops: const [0.0, 0.70, 1.0],
        ).createShader(rect),
    );
  }

  void _paintBuildingLayer(
    Canvas canvas,
    Size size,
    List<_Building> buildings,
    _BuildingDepth depth,
  ) {
    final w = size.width;
    final h = size.height;
    final bodyColor = switch (depth) {
      _BuildingDepth.far => const Color(0xFF0A0E1C),
      _BuildingDepth.mid => const Color(0xFF060912),
      _BuildingDepth.near => const Color(0xFF02040A),
    };
    final windowSize = switch (depth) {
      _BuildingDepth.far => 1.1,
      _BuildingDepth.mid => 1.6,
      _BuildingDepth.near => 2.2,
    };
    final windowAlpha = switch (depth) {
      _BuildingDepth.far => 140,
      _BuildingDepth.mid => 200,
      _BuildingDepth.near => 235,
    };

    for (final b in buildings) {
      final left = b.x * w;
      final right = (b.x + b.width) * w;
      final top = b.top * h;
      // Body — extends below the canvas so adjacent layers stack cleanly.
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, h),
        Paint()..color = bodyColor,
      );

      // A subtle vertical edge highlight on the left of each near/mid
      // silhouette, suggesting moonlight catching the building's corner.
      if (depth != _BuildingDepth.far) {
        canvas.drawRect(
          Rect.fromLTWH(left, top, 1.2, h - top),
          Paint()
            ..color = const Color(0xFF2A3454).withAlpha(
              depth == _BuildingDepth.near ? 90 : 50,
            ),
        );
      }

      // Window grid. Inset a small margin so windows don't touch edges.
      final usableW = (b.width * w) - windowSize * 2.4;
      final usableH = (h - top) - windowSize * 2.4;
      if (usableW <= 0 || usableH <= 0) continue;
      final colStep = usableW / b.windowCols;
      final rowStep = usableH / b.windowRows;
      // Stop drawing windows once we reach the lower 8% of the canvas — the
      // street glow handles that strip.
      final maxWindowY = h * (_streetTop - 0.005);

      for (var row = 0; row < b.windowRows; row++) {
        for (var col = 0; col < b.windowCols; col++) {
          final idx = row * b.windowCols + col;
          if (!b.lit[idx]) continue;
          final wx = left + windowSize * 1.2 + col * colStep + colStep * 0.5;
          final wy = top + windowSize * 1.2 + row * rowStep + rowStep * 0.5;
          if (wy > maxWindowY) continue;

          // Twinkle: each window breathes on its own slow two-harmonic sine,
          // with the per-window phase and rate derived deterministically from
          // the building's seed plus window index. Two harmonics at unrelated
          // rates means no obvious periodicity — the skyline shimmers gently
          // rather than snapping on and off.
          final phaseA = ((b.flickerSeed + idx * 131) & 0xFFFF) / 0xFFFF;
          final phaseB = ((b.flickerSeed + idx * 257 + 7) & 0xFFFF) / 0xFFFF;
          // driftT wraps every 30s; rate ~3–7 gives cycles in the 4–10s range.
          final rate = 3.0 + phaseA * 4.0;
          final wave =
              math.sin((driftT * rate + phaseA) * math.pi * 2) * 0.55 +
              math.sin((driftT * rate * 0.7 + phaseB) * math.pi * 2) * 0.45;
          final dim = (0.78 + 0.22 * wave).clamp(0.30, 1.0);

          final color = b.amber[idx]
              ? const Color(0xFFFFC062)
              : const Color(0xFFB8E0FF);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(wx, wy),
              width: windowSize,
              height: windowSize * 1.4,
            ),
            Paint()
              ..color = color.withAlpha((windowAlpha * dim).round()),
          );
          // A short halo for near-layer windows so they read as glowing
          // sources, not flat pixels.
          if (depth == _BuildingDepth.near) {
            canvas.drawCircle(
              Offset(wx, wy),
              windowSize * 1.6,
              Paint()
                ..color = color.withAlpha((40 * dim).round())
                ..maskFilter =
                    const MaskFilter.blur(BlurStyle.normal, 2.4),
            );
          }
        }
      }

      // Antenna + aircraft warning beacon on the tallest near/mid buildings.
      if (b.hasAntenna && depth != _BuildingDepth.far) {
        final cx = (left + right) / 2;
        final antennaTop =
            top - (depth == _BuildingDepth.near ? 14.0 : 8.0);
        canvas.drawLine(
          Offset(cx, top),
          Offset(cx, antennaTop),
          Paint()
            ..color = const Color(0xFF1A2238)
            ..strokeWidth = depth == _BuildingDepth.near ? 1.6 : 1.2,
        );
        if (b.hasBeacon) {
          // Blink: roughly half-second on, half-second off, with the
          // per-building phase offset so they don't sync.
          final phase = (blinkT * _aircraftBlinkMultiplier + b.beaconPhase)
              % 1.0;
          final lit = phase < 0.18;
          if (lit) {
            final beaconRadius =
                depth == _BuildingDepth.near ? 2.4 : 1.8;
            canvas.drawCircle(
              Offset(cx, antennaTop),
              beaconRadius * 3.0,
              Paint()
                ..color = const Color(0xFFFF3040).withAlpha(110)
                ..maskFilter =
                    const MaskFilter.blur(BlurStyle.normal, 6),
            );
            canvas.drawCircle(
              Offset(cx, antennaTop),
              beaconRadius,
              Paint()..color = const Color(0xFFFF5060),
            );
          }
        }
      }
    }
  }

  void _paintStreetGlow(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // A thin warm band along the very bottom — sodium-vapour street lighting
    // bleeding up between the foreground buildings.
    final rect = Rect.fromLTRB(0, _streetTop * h, w, h);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF02040A));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFA040).withAlpha(70),
            const Color(0x00000000),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CityscapePainter old) =>
      old.driftT != driftT || old.blinkT != blinkT;
}

enum _BuildingDepth { far, mid, near }

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseAlpha,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final int baseAlpha;
  final double phase;
}

class _Building {
  const _Building({
    required this.x,
    required this.width,
    required this.top,
    required this.windowCols,
    required this.windowRows,
    required this.lit,
    required this.amber,
    required this.hasAntenna,
    required this.hasBeacon,
    required this.beaconPhase,
    required this.flickerSeed,
  });

  final double x;
  final double width;
  final double top;
  final int windowCols;
  final int windowRows;
  final List<bool> lit;
  final List<bool> amber;
  final bool hasAntenna;
  final bool hasBeacon;
  final double beaconPhase;
  final int flickerSeed;
}
