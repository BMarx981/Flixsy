import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/connect_failure.dart';
import '../../../theming/skin_provider.dart';
import '../../../theming/skin_registry.dart';
import '../providers/remote_control_provider.dart';

@RoutePage()
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinConfig = ref.watch(skinConfigProvider);

    // Surface failed key commands as a snackbar.
    ref.listen<ConnectFailure?>(remoteControlProvider, (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote'),
        actions: const [_SkinMenuButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: skinConfig.buildRemoteSkin(
            onKeyPressed: (key) =>
                ref.read(remoteControlProvider.notifier).sendKey(key),
          ),
        ),
      ),
    );
  }
}

/// App-bar action that lets the user switch between registered skins.
class _SkinMenuButton extends ConsumerWidget {
  const _SkinMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSkin =
        ref.watch(activeSkinProvider).valueOrNull ?? AppSkin.classic;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<AppSkin>(
      icon: const Icon(Icons.palette_outlined),
      tooltip: 'Change skin',
      initialValue: activeSkin,
      onSelected: (skin) => ref.read(skinControllerProvider).selectSkin(skin),
      // Slick rounded popup with a theme-colored outline that makes it pop.
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: colorScheme.primary.withAlpha(140),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      itemBuilder: (context) => [
        for (final skin in AppSkin.values)
          PopupMenuItem<AppSkin>(
            value: skin,
            child: _SkinMenuRow(
              label: _skinLabel(skin),
              isActive: skin == activeSkin,
              colorScheme: colorScheme,
            ),
          ),
      ],
    );
  }

  static String _skinLabel(AppSkin skin) {
    final name = skin.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

/// A single row inside the skin popup — the active skin is tinted and bolded
/// so the current selection reads clearly.
class _SkinMenuRow extends StatelessWidget {
  const _SkinMenuRow({
    required this.label,
    required this.isActive,
    required this.colorScheme,
  });

  final String label;
  final bool isActive;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final accent = colorScheme.primary;
    return Row(
      children: [
        Icon(
          isActive
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: 18,
          color: isActive ? accent : colorScheme.onSurface.withAlpha(120),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? accent : colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
