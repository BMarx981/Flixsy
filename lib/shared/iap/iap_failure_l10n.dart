import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/iap/iap_failure.dart';

/// Maps [IapFailure] types to localized, user-facing messages. The failure's
/// own `message` stays English and technical — it is for logs.
extension IapFailureL10n on AppLocalizations {
  String iapFailureMessage(IapFailure failure) => switch (failure) {
    IapUserCancelled() => removeAdsFailureCancelled,
    IapProductNotFound() => removeAdsFailureProductNotFound,
    IapNetworkFailure() => removeAdsFailureNetwork,
    IapNothingToRestore() => removeAdsFailureNothingToRestore,
    IapUnknownFailure() => removeAdsFailureUnknown,
  };
}
