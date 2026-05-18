import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared/providers/app_providers.dart';
import 'theming/skin_provider.dart';

class FlixsyApp extends ConsumerWidget {
  const FlixsyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinConfig = ref.watch(skinConfigProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Flixsy',
      theme: skinConfig.themeData,
      routerConfig: appRouter.config(
        navigatorObservers: () => [ref.read(analyticsServiceProvider).observer],
      ),
    );
  }
}
