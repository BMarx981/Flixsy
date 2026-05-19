import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/connect_failure.dart';
import '../../../shared/providers/app_providers.dart';

/// Sends remote key commands to the connected TV and records analytics.
///
/// State is the most recent [ConnectFailure], or `null` when the last
/// command succeeded — the home screen surfaces failures as a snackbar.
class RemoteControlNotifier extends Notifier<ConnectFailure?> {
  @override
  ConnectFailure? build() => null;

  /// Sends [key] to the TV. Skin widgets call this via their
  /// `onKeyPressed` callback — they never touch the channel directly.
  Future<void> sendKey(String key) async {
    try {
      await ref.read(remoteChannelProvider).sendKeyCommand(key);
      await ref.read(analyticsServiceProvider).logKeySent(key);
      if (state != null) state = null;
    } on ConnectFailure catch (failure) {
      state = failure;
    }
  }
}

final remoteControlProvider =
    NotifierProvider<RemoteControlNotifier, ConnectFailure?>(
      RemoteControlNotifier.new,
    );
