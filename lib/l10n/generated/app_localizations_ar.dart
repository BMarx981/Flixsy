// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'ابحث عن تلفازك';

  @override
  String get discoveryHeaderSubtitle =>
      'تأكد من أن التلفاز يعمل ومتصل بنفس شبكة Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'تعذر بدء البحث';

  @override
  String get discoveryErrorBody => 'تحقق من اتصال الشبكة وحاول مرة أخرى.';

  @override
  String get discoveryRetryButton => 'إعادة المحاولة';

  @override
  String get discoverySearching => 'جارٍ البحث في شبكتك…';

  @override
  String get discoverySearchingHint => 'قد يستغرق ذلك بضع ثوانٍ.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count جهاز',
      many: 'تم العثور على $count جهازًا',
      few: 'تم العثور على $count أجهزة',
      two: 'تم العثور على جهازين',
      one: 'تم العثور على جهاز واحد',
      zero: 'لم يتم العثور على أجهزة',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'تلفازك';

  @override
  String get discoveryPairingEnterCodeTitle => 'أدخل الرمز';

  @override
  String get discoveryPairingCheckTvTitle => 'انظر إلى تلفازك';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return 'يعرض $deviceName رمزًا مكونًا من 6 أرقام. أدخله أدناه لإكمال الإقران.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'اقبل طلب الاتصال على $deviceName باستخدام جهاز التحكم الخاص به.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'إقران';

  @override
  String get homeTitle => 'جهاز التحكم';

  @override
  String get homeBackToRadarTooltip => 'اختيار تلفاز آخر';

  @override
  String get renameDeviceDialogTitle => 'إعادة تسمية التلفاز';

  @override
  String get renameDeviceFieldLabel => 'الاسم';

  @override
  String get renameDeviceSaveButton => 'حفظ';

  @override
  String get renameDeviceCancelButton => 'إلغاء';

  @override
  String get renameDeviceResetButton => 'إعادة تعيين';

  @override
  String get homeLayoutsTooltip => 'التخطيطات';

  @override
  String get homeChangeSkinTooltip => 'تغيير المظهر';

  @override
  String get skinPickerApply => 'تطبيق';

  @override
  String get skinPickerCancel => 'إلغاء';

  @override
  String get skinPickerPreviousTooltip => 'المظهر السابق';

  @override
  String get skinPickerNextTooltip => 'المظهر التالي';

  @override
  String get layoutPickerTitle => 'التخطيطات';

  @override
  String layoutPickerLoadError(String error) {
    return 'تعذر تحميل التخطيطات.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'قالب مدمج';

  @override
  String get layoutTypeCustom => 'تخطيط مخصص';

  @override
  String get layoutActionsTooltip => 'إجراءات التخطيط';

  @override
  String get layoutActionDuplicate => 'تكرار';

  @override
  String get layoutActionEdit => 'تعديل';

  @override
  String get layoutDeleteDialogTitle => 'حذف التخطيط؟';

  @override
  String layoutDeleteDialogBody(String name) {
    return 'سيتم حذف «$name» نهائيًا.';
  }

  @override
  String get editorTitle => 'تعديل التخطيط';

  @override
  String get editorAddBlockButton => 'إضافة كتلة';

  @override
  String get editorValidationName => 'أعطِ التخطيط اسمًا.';

  @override
  String get editorValidationBlocks => 'أضف كتلة واحدة على الأقل قبل الحفظ.';

  @override
  String get editorSavedSnack => 'تم حفظ التخطيط.';

  @override
  String get editorPreviewLabel => 'معاينة';

  @override
  String get editorBlocksLabel => 'الكتل';

  @override
  String get editorNameFieldLabel => 'اسم التخطيط';

  @override
  String get editorEmptyPreview => 'أضف كتلة لعرض المعاينة';

  @override
  String get editorRemoveBlockTooltip => 'إزالة الكتلة';

  @override
  String get editorEmptyCell => 'فارغ';

  @override
  String get editorRemoveButtonTooltip => 'إزالة الزر';

  @override
  String get editorAddButtonChip => 'إضافة';

  @override
  String get blockKindDpad => 'أزرار اتجاهية';

  @override
  String get blockKindButtonRow => 'صف أزرار';

  @override
  String get blockKindVolume => 'متحكم الصوت';

  @override
  String get blockKindGrid => 'شبكة';

  @override
  String get blockKindSpacer => 'فاصل';

  @override
  String get blockDescDpad => 'صليب اتجاهي بخمسة أزرار';

  @override
  String get blockDescButtonRow => 'صف من الأزرار متساوية المسافات';

  @override
  String get blockDescVolume => 'خفض الصوت / كتم / رفع الصوت';

  @override
  String get blockDescGrid => 'شبكة من الأزرار';

  @override
  String get blockDescSpacer => 'مسافة عمودية فارغة بين الكتل';

  @override
  String get buttonEditorTitle => 'تعديل الزر';

  @override
  String get buttonEditorActionLabel => 'الإجراء';

  @override
  String get buttonEditorIconLabel => 'الأيقونة';

  @override
  String get buttonEditorShowLabel => 'إظهار التسمية';

  @override
  String get buttonEditorShowLabelOn => 'يتم عرض تسمية على الزر';

  @override
  String get buttonEditorShowLabelOff => 'لا يتم عرض تسمية على الزر';

  @override
  String get buttonEditorLabelField => 'التسمية';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'فارغ — يستخدم الافتراضي: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'اختر أيقونة';

  @override
  String get iconPickerDefaultSubtitle => 'الأيقونة القياسية لهذا الإجراء';

  @override
  String get iconPickerTextOnlySubtitle => 'إظهار التسمية فقط، بدون أيقونة';

  @override
  String get iconPickerYourImages => 'صورك';

  @override
  String get iconPickerAddImage => 'إضافة';

  @override
  String get iconPackStandardName => 'قياسي';

  @override
  String get appearanceDefault => 'افتراضي';

  @override
  String get appearanceTextOnly => 'نص فقط';

  @override
  String get appearancePackIcon => 'أيقونة من الحزمة';

  @override
  String get appearanceCustomImage => 'صورة مخصصة';

  @override
  String get appearanceCustomIcon => 'أيقونة مخصصة';

  @override
  String get keyRoleDpad => 'اتجاهي';

  @override
  String get keyRoleNavigation => 'تنقل';

  @override
  String get keyRoleTransport => 'تشغيل';

  @override
  String get keyRoleVolume => 'الصوت';

  @override
  String get keyRoleChannel => 'القناة';

  @override
  String get keyRoleSystem => 'النظام';

  @override
  String get remoteKeyUp => 'أعلى';

  @override
  String get remoteKeyDown => 'أسفل';

  @override
  String get remoteKeyLeft => 'يسار';

  @override
  String get remoteKeyRight => 'يمين';

  @override
  String get remoteKeyOk => 'موافق';

  @override
  String get remoteKeyBack => 'رجوع';

  @override
  String get remoteKeyHome => 'الرئيسية';

  @override
  String get remoteKeyRewind => 'إرجاع';

  @override
  String get remoteKeyPlayPause => 'تشغيل/إيقاف مؤقت';

  @override
  String get remoteKeyFastForward => 'تقديم سريع';

  @override
  String get remoteKeyNext => 'التالي';

  @override
  String get remoteKeyPrevious => 'السابق';

  @override
  String get remoteKeyVolumeUp => 'رفع الصوت';

  @override
  String get remoteKeyVolumeDown => 'خفض الصوت';

  @override
  String get remoteKeyMute => 'كتم الصوت';

  @override
  String get remoteKeyChannelUp => 'القناة +';

  @override
  String get remoteKeyChannelDown => 'القناة -';

  @override
  String get remoteKeyPower => 'الطاقة';

  @override
  String get remoteKeySettings => 'الإعدادات';

  @override
  String get remoteKeyKeyboard => 'لوحة المفاتيح';

  @override
  String get keyboardTitle => 'اكتب إلى التلفاز';

  @override
  String get keyboardHint => 'حدد حقل نص على التلفاز ثم اكتب هنا.';

  @override
  String get keyboardSendEnter => 'إرسال Enter';

  @override
  String get keyboardClose => 'تم';

  @override
  String get keyboardNotSupported => 'هذا التلفاز لا يدعم الكتابة عن بُعد.';

  @override
  String get iconNameUp => 'أعلى';

  @override
  String get iconNameDown => 'أسفل';

  @override
  String get iconNameLeft => 'يسار';

  @override
  String get iconNameRight => 'يمين';

  @override
  String get iconNameOk => 'موافق';

  @override
  String get iconNameBack => 'رجوع';

  @override
  String get iconNameHome => 'الرئيسية';

  @override
  String get iconNameRewind => 'إرجاع';

  @override
  String get iconNameFastForward => 'تقديم سريع';

  @override
  String get iconNamePlayPause => 'تشغيل / إيقاف مؤقت';

  @override
  String get iconNamePlay => 'تشغيل';

  @override
  String get iconNamePause => 'إيقاف مؤقت';

  @override
  String get iconNameStop => 'إيقاف';

  @override
  String get iconNameNext => 'التالي';

  @override
  String get iconNamePrevious => 'السابق';

  @override
  String get iconNameVolumeUp => 'رفع الصوت';

  @override
  String get iconNameVolumeDown => 'خفض الصوت';

  @override
  String get iconNameMute => 'كتم الصوت';

  @override
  String get iconNameChannelUp => 'القناة +';

  @override
  String get iconNameChannelDown => 'القناة -';

  @override
  String get iconNamePower => 'الطاقة';

  @override
  String get iconNameMenu => 'القائمة';

  @override
  String get iconNameSettings => 'الإعدادات';

  @override
  String get iconNameInfo => 'معلومات';

  @override
  String get iconNameMic => 'ميكروفون';

  @override
  String get iconNameKeyboard => 'لوحة المفاتيح';

  @override
  String get failureDiscovery =>
      'تعذر البحث عن التلفازات. تحقق من Wi-Fi وحاول مرة أخرى.';

  @override
  String get failureConnection =>
      'تعذر الاتصال بالتلفاز. تأكد من أنه يعمل وقريب منك.';

  @override
  String get failureCommand => 'لم يصل ذلك الزر. الرجاء المحاولة مرة أخرى.';

  @override
  String get failureUnknown => 'حدث خطأ ما. الرجاء المحاولة مرة أخرى.';

  @override
  String get logoSemanticLabel => 'شعار Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'جهاز تحكم Flixsy';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDone => 'تم';

  @override
  String get removeAdsAction => 'إزالة الإعلانات';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'إزالة الإعلانات — $price';
  }

  @override
  String get restorePurchasesAction => 'استعادة المشتريات';

  @override
  String get removeAdsSuccess => 'تمت إزالة الإعلانات. شكرًا لدعمك!';

  @override
  String get removeAdsFailureCancelled => 'تم إلغاء الشراء.';

  @override
  String get removeAdsFailureProductNotFound =>
      'هذا المنتج غير متوفر حاليًا. الرجاء المحاولة لاحقًا.';

  @override
  String get removeAdsFailureNetwork =>
      'تعذر الوصول إلى المتجر. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'لم يتم العثور على مشتريات سابقة.';

  @override
  String get removeAdsFailureUnknown => 'حدث خطأ ما. الرجاء المحاولة مرة أخرى.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'تتوفر Magic Mouse على تلفازات LG webOS فقط.';

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

  @override
  String get powerSetupWebosTitle => 'شغّل تلفازك من Flixsy';

  @override
  String get powerSetupWebosIntro =>
      'يحتاج تلفاز LG إلى تفعيل إعداد واحد ليتمكن Flixsy من تنبيهه من وضع الاستعداد.';

  @override
  String get powerSetupWebosStep1 => 'افتح الإعدادات على تلفازك.';

  @override
  String get powerSetupWebosStep2 =>
      'ابحث عن «Mobile TV On» — يُسمى أحيانًا «TV On With Mobile» أو «Wake On LAN». يوجد عادةً ضمن عام → الشبكة، أو اتصال → إدارة الاتصال بالهاتف المحمول.';

  @override
  String get powerSetupWebosStep3 => 'فعّله.';

  @override
  String get powerSetupWebosTipTitle => 'لتنبيه موثوق';

  @override
  String get powerSetupWebosTipBody =>
      'اترك تلفازك موصولاً بالكهرباء. تأكد من أن هاتفك متصل بنفس شبكة Wi-Fi التي يتصل بها التلفاز.';

  @override
  String get powerSetupDismiss => 'حسناً';
}
