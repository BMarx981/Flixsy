import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/router/app_router.dart';
import 'package:flixsy/features/device_discovery/providers/device_discovery_provider.dart';

@RoutePage()
class DeviceDiscoveryScreen extends ConsumerWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceDiscoveryProvider);
    final notifier = ref.read(deviceDiscoveryProvider.notifier);

    ref.listen<DiscoveryState>(deviceDiscoveryProvider, (prev, next) {
      // Navigate to remote once a device connects successfully.
      if (next.connectedDevice != null && prev?.connectedDevice == null) {
        context.router.replace(const HomeRoute());
      }
      // Surface connection failures as a snackbar.
      if (next.failure != null && next.failure != prev?.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failureMessage(next.failure!)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const _Header(),
              const SizedBox(height: 20),
              if (state.pairing != null) ...[
                _PairingBanner(
                  request: state.pairing!,
                  deviceName:
                      _deviceNameFor(state, state.pairing!.deviceId) ??
                      context.l10n.discoveryDeviceFallbackName,
                  onSubmitCode: notifier.submitPairingCode,
                ),
                const SizedBox(height: 20),
              ],
              Expanded(
                child: state.status == DiscoveryStatus.error
                    ? _ErrorBody(onRetry: notifier.retry)
                    : _RadarView(
                        devices: state.devices,
                        connectingDeviceId: state.connectingDeviceId,
                        isConnecting: state.isConnecting,
                        onConnect: notifier.connectToDevice,
                      ),
              ),
              const SizedBox(height: 16),
              _StatusFooter(
                status: state.status,
                deviceCount: state.devices.length,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.discoveryHeaderTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.discoveryHeaderSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white54,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─── Status footer (device count + spinner) ──────────────────────────────────

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({required this.status, required this.deviceCount});

  final DiscoveryStatus status;
  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        Text(
          context.l10n.discoveryDevicesFound(deviceCount),
          style: theme.textTheme.labelMedium?.copyWith(
            color: primary,
            letterSpacing: 0.8,
          ),
        ),
        if (status == DiscoveryStatus.scanning) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Error body ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.discoveryErrorTitle,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.discoveryErrorBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(context.l10n.discoveryRetryButton),
          ),
        ],
      ),
    );
  }
}

// ─── Radar view ──────────────────────────────────────────────────────────────

/// Maximum normalized radius (0..1) at which a target can be placed; keeps
/// dots from kissing the outer ring.
const double _targetMaxRadius = 0.86;

/// Minimum normalized radius — avoids stacking everything on the center.
const double _targetMinRadius = 0.18;

/// Minimum pixel distance between two target dots.
const double _targetMinSeparationPx = 70;

/// Attempts to find a non-overlapping slot before falling back to the last
/// candidate. Higher = better packing but more work; 80 is plenty for ≤12 TVs.
const int _placementAttempts = 80;

class _RadarView extends StatefulWidget {
  const _RadarView({
    required this.devices,
    required this.connectingDeviceId,
    required this.isConnecting,
    required this.onConnect,
  });

  final List<TvDevice> devices;
  final String? connectingDeviceId;
  final bool isConnecting;
  final ValueChanged<TvDevice> onConnect;

  @override
  State<_RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<_RadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  // Cached pixel positions per device id. Cleared when the radar size changes.
  final Map<String, Offset> _positions = {};
  double? _cachedRadarSize;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  // Lay out new devices into free slots, preserving positions of devices that
  // were already placed. Stable across rebuilds within a single discovery
  // session unless the radar resizes.
  void _layoutTargets(double radarSize, List<TvDevice> devices) {
    if (_cachedRadarSize != radarSize) {
      _positions.clear();
      _cachedRadarSize = radarSize;
    }
    final currentIds = {for (final d in devices) d.id};
    _positions.removeWhere((id, _) => !currentIds.contains(id));

    final center = radarSize / 2;
    final maxR = radarSize / 2 - 2;

    for (final device in devices) {
      if (_positions.containsKey(device.id)) continue;
      _positions[device.id] = _findSlot(device.id, center, maxR);
    }
  }

  Offset _findSlot(String id, double center, double maxRadiusPx) {
    // Linear congruential PRNG seeded by the device id so attempts are
    // deterministic per device but explore the full disk if rejected.
    var seed = id.hashCode & 0x7FFFFFFF;
    late Offset candidate;
    for (var attempt = 0; attempt < _placementAttempts; attempt++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      final a = ((seed >> 8) & 0xFFFF) / 0xFFFF;
      final r = ((seed >> 16) & 0xFFFF) / 0xFFFF;
      final angle = a * 2 * math.pi;
      final radiusNorm =
          _targetMinRadius + r * (_targetMaxRadius - _targetMinRadius);
      candidate = Offset(
        center + maxRadiusPx * radiusNorm * math.cos(angle),
        center + maxRadiusPx * radiusNorm * math.sin(angle),
      );
      var ok = true;
      for (final placed in _positions.values) {
        if ((candidate - placed).distance < _targetMinSeparationPx) {
          ok = false;
          break;
        }
      }
      if (ok) return candidate;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        _layoutTargets(size, widget.devices);
        final center = size / 2;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                final sweepAngle = _sweep.value * 2 * math.pi;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RadarBackgroundPainter(
                          color: color,
                          sweepAngle: sweepAngle,
                        ),
                      ),
                    ),
                    for (final device in widget.devices)
                      if (_positions[device.id] case final pos?)
                        _RadarTarget(
                          device: device,
                          position: pos,
                          // Angle from center, used to drive the sweep afterglow.
                          targetAngle: math.atan2(
                            pos.dy - center,
                            pos.dx - center,
                          ),
                          sweepAngle: sweepAngle,
                          isConnecting:
                              widget.connectingDeviceId == device.id,
                          isDisabled: widget.isConnecting &&
                              widget.connectingDeviceId != device.id,
                          color: color,
                          onTap: () => widget.onConnect(device),
                        ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Radar background painter ────────────────────────────────────────────────

class _RadarBackgroundPainter extends CustomPainter {
  _RadarBackgroundPainter({required this.color, required this.sweepAngle});

  final Color color;
  final double sweepAngle;

  static const double _tailWidth = math.pi / 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withAlpha(60);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * (2 / 3), ringPaint);
    canvas.drawCircle(center, radius * (1 / 3), ringPaint);

    // Center dot.
    canvas.drawCircle(
      center,
      2.5,
      Paint()..color = color.withAlpha(180),
    );

    // Semi-transparent axes.
    final axisPaint = Paint()
      ..color = color.withAlpha(70)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    // Small tick marks along each axis.
    final tickPaint = Paint()
      ..color = color.withAlpha(110)
      ..strokeWidth = 1;
    const tickHalf = 4.0;
    for (final fraction in const [1 / 3, 2 / 3]) {
      final d = radius * fraction;
      // X axis ticks.
      canvas.drawLine(
        Offset(center.dx + d, center.dy - tickHalf),
        Offset(center.dx + d, center.dy + tickHalf),
        tickPaint,
      );
      canvas.drawLine(
        Offset(center.dx - d, center.dy - tickHalf),
        Offset(center.dx - d, center.dy + tickHalf),
        tickPaint,
      );
      // Y axis ticks.
      canvas.drawLine(
        Offset(center.dx - tickHalf, center.dy + d),
        Offset(center.dx + tickHalf, center.dy + d),
        tickPaint,
      );
      canvas.drawLine(
        Offset(center.dx - tickHalf, center.dy - d),
        Offset(center.dx + tickHalf, center.dy - d),
        tickPaint,
      );
    }

    // Sweep tail — a wedge with a sweep gradient that fades from transparent
    // at the trailing edge to bright at the leading edge. Rotate the canvas
    // so the gradient angles stay in [0, tailWidth] and never wrap past 2π
    // (which would otherwise flood the off-range region with the bright
    // clamp color).
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle - _tailWidth);
    canvas.translate(-center.dx, -center.dy);

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: _tailWidth,
      colors: [
        color.withAlpha(0),
        color.withAlpha(140),
      ],
    ).createShader(rect);

    final tailPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0, _tailWidth, false)
      ..close();
    canvas.drawPath(tailPath, Paint()..shader = shader);
    canvas.restore();

    // Leading sweep line.
    final linePaint = Paint()
      ..color = color.withAlpha(230)
      ..strokeWidth = 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(sweepAngle),
        center.dy + radius * math.sin(sweepAngle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_RadarBackgroundPainter old) =>
      old.sweepAngle != sweepAngle || old.color != color;
}

// ─── Radar target ────────────────────────────────────────────────────────────

class _RadarTarget extends StatelessWidget {
  const _RadarTarget({
    required this.device,
    required this.position,
    required this.targetAngle,
    required this.sweepAngle,
    required this.isConnecting,
    required this.isDisabled,
    required this.color,
    required this.onTap,
  });

  final TvDevice device;
  final Offset position;
  final double targetAngle;
  final double sweepAngle;
  final bool isConnecting;
  final bool isDisabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final x = position.dx;
    final y = position.dy;

    // How recently the sweep passed over this target's angle (0..1, 1 = now).
    var delta = (sweepAngle - targetAngle) % (2 * math.pi);
    if (delta < 0) delta += 2 * math.pi;
    // Bright for the first ~half rotation behind the sweep, then fade out.
    final glow = math.max(0.0, 1.0 - (delta / math.pi));

    const dotSize = 12.0;
    const hitSize = 56.0;
    const labelWidth = 96.0;

    return Positioned(
      left: x - hitSize / 2,
      top: y - hitSize / 2,
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1.0,
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer afterglow ring — brighter just after the sweep hits it.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: dotSize + 18,
                  height: dotSize + 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha((130 * glow).round()),
                  ),
                ),
                if (isConnecting)
                  SizedBox(
                    width: dotSize + 10,
                    height: dotSize + 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(180),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: hitSize / 2 + dotSize / 2 + 2,
                  width: labelWidth,
                  child: Text(
                    device.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pairing banner ──────────────────────────────────────────────────────────

/// The display name of the device with [deviceId], or `null` when it is not
/// among the discovered devices — the caller supplies a localized fallback.
String? _deviceNameFor(DiscoveryState state, String deviceId) {
  for (final device in state.devices) {
    if (device.id == deviceId) return device.name;
  }
  return null;
}

/// Guidance shown while a TV is waiting on the user to finish pairing — either
/// accepting a prompt on the TV, or typing a code the TV displays.
class _PairingBanner extends StatefulWidget {
  const _PairingBanner({
    required this.request,
    required this.deviceName,
    required this.onSubmitCode,
  });

  final PairingRequest request;
  final String deviceName;
  final void Function(String code) onSubmitCode;

  @override
  State<_PairingBanner> createState() => _PairingBannerState();
}

class _PairingBannerState extends State<_PairingBanner> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) widget.onSubmitCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCode = widget.request.kind == PairingKind.enterCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCode ? Icons.dialpad_rounded : Icons.tv_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isCode
                    ? context.l10n.discoveryPairingEnterCodeTitle
                    : context.l10n.discoveryPairingCheckTvTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCode
                ? context.l10n.discoveryPairingEnterCodeBody(widget.deviceName)
                : context.l10n.discoveryPairingCheckTvBody(widget.deviceName),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withAlpha(210),
              height: 1.4,
            ),
          ),
          if (isCode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: context.l10n.discoveryPairingCodeHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _submit,
                  child: Text(context.l10n.discoveryPairButton),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
