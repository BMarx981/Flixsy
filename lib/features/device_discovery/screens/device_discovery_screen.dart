import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/tv_device.dart';
import '../../../router/app_router.dart';
import '../providers/device_discovery_provider.dart';

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
            content: Text(next.failure!.message),
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
              const SizedBox(height: 56),
              _Header(isScanning: state.status == DiscoveryStatus.scanning),
              const SizedBox(height: 40),
              Expanded(
                child: state.devices.isEmpty
                    ? _EmptyBody(
                        status: state.status,
                        onRetry: notifier.retry,
                      )
                    : _DeviceList(state: state, onConnect: notifier.connectToDevice),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PulsingTvIcon(animate: isScanning),
        const SizedBox(height: 24),
        Text(
          'Find Your TV',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: .bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure your TV is on and connected\nto the same Wi-Fi network.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Pulsing TV icon ─────────────────────────────────────────────────────────

class _PulsingTvIcon extends StatefulWidget {
  const _PulsingTvIcon({required this.animate});
  final bool animate;

  @override
  State<_PulsingTvIcon> createState() => _PulsingTvIconState();
}

class _PulsingTvIconState extends State<_PulsingTvIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulsingTvIcon old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(60),
                  ),
                ),
              ),
            ),
          ),
          Icon(Icons.tv_rounded, size: 44, color: color),
        ],
      ),
    );
  }
}

// ─── Empty body (no devices found yet) ───────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.status, required this.onRetry});

  final DiscoveryStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == DiscoveryStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not start search',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your network connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 20),
          Text(
            'Searching your network…',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'This can take a few seconds.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ─── Device list ─────────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.state, required this.onConnect});

  final DiscoveryState state;
  final void Function(TvDevice device) onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${state.devices.length} device${state.devices.length == 1 ? '' : 's'} found',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
            ),
            if (state.status == DiscoveryStatus.scanning) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: state.devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final device = state.devices[i];
              return _DeviceTile(
                device: device,
                isConnecting: state.connectingDeviceId == device.id,
                isDisabled: state.isConnecting &&
                    state.connectingDeviceId != device.id,
                onTap: () => onConnect(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Device tile ─────────────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isConnecting,
    required this.isDisabled,
    required this.onTap,
  });

  final TvDevice device;
  final bool isConnecting;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.4 : 1.0,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tv_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (device.modelName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          device.modelName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white38),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
