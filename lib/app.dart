import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/skin_provider.dart';

class FlixsyApp extends ConsumerWidget {
  const FlixsyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinConfig = ref.watch(skinConfigProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // The window/task title follows the device language like the rest of
      // the UI — see lib/l10n/app_en.arb and the other app_<locale>.arb files.
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: skinConfig.themeData,
      routerConfig: appRouter.config(
        navigatorObservers: () => [ref.read(analyticsServiceProvider).observer],
      ),
    );
  }
}
