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

    return PopupMenuButton<AppSkin>(
      icon: const Icon(Icons.palette_outlined),
      tooltip: 'Change skin',
      initialValue: activeSkin,
      onSelected: (skin) => ref.read(skinControllerProvider).selectSkin(skin),
      itemBuilder: (context) => [
        for (final skin in AppSkin.values)
          PopupMenuItem<AppSkin>(
            value: skin,
            child: Row(
              children: [
                Icon(
                  skin == activeSkin
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(_skinLabel(skin)),
              ],
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
