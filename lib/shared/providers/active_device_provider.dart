import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/data/models/tv_device.dart';

/// The TV the user is currently controlling — set after a successful
/// connection and cleared on explicit disconnect.
///
/// App-scoped so it survives the radar notifier rebuilding when the user
/// returns to the discovery screen from the remote. The radar reads this to
/// mark the active device, and the home AppBar reads it for the title.
class ActiveDeviceNotifier extends Notifier<TvDevice?> {
  @override
  TvDevice? build() => null;

  void set(TvDevice device) => state = device;

  void clear() => state = null;
}

final activeDeviceProvider =
    NotifierProvider<ActiveDeviceNotifier, TvDevice?>(ActiveDeviceNotifier.new);
