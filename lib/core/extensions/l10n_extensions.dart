import 'package:flutter/widgets.dart';

import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/core/errors/connect_failure.dart';

/// Localization helpers shared across the app.
///
/// `context.l10n` is the short way to reach the generated [AppLocalizations]
/// without spelling out `AppLocalizations.of(context)` at every call site.

extension L10nContext on BuildContext {
  /// The active [AppLocalizations] for this context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureL10n on AppLocalizations {
  /// A localized, user-facing message for [failure].
  ///
  /// The failure's own `message` stays English and technical — it is for logs.
  /// The UI shows this instead, mapped purely from the failure *type* so the
  /// `domain`/`core` layers never need to know about localization.
  String failureMessage(ConnectFailure failure) => switch (failure) {
    DiscoveryFailure() => failureDiscovery,
    ConnectionFailure() => failureConnection,
    CommandFailure() => failureCommand,
    UnknownFailure() => failureUnknown,
  };
}
