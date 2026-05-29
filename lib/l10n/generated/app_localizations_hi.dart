// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'अपना टीवी खोजें';

  @override
  String get discoveryHeaderSubtitle =>
      'सुनिश्चित करें कि आपका टीवी चालू है और उसी Wi-Fi नेटवर्क से जुड़ा है।';

  @override
  String get discoveryErrorTitle => 'खोज शुरू नहीं हो सकी';

  @override
  String get discoveryErrorBody =>
      'अपना नेटवर्क कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String get discoveryRetryButton => 'पुनः प्रयास करें';

  @override
  String get discoverySearching => 'आपके नेटवर्क पर खोज रहे हैं…';

  @override
  String get discoverySearchingHint => 'इसमें कुछ सेकंड लग सकते हैं।';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डिवाइस मिले',
      one: '1 डिवाइस मिला',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'आपके टीवी';

  @override
  String get discoveryPairingEnterCodeTitle => 'कोड दर्ज करें';

  @override
  String get discoveryPairingCheckTvTitle => 'अपना टीवी देखें';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName एक 6-अंकीय कोड दिखा रहा है। पेयरिंग पूरी करने के लिए उसे नीचे दर्ज करें।';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return '$deviceName पर रिमोट से कनेक्शन अनुरोध स्वीकार करें।';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'पेयर करें';

  @override
  String get homeTitle => 'रिमोट';

  @override
  String get homeBackToRadarTooltip => 'कोई दूसरा टीवी चुनें';

  @override
  String get renameDeviceDialogTitle => 'टीवी का नाम बदलें';

  @override
  String get renameDeviceFieldLabel => 'नाम';

  @override
  String get renameDeviceSaveButton => 'सहेजें';

  @override
  String get renameDeviceCancelButton => 'रद्द करें';

  @override
  String get renameDeviceResetButton => 'रीसेट करें';

  @override
  String get homeLayoutsTooltip => 'लेआउट';

  @override
  String get homeChangeSkinTooltip => 'स्किन बदलें';

  @override
  String get skinPickerApply => 'लागू करें';

  @override
  String get skinPickerCancel => 'रद्द करें';

  @override
  String get skinPickerPreviousTooltip => 'पिछली स्किन';

  @override
  String get skinPickerNextTooltip => 'अगली स्किन';

  @override
  String get layoutPickerTitle => 'लेआउट';

  @override
  String layoutPickerLoadError(String error) {
    return 'लेआउट लोड नहीं हो सके।\n$error';
  }

  @override
  String get layoutTypeTemplate => 'बिल्ट-इन टेम्पलेट';

  @override
  String get layoutTypeCustom => 'कस्टम लेआउट';

  @override
  String get layoutActionsTooltip => 'लेआउट क्रियाएँ';

  @override
  String get layoutActionDuplicate => 'डुप्लीकेट';

  @override
  String get layoutActionEdit => 'संपादित करें';

  @override
  String get layoutDeleteDialogTitle => 'लेआउट हटाएँ?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\" स्थायी रूप से हटा दिया जाएगा।';
  }

  @override
  String get editorTitle => 'लेआउट संपादित करें';

  @override
  String get editorAddBlockButton => 'ब्लॉक जोड़ें';

  @override
  String get editorValidationName => 'लेआउट को एक नाम दें।';

  @override
  String get editorValidationBlocks =>
      'सहेजने से पहले कम से कम एक ब्लॉक जोड़ें।';

  @override
  String get editorSavedSnack => 'लेआउट सहेजा गया।';

  @override
  String get editorPreviewLabel => 'पूर्वावलोकन';

  @override
  String get editorBlocksLabel => 'ब्लॉक';

  @override
  String get editorNameFieldLabel => 'लेआउट का नाम';

  @override
  String get editorEmptyPreview => 'पूर्वावलोकन देखने के लिए ब्लॉक जोड़ें';

  @override
  String get editorRemoveBlockTooltip => 'ब्लॉक हटाएँ';

  @override
  String get editorEmptyCell => 'खाली';

  @override
  String get editorRemoveButtonTooltip => 'बटन हटाएँ';

  @override
  String get editorAddButtonChip => 'जोड़ें';

  @override
  String get blockKindDpad => 'डी-पैड';

  @override
  String get blockKindButtonRow => 'बटन पंक्ति';

  @override
  String get blockKindVolume => 'वॉल्यूम रॉकर';

  @override
  String get blockKindGrid => 'ग्रिड';

  @override
  String get blockKindSpacer => 'स्पेसर';

  @override
  String get blockDescDpad => 'पाँच-बटन वाली दिशात्मक क्रॉस';

  @override
  String get blockDescButtonRow => 'समान दूरी पर बटनों की पंक्ति';

  @override
  String get blockDescVolume => 'वॉल्यूम कम / म्यूट / वॉल्यूम अधिक';

  @override
  String get blockDescGrid => 'बटनों का ग्रिड';

  @override
  String get blockDescSpacer => 'ब्लॉकों के बीच खाली ऊर्ध्वाधर स्थान';

  @override
  String get buttonEditorTitle => 'बटन संपादित करें';

  @override
  String get buttonEditorActionLabel => 'क्रिया';

  @override
  String get buttonEditorIconLabel => 'आइकन';

  @override
  String get buttonEditorShowLabel => 'लेबल दिखाएँ';

  @override
  String get buttonEditorShowLabelOn => 'बटन पर कैप्शन दिखाया जाता है';

  @override
  String get buttonEditorShowLabelOff => 'बटन पर कोई कैप्शन नहीं दिखता';

  @override
  String get buttonEditorLabelField => 'लेबल';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'खाली — डिफ़ॉल्ट का उपयोग: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'आइकन चुनें';

  @override
  String get iconPickerDefaultSubtitle => 'इस क्रिया के लिए मानक आइकन';

  @override
  String get iconPickerTextOnlySubtitle => 'बिना आइकन के लेबल दिखाएँ';

  @override
  String get iconPickerYourImages => 'आपकी छवियाँ';

  @override
  String get iconPickerAddImage => 'जोड़ें';

  @override
  String get iconPackStandardName => 'मानक';

  @override
  String get appearanceDefault => 'डिफ़ॉल्ट';

  @override
  String get appearanceTextOnly => 'केवल टेक्स्ट';

  @override
  String get appearancePackIcon => 'पैक आइकन';

  @override
  String get appearanceCustomImage => 'कस्टम छवि';

  @override
  String get appearanceCustomIcon => 'कस्टम आइकन';

  @override
  String get keyRoleDpad => 'दिशात्मक';

  @override
  String get keyRoleNavigation => 'नेविगेशन';

  @override
  String get keyRoleTransport => 'प्लेबैक';

  @override
  String get keyRoleVolume => 'वॉल्यूम';

  @override
  String get keyRoleChannel => 'चैनल';

  @override
  String get keyRoleSystem => 'सिस्टम';

  @override
  String get remoteKeyUp => 'ऊपर';

  @override
  String get remoteKeyDown => 'नीचे';

  @override
  String get remoteKeyLeft => 'बाएँ';

  @override
  String get remoteKeyRight => 'दाएँ';

  @override
  String get remoteKeyOk => 'ठीक';

  @override
  String get remoteKeyBack => 'वापस';

  @override
  String get remoteKeyHome => 'होम';

  @override
  String get remoteKeyRewind => 'रिवाइंड';

  @override
  String get remoteKeyPlayPause => 'चलाएँ/रोकें';

  @override
  String get remoteKeyFastForward => 'फास्ट फॉरवर्ड';

  @override
  String get remoteKeyNext => 'अगला';

  @override
  String get remoteKeyPrevious => 'पिछला';

  @override
  String get remoteKeyVolumeUp => 'वॉल्यूम बढ़ाएँ';

  @override
  String get remoteKeyVolumeDown => 'वॉल्यूम घटाएँ';

  @override
  String get remoteKeyMute => 'म्यूट';

  @override
  String get remoteKeyChannelUp => 'चैनल +';

  @override
  String get remoteKeyChannelDown => 'चैनल -';

  @override
  String get remoteKeyPower => 'पावर';

  @override
  String get remoteKeySettings => 'सेटिंग्स';

  @override
  String get remoteKeyKeyboard => 'कीबोर्ड';

  @override
  String get keyboardTitle => 'टीवी पर लिखें';

  @override
  String get keyboardHint =>
      'अपने टीवी पर टेक्स्ट फ़ील्ड चुनें, फिर यहाँ टाइप करें।';

  @override
  String get keyboardSendEnter => 'Enter भेजें';

  @override
  String get keyboardClose => 'पूर्ण';

  @override
  String get keyboardNotSupported =>
      'यह टीवी रिमोट टाइपिंग का समर्थन नहीं करता।';

  @override
  String get iconNameUp => 'ऊपर';

  @override
  String get iconNameDown => 'नीचे';

  @override
  String get iconNameLeft => 'बाएँ';

  @override
  String get iconNameRight => 'दाएँ';

  @override
  String get iconNameOk => 'ठीक';

  @override
  String get iconNameBack => 'वापस';

  @override
  String get iconNameHome => 'होम';

  @override
  String get iconNameRewind => 'रिवाइंड';

  @override
  String get iconNameFastForward => 'फास्ट फॉरवर्ड';

  @override
  String get iconNamePlayPause => 'चलाएँ / रोकें';

  @override
  String get iconNamePlay => 'चलाएँ';

  @override
  String get iconNamePause => 'रोकें';

  @override
  String get iconNameStop => 'रुकें';

  @override
  String get iconNameNext => 'अगला';

  @override
  String get iconNamePrevious => 'पिछला';

  @override
  String get iconNameVolumeUp => 'वॉल्यूम बढ़ाएँ';

  @override
  String get iconNameVolumeDown => 'वॉल्यूम घटाएँ';

  @override
  String get iconNameMute => 'म्यूट';

  @override
  String get iconNameChannelUp => 'चैनल +';

  @override
  String get iconNameChannelDown => 'चैनल -';

  @override
  String get iconNamePower => 'पावर';

  @override
  String get iconNameMenu => 'मेनू';

  @override
  String get iconNameSettings => 'सेटिंग्स';

  @override
  String get iconNameInfo => 'जानकारी';

  @override
  String get iconNameMic => 'माइक्रोफ़ोन';

  @override
  String get iconNameKeyboard => 'कीबोर्ड';

  @override
  String get failureDiscovery =>
      'टीवी नहीं खोजे जा सके। अपना Wi-Fi जाँचें और पुनः प्रयास करें।';

  @override
  String get failureConnection =>
      'टीवी से कनेक्ट नहीं हो सका। सुनिश्चित करें कि वह चालू है और पास में है।';

  @override
  String get failureCommand => 'वह बटन नहीं पहुँचा। कृपया पुनः प्रयास करें।';

  @override
  String get failureUnknown => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get logoSemanticLabel => 'Flixsy लोगो';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy रिमोट';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonDelete => 'हटाएँ';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonDone => 'पूर्ण';

  @override
  String get removeAdsAction => 'विज्ञापन हटाएँ';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'विज्ञापन हटाएँ — $price';
  }

  @override
  String get restorePurchasesAction => 'खरीदारी पुनर्स्थापित करें';

  @override
  String get removeAdsSuccess =>
      'विज्ञापन हटा दिए गए। आपके समर्थन के लिए धन्यवाद!';

  @override
  String get removeAdsFailureCancelled => 'खरीद रद्द की गई।';

  @override
  String get removeAdsFailureProductNotFound =>
      'यह उत्पाद अभी उपलब्ध नहीं है। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get removeAdsFailureNetwork =>
      'स्टोर तक नहीं पहुँचा जा सका। अपना कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String get removeAdsFailureNothingToRestore => 'कोई पिछली खरीदारी नहीं मिली।';

  @override
  String get removeAdsFailureUnknown =>
      'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse केवल LG webOS टीवी पर उपलब्ध है।';

  @override
  String get voiceSpikeTooltip => 'Voice spike (Phase 0)';

  @override
  String accessibilitySkinChangedAnnouncement(String skinName) {
    return 'Switched to $skinName skin';
  }

  @override
  String accessibilityDeviceConnectedAnnouncement(String deviceName) {
    return 'Connected to $deviceName';
  }

  @override
  String get accessibilityDeviceDisconnectedAnnouncement =>
      'Disconnected from TV';
}
