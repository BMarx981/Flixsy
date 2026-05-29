import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/router/app_router.dart';
import 'package:flixsy/shared/ads/remote_banner_ad.dart';
import 'package:flixsy/features/device_discovery/providers/device_display_names_provider.dart';
import 'package:flixsy/features/device_discovery/widgets/rename_device_dialog.dart';
import 'package:flixsy/shared/iap/iap_failure.dart';
import 'package:flixsy/shared/iap/iap_failure_l10n.dart';
import 'package:flixsy/shared/providers/active_device_provider.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/shared/widgets/glass_popup_menu.dart';
import 'package:flixsy/theming/custom_image_provider.dart';
import 'package:flixsy/theming/layout_provider.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/skin_provider.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flixsy/features/keyboard/voice/voice_spike_button.dart';
import 'package:flixsy/features/keyboard/widgets/keyboard_sheet.dart';
import 'package:flixsy/features/home/providers/remote_control_provider.dart';
import 'package:flixsy/features/home/widgets/skin_picker_carousel.dart';

enum _HomeMenuAction { removeAds, restorePurchases }

@RoutePage()
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinConfig = ref.watch(skinConfigProvider);
    final layout = ref.watch(activeLayoutProvider);
    final imagePaths = ref.watch(customImagePathsProvider);
    final preview = ref.watch(previewSkinProvider);
    final isPicking = preview != null;
    final adsRemoved = ref.watch(adsRemovedProvider).valueOrNull ?? false;

    // Surface failed key commands as a snackbar.
    ref.listen<ConnectFailure?>(remoteControlProvider, (prev, next) {
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failureMessage(next)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    // Surface IAP failures (cancel / network / etc.) as a snackbar.
    ref.listen<AsyncValue<IapFailure>>(iapFailureStreamProvider, (prev, next) {
      next.whenData((failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.iapFailureMessage(failure)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });

    // Confirmation when the entitlement flips on (purchase or restore).
    ref.listen<AsyncValue<bool>>(adsRemovedProvider, (prev, next) {
      final wasOff = prev?.valueOrNull == false;
      final isNowOn = next.valueOrNull == true;
      if (wasOff && isNowOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.removeAdsSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Single dispatch for every button press from any skin or custom layout.
    // RemoteKey.keyboard is UI-only — it opens the in-app keyboard sheet
    // (when the connected channel exposes a RemoteTextInput) instead of
    // going to the wire. Every other key flows through to the channel.
    void handleKeyPressed(String key) {
      if (key == RemoteKey.keyboard.code) {
        final textInput = ref.read(remoteChannelProvider).textInput;
        if (textInput == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.keyboardNotSupported),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        showKeyboardSheet(context, textInput: textInput);
        return;
      }
      ref.read(remoteControlProvider.notifier).sendKey(key);
    }

    final remote = isPicking || !skinConfig.edgeToEdge
        ? SafeArea(
            // Don't extend the safe area into the banner ad — the banner has
            // its own bottom inset handling at the Scaffold level.
            bottom: adsRemoved,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isPicking
                  ? SkinPickerCarousel(
                      layout: layout,
                      imagePaths: imagePaths,
                    )
                  : skinConfig.buildRemoteSkin(
                      layout: layout,
                      imagePaths: imagePaths,
                      onKeyPressed: handleKeyPressed,
                    ),
            ),
          )
        : skinConfig.buildRemoteSkin(
            layout: layout,
            imagePaths: imagePaths,
            onKeyPressed: handleKeyPressed,
          );

    final activeDevice = ref.watch(activeDeviceProvider);
    final displayNames = ref.watch(deviceDisplayNamesProvider);
    final connectedTitle = activeDevice == null
        ? context.l10n.homeTitle
        : displayNames[activeDevice.id] ?? activeDevice.name;

    return Scaffold(
      appBar: AppBar(
        title: activeDevice == null || isPicking
            ? Text(connectedTitle)
            : InkWell(
                onTap: () =>
                    showRenameDeviceDialog(context, ref, activeDevice),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(connectedTitle),
                ),
              ),
        leading: isPicking
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.skinPickerCancel,
                onPressed: () =>
                    ref.read(previewSkinProvider.notifier).state = null,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: context.l10n.homeBackToRadarTooltip,
                onPressed: () =>
                    context.router.replace(const DeviceDiscoveryRoute()),
              ),
        actions: isPicking
            ? [
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(skinControllerProvider)
                        .selectSkin(preview);
                    ref.read(previewSkinProvider.notifier).state = null;
                  },
                  child: Text(context.l10n.skinPickerApply),
                ),
                const SizedBox(width: 4),
              ]
            : [
                // PHASE 0 SPIKE — remove with voice_spike_button.dart.
                const VoiceSpikeButton(),
                IconButton(
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  tooltip: context.l10n.homeLayoutsTooltip,
                  onPressed: () =>
                      context.router.push(const LayoutPickerRoute()),
                ),
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: context.l10n.homeChangeSkinTooltip,
                  onPressed: () {
                    final active =
                        ref.read(activeSkinProvider).valueOrNull ??
                        AppSkin.classic;
                    ref.read(previewSkinProvider.notifier).state = active;
                  },
                ),
                _HomeOverflowMenu(adsRemoved: adsRemoved),
              ],
      ),
      body: adsRemoved
          ? remote
          : Column(
              children: [
                Expanded(child: remote),
                const RemoteBannerAd(),
              ],
            ),
    );
  }
}

/// Streams IAP failures from the singleton [IapService] so screens can show
/// them in a snackbar without subscribing twice. Lives here because today
/// only HomeScreen surfaces them.
final iapFailureStreamProvider = StreamProvider.autoDispose<IapFailure>((ref) {
  return ref.watch(iapServiceProvider).failures;
});

class _HomeOverflowMenu extends ConsumerWidget {
  const _HomeOverflowMenu({required this.adsRemoved});

  final bool adsRemoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = ref.watch(removeAdsProductProvider).valueOrNull?.price;

    return GlassPopupMenu<_HomeMenuAction>(
      onSelected: (action) => _handle(ref, action),
      items: [
        if (!adsRemoved)
          GlassPopupMenuItem(
            value: _HomeMenuAction.removeAds,
            icon: Icons.block_outlined,
            label: price == null
                ? context.l10n.removeAdsAction
                : context.l10n.removeAdsActionWithPrice(price),
          ),
        if (!adsRemoved)
          GlassPopupMenuItem(
            value: _HomeMenuAction.restorePurchases,
            icon: Icons.restore_rounded,
            label: context.l10n.restorePurchasesAction,
          ),
      ],
    );
  }

  Future<void> _handle(WidgetRef ref, _HomeMenuAction action) async {
    final iap = ref.read(iapServiceProvider);
    switch (action) {
      case _HomeMenuAction.removeAds:
        await iap.buyRemoveAds();
      case _HomeMenuAction.restorePurchases:
        await iap.restorePurchases();
    }
  }
}
