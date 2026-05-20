import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/connect_failure.dart';
import '../../../core/extensions/l10n_extensions.dart';
import '../../../router/app_router.dart';
import '../../../shared/ads/remote_banner_ad.dart';
import '../../../shared/iap/iap_failure.dart';
import '../../../shared/iap/iap_failure_l10n.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../theming/custom_image_provider.dart';
import '../../../theming/layout_provider.dart';
import '../../../theming/skin_provider.dart';
import '../../../theming/skin_registry.dart';
import '../providers/remote_control_provider.dart';
import '../widgets/skin_picker_carousel.dart';

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
                      onKeyPressed: (key) => ref
                          .read(remoteControlProvider.notifier)
                          .sendKey(key),
                    ),
            ),
          )
        : skinConfig.buildRemoteSkin(
            layout: layout,
            imagePaths: imagePaths,
            onKeyPressed: (key) =>
                ref.read(remoteControlProvider.notifier).sendKey(key),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeTitle),
        leading: isPicking
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.skinPickerCancel,
                onPressed: () =>
                    ref.read(previewSkinProvider.notifier).state = null,
              )
            : null,
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
    final productAsync = ref.watch(removeAdsProductProvider);
    final price = productAsync.valueOrNull?.price;

    return PopupMenuButton<_HomeMenuAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => [
        if (!adsRemoved)
          PopupMenuItem(
            value: _HomeMenuAction.removeAds,
            child: Text(
              price == null
                  ? context.l10n.removeAdsAction
                  : context.l10n.removeAdsActionWithPrice(price),
            ),
          ),
        if (!adsRemoved)
          PopupMenuItem(
            value: _HomeMenuAction.restorePurchases,
            child: Text(context.l10n.restorePurchasesAction),
          ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _HomeMenuAction action,
  ) async {
    final iap = ref.read(iapServiceProvider);
    switch (action) {
      case _HomeMenuAction.removeAds:
        await iap.buyRemoveAds();
      case _HomeMenuAction.restorePurchases:
        await iap.restorePurchases();
    }
  }
}
