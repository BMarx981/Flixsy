// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Find Your TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Make sure your TV is on and connected to the same Wi-Fi network.';

  @override
  String get discoveryErrorTitle => 'Could not start search';

  @override
  String get discoveryErrorBody =>
      'Check your network connection and try again.';

  @override
  String get discoveryRetryButton => 'Try Again';

  @override
  String get discoverySearching => 'Searching your network…';

  @override
  String get discoverySearchingHint => 'This can take a few seconds.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices found',
      one: '1 device found',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'your TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Enter the code';

  @override
  String get discoveryPairingCheckTvTitle => 'Check your TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName is showing a 6-digit code. Type it below to finish pairing.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Accept the connection request on $deviceName using its remote.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Pair';

  @override
  String get homeTitle => 'Remote';

  @override
  String get homeLayoutsTooltip => 'Layouts';

  @override
  String get homeChangeSkinTooltip => 'Change skin';

  @override
  String get skinPickerApply => 'Apply';

  @override
  String get skinPickerCancel => 'Cancel';

  @override
  String get skinPickerPreviousTooltip => 'Previous skin';

  @override
  String get skinPickerNextTooltip => 'Next skin';

  @override
  String get layoutPickerTitle => 'Layouts';

  @override
  String layoutPickerLoadError(String error) {
    return 'Could not load layouts.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Built-in template';

  @override
  String get layoutTypeCustom => 'Custom layout';

  @override
  String get layoutActionsTooltip => 'Layout actions';

  @override
  String get layoutActionDuplicate => 'Duplicate';

  @override
  String get layoutActionEdit => 'Edit';

  @override
  String get layoutDeleteDialogTitle => 'Delete layout?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\" will be permanently removed.';
  }

  @override
  String get editorTitle => 'Edit layout';

  @override
  String get editorAddBlockButton => 'Add block';

  @override
  String get editorValidationName => 'Give the layout a name.';

  @override
  String get editorValidationBlocks => 'Add at least one block before saving.';

  @override
  String get editorSavedSnack => 'Layout saved.';

  @override
  String get editorPreviewLabel => 'Preview';

  @override
  String get editorBlocksLabel => 'Blocks';

  @override
  String get editorNameFieldLabel => 'Layout name';

  @override
  String get editorEmptyPreview => 'Add a block to see a preview';

  @override
  String get editorRemoveBlockTooltip => 'Remove block';

  @override
  String get editorEmptyCell => 'Empty';

  @override
  String get blockKindDpad => 'D-pad';

  @override
  String get blockKindButtonRow => 'Button row';

  @override
  String get blockKindVolume => 'Volume rocker';

  @override
  String get blockKindGrid => 'Grid';

  @override
  String get blockKindSpacer => 'Spacer';

  @override
  String get blockDescDpad => 'A five-button directional cross';

  @override
  String get blockDescButtonRow => 'An evenly spaced row of buttons';

  @override
  String get blockDescVolume => 'Volume down / mute / volume up';

  @override
  String get blockDescGrid => 'A grid of buttons';

  @override
  String get blockDescSpacer => 'Blank vertical space between blocks';

  @override
  String get buttonEditorTitle => 'Edit button';

  @override
  String get buttonEditorActionLabel => 'Action';

  @override
  String get buttonEditorIconLabel => 'Icon';

  @override
  String get buttonEditorShowLabel => 'Show label';

  @override
  String get buttonEditorShowLabelOn => 'A caption is shown on the button';

  @override
  String get buttonEditorShowLabelOff => 'The button shows no caption';

  @override
  String get buttonEditorLabelField => 'Label';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Empty — using the default: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Choose icon';

  @override
  String get iconPickerDefaultSubtitle => 'The standard icon for this action';

  @override
  String get iconPickerTextOnlySubtitle => 'Show the label, no icon';

  @override
  String get iconPickerYourImages => 'Your images';

  @override
  String get iconPickerAddImage => 'Add';

  @override
  String get iconPackStandardName => 'Standard';

  @override
  String get appearanceDefault => 'Default';

  @override
  String get appearanceTextOnly => 'Text only';

  @override
  String get appearancePackIcon => 'Pack icon';

  @override
  String get appearanceCustomImage => 'Custom image';

  @override
  String get appearanceCustomIcon => 'Custom icon';

  @override
  String get keyRoleDpad => 'Directional';

  @override
  String get keyRoleNavigation => 'Navigation';

  @override
  String get keyRoleTransport => 'Playback';

  @override
  String get keyRoleVolume => 'Volume';

  @override
  String get keyRoleSystem => 'System';

  @override
  String get remoteKeyUp => 'Up';

  @override
  String get remoteKeyDown => 'Down';

  @override
  String get remoteKeyLeft => 'Left';

  @override
  String get remoteKeyRight => 'Right';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Back';

  @override
  String get remoteKeyHome => 'Home';

  @override
  String get remoteKeyRewind => 'Rewind';

  @override
  String get remoteKeyPlayPause => 'Play/Pause';

  @override
  String get remoteKeyFastForward => 'Fast Forward';

  @override
  String get remoteKeyNext => 'Next';

  @override
  String get remoteKeyPrevious => 'Previous';

  @override
  String get remoteKeyVolumeUp => 'Volume Up';

  @override
  String get remoteKeyVolumeDown => 'Volume Down';

  @override
  String get remoteKeyMute => 'Mute';

  @override
  String get remoteKeyPower => 'Power';

  @override
  String get iconNameUp => 'Up';

  @override
  String get iconNameDown => 'Down';

  @override
  String get iconNameLeft => 'Left';

  @override
  String get iconNameRight => 'Right';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Back';

  @override
  String get iconNameHome => 'Home';

  @override
  String get iconNameRewind => 'Rewind';

  @override
  String get iconNameFastForward => 'Fast forward';

  @override
  String get iconNamePlayPause => 'Play / Pause';

  @override
  String get iconNamePlay => 'Play';

  @override
  String get iconNamePause => 'Pause';

  @override
  String get iconNameStop => 'Stop';

  @override
  String get iconNameNext => 'Next';

  @override
  String get iconNamePrevious => 'Previous';

  @override
  String get iconNameVolumeUp => 'Volume up';

  @override
  String get iconNameVolumeDown => 'Volume down';

  @override
  String get iconNameMute => 'Mute';

  @override
  String get iconNamePower => 'Power';

  @override
  String get iconNameMenu => 'Menu';

  @override
  String get iconNameSettings => 'Settings';

  @override
  String get iconNameInfo => 'Info';

  @override
  String get iconNameMic => 'Microphone';

  @override
  String get failureDiscovery =>
      'Couldn\'t search for TVs. Check your Wi-Fi and try again.';

  @override
  String get failureConnection =>
      'Couldn\'t connect to the TV. Make sure it\'s on and nearby.';

  @override
  String get failureCommand =>
      'That button didn\'t go through. Please try again.';

  @override
  String get failureUnknown => 'Something went wrong. Please try again.';

  @override
  String get logoSemanticLabel => 'Flixsy logo';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy remote';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get removeAdsAction => 'Remove Ads';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Remove Ads — $price';
  }

  @override
  String get restorePurchasesAction => 'Restore Purchases';

  @override
  String get removeAdsSuccess => 'Ads removed. Thanks for your support!';

  @override
  String get removeAdsFailureCancelled => 'Purchase cancelled.';

  @override
  String get removeAdsFailureProductNotFound =>
      'This product isn\'t available right now. Please try again later.';

  @override
  String get removeAdsFailureNetwork =>
      'Couldn\'t reach the store. Check your connection and try again.';

  @override
  String get removeAdsFailureNothingToRestore => 'No previous purchases found.';

  @override
  String get removeAdsFailureUnknown =>
      'Something went wrong. Please try again.';
}
