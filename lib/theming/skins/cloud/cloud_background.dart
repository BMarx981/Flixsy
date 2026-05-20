import 'package:flutter/material.dart';

import 'cloud_theme.dart';

/// Slow, peaceful drift of soft clouds across a sky-blue gradient — the
/// backdrop for the `Cloud` skin. Self-contained: owns its ticker and isolates
/// repaints with a [RepaintBoundary].
class CloudBackground extends StatefulWidget {
  const CloudBackground({super.key});

  @override
  State<CloudBackground> createState() => _CloudBackgroundState();
}

class _CloudBackgroundState extends State<CloudBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A long cycle keeps the drift slow without dropping the frame rate.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
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
          painter: _CloudPainter(t: _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Cloud {
  const _Cloud({
    required this.baseX,
    required this.centerY,
    required this.size,
    required this.speed,
    required this.alpha,
  });

  /// Starting x within [_CloudPainter._range], 0..range.
  final double baseX;

  /// Vertical centre, fraction of canvas height.
  final double centerY;

  /// Overall puff scale, fraction of canvas width.
  final double size;

  /// How many full [_range]-width traversals per controller cycle.
  /// Must be a positive integer so position at t=1 matches t=0 — otherwise
  /// the controller's wrap shows up as a visible jump.
  final int speed;

  /// 0..1 base opacity, scaled before painting.
  final double alpha;
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.t});

  /// Normalised animation time (0..1, wraps).
  final double t;

  /// Horizontal travel range, in fractions of canvas width. Clouds wrap when
  /// they leave the right side and re-enter on the left; the 0.5 overshoot on
  /// each end keeps the wrap moment off-screen so it can't be seen.
  static const double _range = 2.0;
  static const double _overshoot = 0.5;

  // Puff layout inside one cloud, in units of [_Cloud.size]. Six overlapping
  // soft circles read as a fluffy, irregular cloud shape once blurred.
  static const List<Offset> _puffOffsets = [
    Offset(-0.55, 0.08),
    Offset(-0.30, -0.20),
    Offset(0.00, -0.30),
    Offset(0.28, -0.20),
    Offset(0.55, 0.05),
    Offset(-0.05, 0.14),
  ];
  static const List<double> _puffRadii = [
    0.30,
    0.38,
    0.42,
    0.36,
    0.32,
    0.44,
  ];

  static const List<_Cloud> _clouds = [
    _Cloud(baseX: 0.10, centerY: 0.22, size: 0.30, speed: 2, alpha: 0.92),
    _Cloud(baseX: 0.80, centerY: 0.55, size: 0.38, speed: 2, alpha: 0.88),
    _Cloud(baseX: 1.40, centerY: 0.18, size: 0.22, speed: 4, alpha: 0.78),
    _Cloud(baseX: 0.35, centerY: 0.80, size: 0.34, speed: 2, alpha: 0.85),
    _Cloud(baseX: 1.70, centerY: 0.42, size: 0.26, speed: 4, alpha: 0.70),
    _Cloud(baseX: 1.10, centerY: 0.92, size: 0.30, speed: 2, alpha: 0.65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sky gradient: a touch darker up top, paler near the horizon.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CloudTheme.skyTop, CloudTheme.skyBottom],
        ).createShader(rect),
    );

    for (final cloud in _clouds) {
      _paintCloud(canvas, size, cloud);
    }
  }

  void _paintCloud(Canvas canvas, Size size, _Cloud cloud) {
    final w = size.width;
    final h = size.height;

    // Wrap horizontally with overshoot so the discontinuous modulo step
    // happens while the cloud is fully off-screen.
    final pos = ((cloud.baseX + t * cloud.speed) % _range) - _overshoot;
    final cx = pos * w;
    final cy = cloud.centerY * h;
    final s = cloud.size * w;

    final body = Paint()
      ..color = CloudTheme.alpha(CloudTheme.cloud, cloud.alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // A slightly larger, dimmer halo gives each cloud a soft underside
    // shadow without committing to a hard shape.
    final halo = Paint()
      ..color = CloudTheme.alpha(CloudTheme.inkSoft, 0.10 * cloud.alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    for (var i = 0; i < _puffOffsets.length; i++) {
      final centre = Offset(
        cx + _puffOffsets[i].dx * s,
        cy + _puffOffsets[i].dy * s,
      );
      final radius = _puffRadii[i] * s;
      canvas.drawCircle(centre.translate(0, radius * 0.25), radius, halo);
      canvas.drawCircle(centre, radius, body);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudPainter old) => old.t != t;
}
