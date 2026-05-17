import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/app_providers.dart';
import 'skin_registry.dart';

/// Streams the active [AppSkin] from the Drift-backed preferences repository.
final activeSkinProvider = StreamProvider<AppSkin>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.watchActiveSkin();
});

/// Synchronously resolves the [SkinConfig] for the current skin,
/// falling back to [AppSkin.classic] while the stream is loading.
final skinConfigProvider = Provider<SkinConfig>((ref) {
  final activeSkin =
      ref.watch(activeSkinProvider).valueOrNull ?? AppSkin.classic;
  return skinRegistry[activeSkin]!;
});
