import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Country-bar interior backdrop for the `Honkytonk` skin: dim wood-plank
/// back wall, a row of warm pendant bulbs hanging across the top, a glowing
/// neon guitar sign centred on the back wall, soft cigarette-smoke haze
/// drifting horizontally, a wood-plank floor below a bar counter strip, a
/// felt cowboy hat resting on the counter, a row of bar stools along the
/// customer side, and two pool tables anchored at the canvas edges in the
/// foreground. The neon flickers on a fast controller; the smoke drifts on
/// a slow one — both are seeded so the scene is reproducible.
class HonkytonkBackground extends StatefulWidget {
  const HonkytonkBackground({super.key});

  @override
  State<HonkytonkBackground> createState() => _HonkytonkBackgroundState();
}

class _HonkytonkBackgroundState extends State<HonkytonkBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _flicker;

  @override
  void initState() {
    super.initState();
    // Slow controller drives smoke drift + bulb breath.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    // Fast controller drives the neon flicker. Period is the wrap; per-element
    // integer multipliers inside the painter pick how many full sine cycles
    // each phase completes per wrap, keeping the loop seamless.
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
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
          painter: _HonkytonkPainter(
            driftT: _drift.value,
            flickerT: _flicker.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _HonkytonkPainter extends CustomPainter {
  _HonkytonkPainter({required this.driftT, required this.flickerT});

  final double driftT;
  final double flickerT;

  // Canvas-fraction landmarks.
  static const double _ceilingY = 0.04;
  static const double _bulbY = 0.10;
  static const double _signTop = 0.20;
  static const double _signBottom = 0.46;
  static const double _counterTop = 0.78;
  static const double _floorTop = 0.84;

  static const int _flickerMultiplier = 8; // brief dip on every cycle
  static const int _bulbBreathMultiplier = 1; // gentle, once per drift wrap

  static final List<_Bulb> _bulbs = _buildBulbs();
  static final List<_SmokePuff> _smoke = _buildSmoke();
  static final List<_Plank> _floorPlanks = _buildFloorPlanks();
  static final List<_Plank> _wallPlanks = _buildWallPlanks();

  static List<_Bulb> _buildBulbs() {
    // Four bulbs evenly spaced across the upper band, each with a small phase
    // offset so they don't breathe in perfect lockstep.
    final out = <_Bulb>[];
    for (var i = 0; i < 4; i++) {
      final x = 0.18 + i * 0.21;
      out.add(_Bulb(x: x, phase: i * 0.42));
    }
    return out;
  }

  static List<_SmokePuff> _buildSmoke() {
    final rng = math.Random(31);
    final out = <_SmokePuff>[];
    for (var i = 0; i < 7; i++) {
      out.add(
        _SmokePuff(
          // Phase offset along the drift cycle.
          phaseOffset: rng.nextDouble(),
          // Vertical band — smoke hangs in the upper-mid region.
          y: 0.22 + rng.nextDouble() * 0.40,
          // Radius in canvas-fraction units.
          radius: 0.05 + rng.nextDouble() * 0.06,
          // Direction: +1 left-to-right, -1 right-to-left.
          direction: rng.nextBool() ? 1 : -1,
          // Speed multiplier (full cycles per drift wrap).
          speed: 1 + rng.nextInt(2),
          baseAlpha: 12 + rng.nextInt(14),
        ),
      );
    }
    return out;
  }

  static List<_Plank> _buildFloorPlanks() {
    final rng = math.Random(47);
    final out = <_Plank>[];
    var y = _floorTop;
    while (y < 1.0) {
      final h = 0.025 + rng.nextDouble() * 0.015;
      // Slight per-plank tone variation around mid-wood brown.
      final tone = 0.85 + rng.nextDouble() * 0.30;
      out.add(_Plank(y: y, height: h, tone: tone));
      y += h;
    }
    return out;
  }

  static List<_Plank> _buildWallPlanks() {
    // Vertical wood planks on the back wall (above the counter). Stored as
    // x-positions of seams between planks.
    final rng = math.Random(59);
    final out = <_Plank>[];
    var x = 0.0;
    while (x < 1.0) {
      final w = 0.08 + rng.nextDouble() * 0.05;
      final tone = 0.88 + rng.nextDouble() * 0.22;
      // For wall planks: `y` reused as `x`, `height` reused as `width`.
      out.add(_Plank(y: x, height: w, tone: tone));
      x += w;
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackWall(canvas, size);
    _paintWallPlanks(canvas, size);
    _paintCeiling(canvas, size);
    _paintNeonSign(canvas, size);
    _paintBulbCord(canvas, size);
    _paintBulbs(canvas, size);
    _paintSmoke(canvas, size);
    _paintBarCounter(canvas, size);
    _paintCowboyHat(canvas, size);
    _paintFloor(canvas, size);
    _paintBarStools(canvas, size);
    _paintPoolTables(canvas, size);
  }

  void _paintBackWall(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      _counterTop * size.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E0604),
            Color(0xFF1E100A),
            Color(0xFF2A1410),
            Color(0xFF1C0E08),
          ],
          stops: [0.0, 0.30, 0.70, 1.0],
        ).createShader(rect),
    );
  }

  void _paintWallPlanks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = _ceilingY * h;
    final bottom = _counterTop * h;
    final seam = Paint()
      ..color = const Color(0xFF0A0402).withAlpha(140)
      ..strokeWidth = 1.2;
    final highlight = Paint()
      ..color = const Color(0xFF3A1E12).withAlpha(60)
      ..strokeWidth = 0.8;

    for (final p in _wallPlanks) {
      final x = (p.y + p.height) * w;
      if (x >= w) continue;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), seam);
      canvas.drawLine(
        Offset(x + 1.2, top),
        Offset(x + 1.2, bottom),
        highlight,
      );
    }

    // Subtle horizontal vignette to suggest a wash of warm light across the
    // wall behind the sign — keeps the wood from reading as flat colour.
    final glowRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.30),
      width: w * 1.4,
      height: h * 0.45,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..color = const Color(0xFFFFB060).withAlpha(18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
  }

  void _paintCeiling(Canvas canvas, Size size) {
    // A thin ceiling band at the very top, slightly darker than the wall.
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      _ceilingY * size.height,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF080402));
  }

  void _paintBulbCord(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cordY = _ceilingY * h + 2;
    canvas.drawLine(
      Offset(0, cordY),
      Offset(w, cordY),
      Paint()
        ..color = const Color(0xFF0A0402)
        ..strokeWidth = 1.4,
    );
  }

  void _paintBulbs(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cordY = _ceilingY * h + 2;
    final bulbCentreY = _bulbY * h;
    final r = math.min(w, h) * 0.012;

    // Bulbs breathe with the slow drift controller; a tiny multiplier on the
    // fast flicker controller adds a subtle shimmer.
    final breathBase =
        math.sin(driftT * math.pi * 2 * _bulbBreathMultiplier);
    final shimmer = math.sin(flickerT * math.pi * 2 * 3);

    for (final bulb in _bulbs) {
      final cx = bulb.x * w;
      final phase = breathBase * math.cos(bulb.phase * math.pi);
      final intensity =
          (0.75 + 0.15 * phase + 0.05 * shimmer).clamp(0.40, 1.00);

      // Pendant wire from the ceiling cord down to the bulb.
      canvas.drawLine(
        Offset(cx, cordY),
        Offset(cx, bulbCentreY - r),
        Paint()
          ..color = const Color(0xFF120A06)
          ..strokeWidth = 1.2,
      );

      // Wide soft halo wash on the wall behind the bulb.
      canvas.drawCircle(
        Offset(cx, bulbCentreY),
        r * 6.0,
        Paint()
          ..color =
              const Color(0xFFFFC070).withAlpha((intensity * 28).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
      // Tighter inner halo.
      canvas.drawCircle(
        Offset(cx, bulbCentreY),
        r * 2.6,
        Paint()
          ..color =
              const Color(0xFFFFD888).withAlpha((intensity * 95).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Bulb body — a small warm disc with a brighter core.
      canvas.drawCircle(
        Offset(cx, bulbCentreY),
        r,
        Paint()..color = const Color(0xFFFFE0A0),
      );
      canvas.drawCircle(
        Offset(cx - r * 0.25, bulbCentreY - r * 0.25),
        r * 0.45,
        Paint()..color = const Color(0xFFFFF6D8),
      );
      // Small dark socket cap above the bulb.
      final socket = Rect.fromCenter(
        center: Offset(cx, bulbCentreY - r * 1.05),
        width: r * 1.3,
        height: r * 0.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(socket, Radius.circular(r * 0.2)),
        Paint()..color = const Color(0xFF1A0E08),
      );
    }
  }

  void _paintNeonSign(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Flicker: a periodic dip — most of the cycle is fully lit, with a short
    // window where the sign briefly browns out, like a tired neon tube.
    final flickerPhase = (flickerT * _flickerMultiplier) % 1.0;
    final dim = flickerPhase < 0.04
        ? 0.45 + (flickerPhase / 0.04) * 0.55
        : (flickerPhase < 0.08
            ? 1.0 - ((flickerPhase - 0.04) / 0.04) * 0.55
            : 1.0);
    // Always-on shimmer on the lit core.
    final shimmer =
        1.0 + 0.03 * math.sin(flickerT * math.pi * 2 * 11);
    final intensity = (dim * shimmer).clamp(0.0, 1.0);

    // Guitar geometry. The sign band runs _signTop..._signBottom; we reserve
    // a slice at the top for the headstock, then the neck, then the body.
    final centreX = w * 0.46;
    final signBandHeight = (_signBottom - _signTop) * h;
    final headTopY = _signTop * h;
    final headHeight = signBandHeight * 0.14;
    final headBottomY = headTopY + headHeight;
    final bodyTopY = _signTop * h + signBandHeight * 0.40;
    final bodyBottomY = _signBottom * h;
    final bodyHeight = bodyBottomY - bodyTopY;
    // Bouts intentionally sized so they overlap only slightly — that's what
    // gives the body a visible waist instead of reading as one fat blob.
    // Upper bout is ~75% of the lower bout, matching a natural acoustic.
    final upperRadius = bodyHeight * 0.26;
    final lowerRadius = bodyHeight * 0.34;
    // Upper bout sits ~1/3 of the way down the body so the neck visibly
    // enters the bout from above instead of barely grazing its top edge.
    // Lower bout stays anchored near the bottom so the body still tapers
    // wide-at-the-bottom like a real acoustic.
    final upperCentre = Offset(centreX, bodyTopY + bodyHeight * 0.33);
    final lowerCentre = Offset(centreX, bodyBottomY - bodyHeight * 0.28);

    // Sound hole — placed above the lower bout's centre, near where a real
    // guitar's hole sits relative to the body.
    final holeCentre =
        Offset(centreX, lowerCentre.dy - lowerRadius * 0.35);
    final holeRadius = lowerRadius * 0.26;

    // Neck stretching straight up from the upper bout to the headstock.
    final neckBaseY = upperCentre.dy - upperRadius * 0.95;
    final neckTopY = headBottomY;
    final neckHalfWidth = upperRadius * 0.18;
    final neck = Path()
      ..moveTo(centreX - neckHalfWidth, neckBaseY)
      ..lineTo(centreX - neckHalfWidth, neckTopY)
      ..lineTo(centreX + neckHalfWidth, neckTopY)
      ..lineTo(centreX + neckHalfWidth, neckBaseY)
      ..close();

    // Headstock — a paddle that flares outward from the neck and dips into a
    // shallow V-notch at the top. Tuning-peg pips sit along the sides.
    final headBaseHalfW = neckHalfWidth * 1.05;
    final headTopHalfW = neckHalfWidth * 2.8;
    final notchDepth = headHeight * 0.22;
    final head = Path()
      ..moveTo(centreX - headBaseHalfW, headBottomY)
      ..lineTo(centreX - headTopHalfW, headTopY + headHeight * 0.18)
      ..quadraticBezierTo(
        centreX - headTopHalfW * 0.95,
        headTopY,
        centreX - headTopHalfW * 0.55,
        headTopY + 1,
      )
      ..quadraticBezierTo(
        centreX - headTopHalfW * 0.20,
        headTopY + notchDepth * 0.4,
        centreX,
        headTopY + notchDepth,
      )
      ..quadraticBezierTo(
        centreX + headTopHalfW * 0.20,
        headTopY + notchDepth * 0.4,
        centreX + headTopHalfW * 0.55,
        headTopY + 1,
      )
      ..quadraticBezierTo(
        centreX + headTopHalfW * 0.95,
        headTopY,
        centreX + headTopHalfW,
        headTopY + headHeight * 0.18,
      )
      ..lineTo(centreX + headBaseHalfW, headBottomY)
      ..close();

    // Guitar body outline: union of two ellipses, drawn as a single stroke.
    final upperOval = Path()
      ..addOval(
        Rect.fromCircle(center: upperCentre, radius: upperRadius),
      );
    final lowerOval = Path()
      ..addOval(
        Rect.fromCircle(center: lowerCentre, radius: lowerRadius),
      );
    final bodyPath = Path.combine(PathOperation.union, upperOval, lowerOval);

    const neonColor = Color(0xFFFF3A78);
    const neonCore = Color(0xFFFFD8E6);

    // Outer wide glow (drawn first, blurred). Two passes — broad and soft,
    // then narrow and stronger — give the neon "wet" look.
    final wideGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = neonColor.withAlpha((intensity * 110).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final mediumGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = neonColor.withAlpha((intensity * 200).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = neonCore.withAlpha((intensity * 230).round());

    canvas.drawPath(bodyPath, wideGlow);
    canvas.drawPath(bodyPath, mediumGlow);
    canvas.drawPath(bodyPath, core);

    canvas.drawPath(neck, wideGlow);
    canvas.drawPath(neck, mediumGlow);
    canvas.drawPath(neck, core);

    canvas.drawPath(head, wideGlow);
    canvas.drawPath(head, mediumGlow);
    canvas.drawPath(head, core);

    // Tuning-peg pips — two on each side of the headstock, drawn as small
    // neon-rim rings so they read as pegs rather than solid dots.
    final pegStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = neonCore.withAlpha((intensity * 220).round());
    final pegGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = neonColor.withAlpha((intensity * 180).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final pegRadius = headHeight * 0.10;
    for (final t in const [0.40, 0.72]) {
      final y = headTopY + headHeight * t;
      // Horizontal placement: interpolate between top-flare and base widths,
      // then nudge inward so the pegs sit just inside the silhouette edge.
      final flareHalfW =
          headBaseHalfW + (headTopHalfW - headBaseHalfW) * (1 - t);
      final pegOffset = flareHalfW - pegRadius * 1.6;
      canvas.drawCircle(Offset(centreX - pegOffset, y), pegRadius, pegGlow);
      canvas.drawCircle(Offset(centreX - pegOffset, y), pegRadius, pegStroke);
      canvas.drawCircle(Offset(centreX + pegOffset, y), pegRadius, pegGlow);
      canvas.drawCircle(Offset(centreX + pegOffset, y), pegRadius, pegStroke);
    }

    // Sound hole — a solid neon ring (smaller).
    canvas.drawCircle(holeCentre, holeRadius, wideGlow);
    canvas.drawCircle(holeCentre, holeRadius, mediumGlow);
    canvas.drawCircle(holeCentre, holeRadius, core);

    // Three strings running down the neck and across the body to the bridge.
    final stringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = neonCore.withAlpha((intensity * 180).round());
    final bridgeY = lowerCentre.dy + lowerRadius * 0.55;
    for (final dx in const [-3.0, 0.0, 3.0]) {
      canvas.drawLine(
        Offset(centreX + dx, headBottomY),
        Offset(centreX + dx, bridgeY),
        stringPaint,
      );
    }

    // Bridge bar across the strings near the bottom of the body.
    final bridgeRect = Rect.fromCenter(
      center: Offset(centreX, bridgeY),
      width: lowerRadius * 0.55,
      height: 2.5,
    );
    canvas.drawRect(bridgeRect, core);
  }

  void _paintSmoke(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final puff in _smoke) {
      // Travel one full canvas width per drift wrap (times speed). The puff
      // wraps around — uses modulo so it re-enters from the opposite edge.
      final progress =
          ((driftT * puff.speed) + puff.phaseOffset) % 1.0;
      final start = puff.direction > 0 ? -puff.radius : 1 + puff.radius;
      final end = puff.direction > 0 ? 1 + puff.radius : -puff.radius;
      final x = (start + (end - start) * progress) * w;
      // A gentle vertical bob.
      final bob =
          math.sin((progress + puff.phaseOffset) * math.pi * 2) * h * 0.01;
      final cy = puff.y * h + bob;
      canvas.drawCircle(
        Offset(x, cy),
        puff.radius * math.min(w, h),
        Paint()
          ..color = const Color(0xFFE8D8C0).withAlpha(puff.baseAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
  }

  void _paintBarCounter(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTRB(
      0,
      _counterTop * h,
      w,
      _floorTop * h,
    );
    // The counter — a darker wood band with a glossy highlight on top.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0C06),
            Color(0xFF3A1C10),
            Color(0xFF1E100A),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
    // Highlight stripe along the front edge.
    canvas.drawRect(
      Rect.fromLTRB(0, _counterTop * h, w, _counterTop * h + 2.5),
      Paint()..color = const Color(0xFFC97A2C).withAlpha(80),
    );
  }

  void _paintCowboyHat(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final counterTopY = _counterTop * h;

    // Sits off-centre on the bar counter so it isn't masked by the remote.
    final hatCentreX = w * 0.80;
    final brimY = counterTopY + 2;

    final brimWidth = math.min(w, h) * 0.14;
    final brimHeight = brimWidth * 0.20;
    final crownWidth = brimWidth * 0.46;
    final crownHeight = brimWidth * 0.40;

    const hatBrown = Color(0xFF3E2418);
    const hatHighlight = Color(0xFF5A3624);
    const hatShadow = Color(0xFF1A0A04);
    const hatBand = Color(0xFF08030A);

    // Crown — rounded with the classic cattleman crease down the centre.
    final crownRect = Rect.fromCenter(
      center: Offset(hatCentreX, brimY - crownHeight * 0.46),
      width: crownWidth,
      height: crownHeight,
    );
    final crownPath = Path()
      ..moveTo(crownRect.left, crownRect.bottom)
      ..lineTo(
        crownRect.left + crownWidth * 0.08,
        crownRect.top + crownHeight * 0.32,
      )
      ..quadraticBezierTo(
        crownRect.left + crownWidth * 0.18,
        crownRect.top,
        crownRect.left + crownWidth * 0.34,
        crownRect.top + crownHeight * 0.10,
      )
      ..quadraticBezierTo(
        crownRect.center.dx,
        crownRect.top + crownHeight * 0.32,
        crownRect.right - crownWidth * 0.34,
        crownRect.top + crownHeight * 0.10,
      )
      ..quadraticBezierTo(
        crownRect.right - crownWidth * 0.18,
        crownRect.top,
        crownRect.right - crownWidth * 0.08,
        crownRect.top + crownHeight * 0.32,
      )
      ..lineTo(crownRect.right, crownRect.bottom)
      ..close();
    canvas.drawPath(
      crownPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hatHighlight, hatBrown, hatShadow],
          stops: [0.0, 0.55, 1.0],
        ).createShader(crownRect),
    );

    // Hatband — thin dark strip at the base of the crown.
    final bandRect = Rect.fromLTWH(
      crownRect.left,
      crownRect.bottom - crownHeight * 0.20,
      crownWidth,
      crownHeight * 0.13,
    );
    canvas.drawRect(bandRect, Paint()..color = hatBand);
    // Tiny silver buckle on the band.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(crownRect.center.dx, bandRect.center.dy),
        width: crownWidth * 0.10,
        height: bandRect.height * 0.75,
      ),
      Paint()..color = const Color(0xFFD4B070),
    );

    // Brim — ellipse with shadowed underside and brown top.
    final brimRect = Rect.fromCenter(
      center: Offset(hatCentreX, brimY),
      width: brimWidth,
      height: brimHeight,
    );
    canvas.drawOval(brimRect, Paint()..color = hatShadow);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        brimRect.left,
        brimRect.top,
        brimRect.right,
        brimRect.center.dy,
      ),
    );
    canvas.drawOval(brimRect, Paint()..color = hatBrown);
    canvas.restore();
    // Rim highlight on the front edge.
    canvas.drawOval(
      brimRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = hatHighlight.withAlpha(180),
    );

    // Warm wash from the overhead bulbs landing on the crown.
    canvas.drawCircle(
      Offset(hatCentreX, crownRect.top + crownHeight * 0.25),
      crownWidth * 0.42,
      Paint()
        ..color = const Color(0xFFFFB060).withAlpha(46)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _paintFloor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorRect = Rect.fromLTRB(0, _floorTop * h, w, h);
    canvas.drawRect(
      floorRect,
      Paint()..color = const Color(0xFF0E0604),
    );

    // Plank stripes — alternating tones with thin dark seams.
    const baseColor = Color(0xFF2A1610);
    final seamPaint = Paint()
      ..color = const Color(0xFF060302).withAlpha(160)
      ..strokeWidth = 1.2;
    for (final plank in _floorPlanks) {
      final top = plank.y * h;
      final bottom = (plank.y + plank.height) * h;
      if (top >= h) continue;
      final rect = Rect.fromLTRB(0, top, w, math.min(bottom, h));
      final r = (baseColor.r * plank.tone).clamp(0.0, 1.0);
      final g = (baseColor.g * plank.tone).clamp(0.0, 1.0);
      final b = (baseColor.b * plank.tone).clamp(0.0, 1.0);
      canvas.drawRect(
        rect,
        Paint()..color = Color.from(alpha: 1, red: r, green: g, blue: b),
      );
      canvas.drawLine(
        Offset(0, top),
        Offset(w, top),
        seamPaint,
      );
    }
  }

  void _paintBarStools(Canvas canvas, Size size) {
    // Stools sit at the customer side of the bar. The cushions line up with
    // the counter top; posts run down through the floor band. Spaced so the
    // outer pair frames the visible counter and the inner pair sits just
    // beyond where the foreground pool tables crop in.
    for (final x in const [0.10, 0.32, 0.68, 0.92]) {
      _paintBarStool(canvas, size, xFraction: x);
    }
  }

  void _paintBarStool(
    Canvas canvas,
    Size size, {
    required double xFraction,
  }) {
    final w = size.width;
    final h = size.height;
    final cx = xFraction * w;

    final floorBaseY = h * 0.955;
    final seatRadius = math.min(w, h) * 0.040;
    final seatThickness = seatRadius * 0.55;
    // Seat sits midway between the counter line and the floor — a slightly
    // shortened stool reads better against the foreground than one whose
    // cushion floats up at counter height.
    final seatCentreY = h * 0.82;

    final cushionRect = Rect.fromCenter(
      center: Offset(cx, seatCentreY),
      width: seatRadius * 2,
      height: seatThickness * 2.0,
    );

    // Soft shadow just under the cushion.
    canvas.drawOval(
      cushionRect.shift(Offset(0, seatThickness * 0.5)),
      Paint()
        ..color = const Color(0xFF000000).withAlpha(90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Leather cushion with an upper-left highlight to read as 3D.
    canvas.drawOval(
      cushionRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [Color(0xFF7E3820), Color(0xFF2C1208)],
        ).createShader(cushionRect),
    );
    // Dark rim around the cushion edge — gives the seat a defined silhouette.
    canvas.drawOval(
      cushionRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0xFF120804).withAlpha(220),
    );

    // Vertical post — metal rod from cushion bottom to floor base.
    final postWidth = math.min(w, h) * 0.011;
    final postTop = seatCentreY + seatThickness * 0.85;
    final postRect = Rect.fromLTWH(
      cx - postWidth * 0.5,
      postTop,
      postWidth,
      floorBaseY - postTop,
    );
    canvas.drawRect(
      postRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0A0604), Color(0xFF3A2614), Color(0xFF0A0604)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(postRect),
    );

    // Footring — brass ring around the post, partway down.
    final ringY = postTop + (floorBaseY - postTop) * 0.55;
    final ringRect = Rect.fromCenter(
      center: Offset(cx, ringY),
      width: seatRadius * 1.55,
      height: seatRadius * 0.32,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF8A5828),
    );
    // Highlight along the near (lower-front) arc of the ring.
    canvas.drawArc(
      ringRect,
      math.pi * 0.10,
      math.pi * 0.80,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = const Color(0xFFD0A060).withAlpha(190),
    );

    // Flared floor base.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, floorBaseY),
        width: seatRadius * 1.7,
        height: seatRadius * 0.45,
      ),
      Paint()..color = const Color(0xFF080302),
    );
  }

  void _paintPoolTables(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Both tables are anchored at the canvas edges with their outer halves
    // off-screen — they frame the foreground without competing with the
    // remote in the middle. The right one sits slightly larger and lower so
    // the two read as different tables rather than a mirrored pair.
    _paintPoolTable(
      canvas,
      Offset(0, h * 0.91),
      width: w * 0.58,
    );
    _paintPoolTable(
      canvas,
      Offset(w, h * 0.94),
      width: w * 0.66,
    );
  }

  void _paintPoolTable(
    Canvas canvas,
    Offset centre, {
    required double width,
  }) {
    final cx = centre.dx;
    final cy = centre.dy;
    final tableHeight = width * 0.50;

    // Foreshortening — far edge narrower than near edge.
    final topHalfW = width * 0.42;
    final bottomHalfW = width * 0.50;
    final topY = cy - tableHeight * 0.5;
    final bottomY = cy + tableHeight * 0.5;
    final fullRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: 2 * bottomHalfW,
      height: tableHeight,
    );

    // Wood rails — outer trapezoid with a soft top-edge highlight.
    final railPath = Path()
      ..moveTo(cx - topHalfW, topY)
      ..lineTo(cx + topHalfW, topY)
      ..lineTo(cx + bottomHalfW, bottomY)
      ..lineTo(cx - bottomHalfW, bottomY)
      ..close();
    canvas.drawPath(
      railPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2614), Color(0xFF2E1408)],
        ).createShader(fullRect),
    );
    canvas.drawLine(
      Offset(cx - topHalfW, topY),
      Offset(cx + topHalfW, topY),
      Paint()
        ..color = const Color(0xFF8A4820).withAlpha(160)
        ..strokeWidth = 1.4,
    );

    // Felt inset.
    final inset = width * 0.06;
    final feltTopHalfW = topHalfW - inset * 0.85;
    final feltBottomHalfW = bottomHalfW - inset;
    final feltTopY = topY + inset * 0.6;
    final feltBottomY = bottomY - inset * 0.5;
    final feltPath = Path()
      ..moveTo(cx - feltTopHalfW, feltTopY)
      ..lineTo(cx + feltTopHalfW, feltTopY)
      ..lineTo(cx + feltBottomHalfW, feltBottomY)
      ..lineTo(cx - feltBottomHalfW, feltBottomY)
      ..close();
    canvas.drawPath(
      feltPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF083014),
            Color(0xFF1A5028),
            Color(0xFF082610),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(fullRect),
    );

    // Pockets — six total: four corners + two side pockets.
    final pocketR = inset * 0.55;
    final pocketPaint = Paint()..color = const Color(0xFF030101);
    final pockets = <Offset>[
      Offset(cx - topHalfW + inset * 0.4, topY + inset * 0.5),
      Offset(cx + topHalfW - inset * 0.4, topY + inset * 0.5),
      Offset(cx - bottomHalfW + inset * 0.4, bottomY - inset * 0.45),
      Offset(cx + bottomHalfW - inset * 0.4, bottomY - inset * 0.45),
      Offset(cx - (topHalfW + bottomHalfW) * 0.5, cy),
      Offset(cx + (topHalfW + bottomHalfW) * 0.5, cy),
    ];
    for (final p in pockets) {
      canvas.drawCircle(p, pocketR, pocketPaint);
    }

    // Racked balls — proper triangle near the top end of the table.
    final ballR = inset * 0.48;
    final rackTopY = feltTopY + tableHeight * 0.20;
    const rackColors = <Color>[
      Color(0xFFE0C020), // 1 yellow
      Color(0xFF1838A0), // 2 blue
      Color(0xFFE03020), // 3 red
      Color(0xFF6A1090), // 4 purple
      Color(0xFFE57020), // 5 orange
      Color(0xFF108C40), // 6 green
      Color(0xFF8A2018), // 7 maroon
      Color(0xFF101010), // 8 black
      Color(0xFFD8C040), // 9
      Color(0xFF2848B0), // 10
    ];
    var idx = 0;
    for (var row = 0; row < 4; row++) {
      final rowY = rackTopY + row * ballR * 1.85;
      for (var col = 0; col <= row; col++) {
        if (idx >= rackColors.length) break;
        final offsetX = (col - row / 2.0) * ballR * 2.1;
        canvas.drawCircle(
          Offset(cx + offsetX, rowY),
          ballR,
          Paint()..color = rackColors[idx],
        );
        idx++;
      }
    }

    // Cue ball near the bottom end of the table.
    final cueOffset = Offset(cx - tableHeight * 0.18, feltBottomY - tableHeight * 0.18);
    canvas.drawCircle(
      cueOffset,
      ballR,
      Paint()..color = const Color(0xFFF4ECD8),
    );
    canvas.drawCircle(
      cueOffset.translate(-ballR * 0.32, -ballR * 0.32),
      ballR * 0.30,
      Paint()..color = const Color(0xFFFFFFFF).withAlpha(180),
    );

    // Overhead-lamp pool on the felt.
    canvas.drawCircle(
      Offset(cx, cy - tableHeight * 0.08),
      width * 0.22,
      Paint()
        ..color = const Color(0xFFFFD080).withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(covariant _HonkytonkPainter old) =>
      old.driftT != driftT || old.flickerT != flickerT;
}

class _Bulb {
  const _Bulb({required this.x, required this.phase});

  final double x;
  final double phase;
}

class _SmokePuff {
  const _SmokePuff({
    required this.phaseOffset,
    required this.y,
    required this.radius,
    required this.direction,
    required this.speed,
    required this.baseAlpha,
  });

  final double phaseOffset;
  final double y;
  final double radius;
  final int direction;
  final int speed;
  final int baseAlpha;
}

class _Plank {
  const _Plank({
    required this.y,
    required this.height,
    required this.tone,
  });

  final double y;
  final double height;
  final double tone;
}
