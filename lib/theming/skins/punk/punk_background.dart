import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Graffitied-alley backdrop for the `Punk` skin: a dark brick wall with
/// uneven mortar, two torn band posters stapled crookedly to the wall, a
/// scatter of spray-paint splatters, a hot-magenta Flixsy sparkle-star tag
/// in the upper-centre, slow paint drips running below the tag, and a
/// rough concrete gutter strip along the bottom edge. Everything is seeded
/// so the scene is reproducible.
class PunkBackground extends StatefulWidget {
  const PunkBackground({super.key});

  @override
  State<PunkBackground> createState() => _PunkBackgroundState();
}

class _PunkBackgroundState extends State<PunkBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    // Slow controller — long, lazy period. Drives the paint-drip growth.
    // The star tag is static spray paint, so no fast controller is needed.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (_, _) => CustomPaint(
          painter: _PunkPainter(driftT: _drift.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PunkPainter extends CustomPainter {
  _PunkPainter({required this.driftT});

  final double driftT;

  // Canvas-fraction landmarks.
  static const double _gutterTop = 0.92;

  // Brick grid sizing (canvas-fraction units).
  static const double _brickRowHeight = 0.040;
  static const double _brickColWidth = 0.090;

  static final List<_Splatter> _splatters = _buildSplatters();
  static final List<_Drip> _drips = _buildDrips();
  static final List<_Poster> _posters = _buildPosters();
  static final List<_Brick> _brickChips = _buildBrickChips();
  static final List<_SprayDot> _tagSprayDots = _buildTagSprayDots();

  static List<_Splatter> _buildSplatters() {
    final rng = math.Random(13);
    final out = <_Splatter>[];
    for (var i = 0; i < 16; i++) {
      out.add(
        _Splatter(
          x: rng.nextDouble(),
          y: 0.08 + rng.nextDouble() * 0.72,
          radius: 0.008 + rng.nextDouble() * 0.018,
          // ~half are magenta, ~third are acid-yellow, rest are bone-white.
          color: rng.nextDouble() < 0.5
              ? const Color(0xFFFF1F8C)
              : (rng.nextDouble() < 0.55
                  ? const Color(0xFFD6F33A)
                  : const Color(0xFFEAE2D6)),
          // A handful of small satellite droplets per blob.
          satellites: List.generate(
            3 + rng.nextInt(4),
            (_) => Offset(
              (rng.nextDouble() - 0.5) * 0.06,
              (rng.nextDouble() - 0.5) * 0.06,
            ),
          ),
        ),
      );
    }
    return out;
  }

  static List<_Drip> _buildDrips() {
    final rng = math.Random(29);
    final out = <_Drip>[];
    // Drips cluster below the bottom tip of the star tag, fanning out
    // slightly so they don't form a straight line.
    for (var i = 0; i < 7; i++) {
      out.add(
        _Drip(
          x: 0.42 + rng.nextDouble() * 0.16,
          startY: 0.39 + rng.nextDouble() * 0.04,
          maxLength: 0.04 + rng.nextDouble() * 0.10,
          width: 1.6 + rng.nextDouble() * 1.6,
          phase: rng.nextDouble(),
        ),
      );
    }
    return out;
  }

  static List<_Poster> _buildPosters() {
    // Two crooked posters — one upper-left, one mid-right — with stripes of
    // contrasting colour and a torn corner. Tilt is in radians.
    return const [
      _Poster(
        x: 0.06,
        y: 0.10,
        width: 0.22,
        height: 0.16,
        tilt: -0.10,
        background: Color(0xFFEAE2D6),
        accent: Color(0xFFFF1F8C),
        bandLines: 3,
        tornCorner: _Corner.topRight,
        text: 'PUNK',
      ),
      _Poster(
        x: 0.70,
        y: 0.50,
        width: 0.24,
        height: 0.18,
        tilt: 0.08,
        background: Color(0xFFD6F33A),
        accent: Color(0xFF08060A),
        bandLines: 4,
        tornCorner: _Corner.bottomLeft,
        text: 'RIOT',
      ),
    ];
  }

  static List<_SprayDot> _buildTagSprayDots() {
    // Pre-rolled scatter of small dots along the Flixsy sparkle-star tag's
    // outline — the can's overspray. Positions are in r-units (where r is the
    // tag's reference radius at paint time), matching the geometry built in
    // `_paintStarTag` so the cloud lines up with the silhouette.
    final rng = math.Random(83);
    final out = <_SprayDot>[];

    void addBezierDots(
      Offset p0,
      Offset p1,
      Offset p2,
      Offset p3,
      int count,
      double spread,
    ) {
      for (var i = 0; i < count; i++) {
        final t = rng.nextDouble();
        final mt = 1.0 - t;
        // Point on the cubic Bezier.
        final point = p0 * (mt * mt * mt) +
            p1 * (3 * mt * mt * t) +
            p2 * (3 * mt * t * t) +
            p3 * (t * t * t);
        // Tangent — its perpendicular drives the overspray offset.
        final tangent = (p1 - p0) * (3 * mt * mt) +
            (p2 - p1) * (6 * mt * t) +
            (p3 - p2) * (3 * t * t);
        final len = tangent.distance;
        if (len < 1e-6) continue;
        final perp = Offset(-tangent.dy, tangent.dx) / len;
        // Bias to one side so the cloud feels hand-shaken, not even.
        final off = (rng.nextDouble() - 0.45) * spread * 2;
        out.add(
          _SprayDot(
            dx: point.dx + perp.dx * off,
            dy: point.dy + perp.dy * off,
            size: 0.012 + rng.nextDouble() * 0.038,
            alpha: 130 + rng.nextInt(95),
          ),
        );
      }
    }

    // 4-point sparkle star — sharp tips at distance `tip` along the four
    // cardinal axes, with a deeply-concave Bezier "waist" at distance `waist`
    // between adjacent tips. Mirrors assets/images/flixsy_logo.svg.
    const tip = 1.20;
    const waist = 0.146;
    const spread = 0.10;
    const top = Offset(0, -tip);
    const right = Offset(tip, 0);
    const bottom = Offset(0, tip);
    const left = Offset(-tip, 0);
    const ctrlTopRight1 = Offset(0, -waist);
    const ctrlTopRight2 = Offset(waist, 0);
    const ctrlRightBottom1 = Offset(waist, 0);
    const ctrlRightBottom2 = Offset(0, waist);
    const ctrlBottomLeft1 = Offset(0, waist);
    const ctrlBottomLeft2 = Offset(-waist, 0);
    const ctrlLeftTop1 = Offset(-waist, 0);
    const ctrlLeftTop2 = Offset(0, -waist);
    addBezierDots(top, ctrlTopRight1, ctrlTopRight2, right, 60, spread);
    addBezierDots(
      right,
      ctrlRightBottom1,
      ctrlRightBottom2,
      bottom,
      60,
      spread,
    );
    addBezierDots(bottom, ctrlBottomLeft1, ctrlBottomLeft2, left, 60, spread);
    addBezierDots(left, ctrlLeftTop1, ctrlLeftTop2, top, 60, spread);

    return out;
  }

  static List<_Brick> _buildBrickChips() {
    // A handful of chipped/cracked bricks so the wall doesn't feel like a
    // perfect grid.
    final rng = math.Random(41);
    final out = <_Brick>[];
    for (var i = 0; i < 18; i++) {
      out.add(
        _Brick(
          x: rng.nextDouble(),
          y: rng.nextDouble() * _gutterTop,
          // 0 = chip on the corner, 1 = crack across the face.
          kind: rng.nextInt(2),
          // Tone variation darkening (or barely lightening) the brick.
          tone: 0.72 + rng.nextDouble() * 0.20,
        ),
      );
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBricks(canvas, size);
    _paintBrickImperfections(canvas, size);
    _paintSplatters(canvas, size);
    _paintPosters(canvas, size);
    _paintStarTag(canvas, size);
    _paintDrips(canvas, size);
    _paintGutter(canvas, size);
  }

  void _paintBricks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base wall fill — gradient gives a hint of side lighting so the wall
    // doesn't read as flat colour.
    final wallRect = Rect.fromLTWH(0, 0, w, _gutterTop * h);
    canvas.drawRect(
      wallRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A0E0F),
            Color(0xFF3E1418),
            Color(0xFF1E0A0C),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(wallRect),
    );

    // Brick faces — alternate-offset rows. Slight per-brick tone variation
    // gives the wall depth.
    final brickPaint = Paint();
    final mortarBetween = Paint()
      ..color = const Color(0xFF0A0405)
      ..strokeWidth = 1.4;
    final mortarHighlight = Paint()
      ..color = const Color(0xFF4A1E20).withAlpha(80)
      ..strokeWidth = 0.6;

    final brickH = _brickRowHeight * h;
    final brickW = _brickColWidth * w;
    final rng = math.Random(101);
    var rowIndex = 0;
    for (var y = 0.0; y < _gutterTop * h; y += brickH) {
      final isOffset = rowIndex.isOdd;
      final xStart = isOffset ? -brickW / 2 : 0.0;
      for (var x = xStart; x < w; x += brickW) {
        final tone = 0.86 + rng.nextDouble() * 0.30;
        brickPaint.color = Color.from(
          alpha: 1,
          red: (0.36 * tone).clamp(0.10, 0.55),
          green: (0.12 * tone).clamp(0.05, 0.25),
          blue: (0.14 * tone).clamp(0.05, 0.25),
        );
        final brickRect = Rect.fromLTWH(
          x + 1.0,
          y + 1.0,
          brickW - 2.0,
          brickH - 2.0,
        );
        canvas.drawRect(brickRect, brickPaint);
        // Subtle warm highlight along the top of each brick.
        canvas.drawLine(
          Offset(brickRect.left, brickRect.top),
          Offset(brickRect.right, brickRect.top),
          mortarHighlight,
        );
      }
      // Horizontal mortar seam.
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        mortarBetween,
      );
      // Vertical mortar seams for this row.
      final vStart = isOffset ? -brickW / 2 : 0.0;
      for (var x = vStart; x <= w; x += brickW) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + brickH),
          mortarBetween,
        );
      }
      rowIndex++;
    }
  }

  void _paintBrickImperfections(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = Paint()..color = const Color(0xFF0A0405).withAlpha(220);
    final crack = Paint()
      ..color = const Color(0xFF0A0405).withAlpha(180)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final b in _brickChips) {
      final x = b.x * w;
      final y = b.y * h;
      if (b.kind == 0) {
        // Chip — a small irregular triangle missing from a brick face.
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + 6, y - 2)
          ..lineTo(x + 4, y + 5)
          ..close();
        canvas.drawPath(path, dark);
      } else {
        // Crack — a short zigzag line.
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + 6, y + 2)
          ..lineTo(x + 10, y - 1)
          ..lineTo(x + 18, y + 3);
        canvas.drawPath(path, crack);
      }
    }
  }

  void _paintSplatters(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = math.min(w, h);
    for (final s in _splatters) {
      final cx = s.x * w;
      final cy = s.y * h;
      // Soft outer halo so the splatter looks slightly wet against the wall.
      canvas.drawCircle(
        Offset(cx, cy),
        s.radius * base * 1.6,
        Paint()
          ..color = s.color.withAlpha(40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Main blob.
      canvas.drawCircle(
        Offset(cx, cy),
        s.radius * base,
        Paint()..color = s.color.withAlpha(230),
      );
      // Satellite droplets.
      for (final sat in s.satellites) {
        canvas.drawCircle(
          Offset(cx + sat.dx * base, cy + sat.dy * base),
          s.radius * base * (0.18 + 0.10 * sat.dx.abs() * 8),
          Paint()..color = s.color.withAlpha(210),
        );
      }
    }
  }

  void _paintPosters(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final p in _posters) {
      canvas.save();
      final cx = (p.x + p.width / 2) * w;
      final cy = (p.y + p.height / 2) * h;
      canvas.translate(cx, cy);
      canvas.rotate(p.tilt);
      canvas.translate(-cx, -cy);

      final rect = Rect.fromLTWH(
        p.x * w,
        p.y * h,
        p.width * w,
        p.height * h,
      );

      // Drop-shadow behind poster.
      canvas.drawRect(
        rect.translate(2, 3),
        Paint()
          ..color = Colors.black.withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Build a torn-corner clip so the poster has one frayed edge.
      final tornPath = _tornPosterPath(rect, p.tornCorner);
      canvas.save();
      canvas.clipPath(tornPath);

      // Poster background.
      canvas.drawRect(rect, Paint()..color = p.background);
      // Diagonal contrast bands across the poster — quick way to evoke
      // band-flyer aesthetic without text rendering.
      final bandPaint = Paint()..color = p.accent.withAlpha(180);
      final bandHeight = rect.height / (p.bandLines * 2.0);
      for (var i = 0; i < p.bandLines; i++) {
        final top = rect.top + i * (rect.height / p.bandLines);
        canvas.drawRect(
          Rect.fromLTWH(rect.left, top, rect.width, bandHeight),
          bandPaint,
        );
      }
      // Stamped text block in the centre — a chunky block of the accent
      // colour with the poster background letter holes punched through.
      final textBlock = Rect.fromCenter(
        center: rect.center,
        width: rect.width * 0.7,
        height: rect.height * 0.34,
      );
      canvas.drawRect(textBlock, Paint()..color = p.accent);
      _stencilText(canvas, textBlock, p.text, p.background);

      canvas.restore();

      // Two staples — small dark slashes at the upper corners.
      final staple = Paint()
        ..color = const Color(0xFF101010)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(rect.left + 6, rect.top + 4),
        Offset(rect.left + 12, rect.top + 4),
        staple,
      );
      canvas.drawLine(
        Offset(rect.right - 12, rect.top + 4),
        Offset(rect.right - 6, rect.top + 4),
        staple,
      );

      canvas.restore();
    }
  }

  Path _tornPosterPath(Rect rect, _Corner corner) {
    // Build a poster rectangle whose target corner is replaced by a small
    // jagged tear. The other three corners are clean.
    final path = Path();
    final tearDepthX = rect.width * 0.12;
    final tearDepthY = rect.height * 0.12;
    switch (corner) {
      case _Corner.topRight:
        path
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right - tearDepthX, rect.top)
          ..lineTo(rect.right - tearDepthX * 0.5, rect.top + tearDepthY * 0.3)
          ..lineTo(rect.right - tearDepthX * 0.85, rect.top + tearDepthY * 0.6)
          ..lineTo(rect.right - tearDepthX * 0.25, rect.top + tearDepthY * 0.9)
          ..lineTo(rect.right, rect.top + tearDepthY)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
      case _Corner.bottomLeft:
        path
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left + tearDepthX, rect.bottom)
          ..lineTo(rect.left + tearDepthX * 0.5, rect.bottom - tearDepthY * 0.3)
          ..lineTo(rect.left + tearDepthX * 0.85, rect.bottom - tearDepthY * 0.6)
          ..lineTo(rect.left + tearDepthX * 0.25, rect.bottom - tearDepthY * 0.9)
          ..lineTo(rect.left, rect.bottom - tearDepthY)
          ..close();
    }
    return path;
  }

  void _stencilText(Canvas canvas, Rect block, String text, Color holeColor) {
    // A blocky stencil suggestion of the poster text — we paint solid bars
    // for each letter and notch them with the poster background colour so
    // the letters read as cut-out shapes without doing real glyph layout.
    if (text.isEmpty) return;
    final letterCount = text.length;
    final letterWidth = block.width / letterCount;
    final letterPadding = letterWidth * 0.15;
    final letterRectW = letterWidth - letterPadding * 2;
    final holePaint = Paint()..color = holeColor;
    for (var i = 0; i < letterCount; i++) {
      final letterRect = Rect.fromLTWH(
        block.left + i * letterWidth + letterPadding,
        block.top + block.height * 0.18,
        letterRectW,
        block.height * 0.64,
      );
      // Punch a central horizontal slit so the bar reads as a chunky letter.
      canvas.drawRect(
        Rect.fromLTWH(
          letterRect.left + letterRect.width * 0.20,
          letterRect.top + letterRect.height * 0.40,
          letterRect.width * 0.60,
          letterRect.height * 0.20,
        ),
        holePaint,
      );
    }
  }

  void _paintStarTag(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w * 0.50, h * 0.28);
    final r = math.min(w, h) * 0.085;

    const tagColor = Color(0xFFFF1F8C);

    // 4-point sparkle star — sharp tips 1.2r out along the four cardinal
    // axes, with a deeply-concave Bezier waist (control points at 0.146r)
    // between adjacent tips. Mirrors assets/images/flixsy_logo.svg, sized to
    // match the geometry sampled in `_buildTagSprayDots` so the overspray
    // cloud aligns with the silhouette.
    const tip = 1.20;
    const waist = 0.146;
    final cx = centre.dx;
    final cy = centre.dy;
    final star = Path()
      ..moveTo(cx, cy - tip * r)
      ..cubicTo(
        cx, cy - waist * r,
        cx + waist * r, cy,
        cx + tip * r, cy,
      )
      ..cubicTo(
        cx + waist * r, cy,
        cx, cy + waist * r,
        cx, cy + tip * r,
      )
      ..cubicTo(
        cx, cy + waist * r,
        cx - waist * r, cy,
        cx - tip * r, cy,
      )
      ..cubicTo(
        cx - waist * r, cy,
        cx, cy - waist * r,
        cx, cy - tip * r,
      )
      ..close();

    // Soft outer halo — low alpha, blurred — suggests paint bleeding into
    // the brick texture around the silhouette's edge.
    canvas.drawPath(
      star,
      Paint()
        ..color = tagColor.withAlpha(60)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );
    // Main fill — slightly translucent so the brick texture shows faintly.
    canvas.drawPath(
      star,
      Paint()..color = tagColor.withAlpha(232),
    );

    // Overspray — scattered dots along the star outline, pre-rolled in
    // r-units so the cloud is stable across frames and resizes cleanly.
    final dotPaint = Paint();
    for (final dot in _tagSprayDots) {
      dotPaint.color = tagColor.withAlpha(dot.alpha);
      canvas.drawCircle(
        centre + Offset(dot.dx * r, dot.dy * r),
        dot.size * r,
        dotPaint,
      );
    }
  }

  void _paintDrips(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Each drip runs a one-shot cycle: extend from 0 → full length, hold at
    // full length while the alpha fades out, then reset invisible. No
    // shrinking — paint never travels back up. Per-drip phase offset keeps
    // the cluster from cycling in lockstep.
    for (final d in _drips) {
      final cyclePhase = (driftT + d.phase) % 1.0;

      double length;
      double alphaFraction;
      if (cyclePhase < 0.30) {
        // Growth: 0 → maxLength. A touch of ease-in so the drop accelerates
        // as it falls, matching gravity rather than linear extension.
        final t = cyclePhase / 0.30;
        length = d.maxLength * (t * t * 0.5 + t * 0.5);
        alphaFraction = 1.0;
      } else if (cyclePhase < 0.95) {
        // Hold at full length while alpha fades linearly.
        length = d.maxLength;
        alphaFraction = 1.0 - (cyclePhase - 0.30) / 0.65;
      } else {
        // Reset window — invisible, ready to start fresh.
        continue;
      }
      if (alphaFraction <= 0.005) continue;

      final top = d.startY * h;
      final bottom = (d.startY + length) * h;
      final x = d.x * w;
      // Drip line.
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..color = const Color(0xFFFF1F8C).withAlpha(
            (200 * alphaFraction).round(),
          )
          ..strokeWidth = d.width,
      );
      // Bead at the tip — a small round droplet, slightly wider than the
      // line so it reads as a hanging drop.
      canvas.drawCircle(
        Offset(x, bottom),
        d.width * 1.15,
        Paint()
          ..color = const Color(0xFFFF1F8C).withAlpha(
            (255 * alphaFraction).round(),
          ),
      );
      canvas.drawCircle(
        Offset(x - d.width * 0.4, bottom - d.width * 0.4),
        d.width * 0.45,
        Paint()
          ..color = const Color(0xFFFFD8E6).withAlpha(
            (255 * alphaFraction).round(),
          ),
      );
    }
  }

  void _paintGutter(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTRB(0, _gutterTop * h, w, h);
    // Rough dark concrete.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A171C),
            Color(0xFF0E0C10),
          ],
        ).createShader(rect),
    );
    // A grime line where the wall meets the gutter.
    canvas.drawRect(
      Rect.fromLTWH(0, _gutterTop * h - 1.4, w, 2.8),
      Paint()..color = const Color(0xFF050304),
    );
    // A handful of small dark specks to suggest debris.
    final rng = math.Random(67);
    for (var i = 0; i < 22; i++) {
      final px = rng.nextDouble() * w;
      final py = _gutterTop * h + rng.nextDouble() * (h - _gutterTop * h);
      canvas.drawCircle(
        Offset(px, py),
        0.6 + rng.nextDouble() * 0.9,
        Paint()..color = const Color(0xFF050304).withAlpha(220),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PunkPainter old) => old.driftT != driftT;
}

enum _Corner { topRight, bottomLeft }

class _Splatter {
  const _Splatter({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.satellites,
  });

  final double x;
  final double y;
  final double radius;
  final Color color;
  final List<Offset> satellites;
}

class _Drip {
  const _Drip({
    required this.x,
    required this.startY,
    required this.maxLength,
    required this.width,
    required this.phase,
  });

  final double x;
  final double startY;
  final double maxLength;
  final double width;
  final double phase;
}

class _Poster {
  const _Poster({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.tilt,
    required this.background,
    required this.accent,
    required this.bandLines,
    required this.tornCorner,
    required this.text,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double tilt;
  final Color background;
  final Color accent;
  final int bandLines;
  final _Corner tornCorner;
  final String text;
}

class _Brick {
  const _Brick({
    required this.x,
    required this.y,
    required this.kind,
    required this.tone,
  });

  final double x;
  final double y;
  final int kind;
  final double tone;
}

class _SprayDot {
  const _SprayDot({
    required this.dx,
    required this.dy,
    required this.size,
    required this.alpha,
  });

  // Position relative to the tag centre, in units of the tag radius.
  final double dx;
  final double dy;
  // Dot radius, also in units of the tag radius.
  final double size;
  final int alpha;
}
