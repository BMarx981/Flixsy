import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/l10n_extensions.dart';
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
              const SizedBox(height: 56),
              _Header(isScanning: state.status == DiscoveryStatus.scanning),
              const SizedBox(height: 40),
              if (state.pairing != null) ...[
                _PairingBanner(
                  request: state.pairing!,
                  deviceName:
                      _deviceNameFor(state, state.pairing!.deviceId) ??
                      context.l10n.discoveryDeviceFallbackName,
                  onSubmitCode: notifier.submitPairingCode,
                ),
                const SizedBox(height: 24),
              ],
              Expanded(
                child: state.devices.isEmpty
                    ? _EmptyBody(status: state.status, onRetry: notifier.retry)
                    : _DeviceList(
                        state: state,
                        onConnect: notifier.connectToDevice,
                      ),
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
          context.l10n.discoveryHeaderTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: .bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.discoveryHeaderSubtitle,
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
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
            context.l10n.discoverySearching,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.discoverySearchingHint,
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
              context.l10n.discoveryDevicesFound(state.devices.length),
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
                isDisabled:
                    state.isConnecting && state.connectingDeviceId != device.id,
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
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
