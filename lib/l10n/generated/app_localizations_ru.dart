// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Найдите свой ТВ';

  @override
  String get discoveryHeaderSubtitle =>
      'Убедитесь, что телевизор включён и подключён к той же сети Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'Не удалось начать поиск';

  @override
  String get discoveryErrorBody =>
      'Проверьте подключение к сети и попробуйте снова.';

  @override
  String get discoveryRetryButton => 'Повторить';

  @override
  String get discoverySearching => 'Поиск в вашей сети…';

  @override
  String get discoverySearchingHint => 'Это может занять несколько секунд.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count устройства',
      many: 'Найдено $count устройств',
      few: 'Найдено $count устройства',
      one: 'Найдено $count устройство',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'вашем ТВ';

  @override
  String get discoveryPairingEnterCodeTitle => 'Введите код';

  @override
  String get discoveryPairingCheckTvTitle => 'Посмотрите на ТВ';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return 'На $deviceName отображается 6-значный код. Введите его ниже, чтобы завершить сопряжение.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Подтвердите запрос на подключение на $deviceName с помощью пульта.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Сопрячь';

  @override
  String get homeTitle => 'Пульт';

  @override
  String get homeBackToRadarTooltip => 'Выбрать другой ТВ';

  @override
  String get renameDeviceDialogTitle => 'Переименовать ТВ';

  @override
  String get renameDeviceFieldLabel => 'Имя';

  @override
  String get renameDeviceSaveButton => 'Сохранить';

  @override
  String get renameDeviceCancelButton => 'Отмена';

  @override
  String get renameDeviceResetButton => 'Сбросить';

  @override
  String get homeLayoutsTooltip => 'Макеты';

  @override
  String get homeChangeSkinTooltip => 'Сменить тему';

  @override
  String get skinPickerApply => 'Применить';

  @override
  String get skinPickerCancel => 'Отмена';

  @override
  String get skinPickerPreviousTooltip => 'Предыдущая тема';

  @override
  String get skinPickerNextTooltip => 'Следующая тема';

  @override
  String get layoutPickerTitle => 'Макеты';

  @override
  String layoutPickerLoadError(String error) {
    return 'Не удалось загрузить макеты.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Встроенный шаблон';

  @override
  String get layoutTypeCustom => 'Свой макет';

  @override
  String get layoutActionsTooltip => 'Действия с макетом';

  @override
  String get layoutActionDuplicate => 'Дублировать';

  @override
  String get layoutActionEdit => 'Изменить';

  @override
  String get layoutDeleteDialogTitle => 'Удалить макет?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '«$name» будет удалён без возможности восстановления.';
  }

  @override
  String get editorTitle => 'Изменить макет';

  @override
  String get editorAddBlockButton => 'Добавить блок';

  @override
  String get editorValidationName => 'Дайте макету название.';

  @override
  String get editorValidationBlocks =>
      'Добавьте хотя бы один блок перед сохранением.';

  @override
  String get editorSavedSnack => 'Макет сохранён.';

  @override
  String get editorPreviewLabel => 'Предпросмотр';

  @override
  String get editorBlocksLabel => 'Блоки';

  @override
  String get editorNameFieldLabel => 'Название макета';

  @override
  String get editorEmptyPreview => 'Добавьте блок, чтобы увидеть предпросмотр';

  @override
  String get editorRemoveBlockTooltip => 'Удалить блок';

  @override
  String get editorEmptyCell => 'Пусто';

  @override
  String get editorRemoveButtonTooltip => 'Удалить кнопку';

  @override
  String get editorAddButtonChip => 'Добавить';

  @override
  String get blockKindDpad => 'D-pad';

  @override
  String get blockKindButtonRow => 'Ряд кнопок';

  @override
  String get blockKindVolume => 'Регулятор громкости';

  @override
  String get blockKindGrid => 'Сетка';

  @override
  String get blockKindSpacer => 'Разделитель';

  @override
  String get blockDescDpad => 'Пятикнопочный направляющий крест';

  @override
  String get blockDescButtonRow => 'Ряд равномерно расположенных кнопок';

  @override
  String get blockDescVolume => 'Тише / без звука / громче';

  @override
  String get blockDescGrid => 'Сетка кнопок';

  @override
  String get blockDescSpacer =>
      'Пустое вертикальное пространство между блоками';

  @override
  String get buttonEditorTitle => 'Изменить кнопку';

  @override
  String get buttonEditorActionLabel => 'Действие';

  @override
  String get buttonEditorIconLabel => 'Значок';

  @override
  String get buttonEditorShowLabel => 'Показывать подпись';

  @override
  String get buttonEditorShowLabelOn => 'На кнопке отображается подпись';

  @override
  String get buttonEditorShowLabelOff => 'На кнопке нет подписи';

  @override
  String get buttonEditorLabelField => 'Подпись';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Пусто — используется по умолчанию: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Выбрать значок';

  @override
  String get iconPickerDefaultSubtitle =>
      'Стандартный значок для этого действия';

  @override
  String get iconPickerTextOnlySubtitle => 'Показать подпись без значка';

  @override
  String get iconPickerYourImages => 'Ваши изображения';

  @override
  String get iconPickerAddImage => 'Добавить';

  @override
  String get iconPackStandardName => 'Стандартный';

  @override
  String get appearanceDefault => 'По умолчанию';

  @override
  String get appearanceTextOnly => 'Только текст';

  @override
  String get appearancePackIcon => 'Значок из набора';

  @override
  String get appearanceCustomImage => 'Своё изображение';

  @override
  String get appearanceCustomIcon => 'Свой значок';

  @override
  String get keyRoleDpad => 'Направления';

  @override
  String get keyRoleNavigation => 'Навигация';

  @override
  String get keyRoleTransport => 'Воспроизведение';

  @override
  String get keyRoleVolume => 'Громкость';

  @override
  String get keyRoleChannel => 'Канал';

  @override
  String get keyRoleSystem => 'Система';

  @override
  String get remoteKeyUp => 'Вверх';

  @override
  String get remoteKeyDown => 'Вниз';

  @override
  String get remoteKeyLeft => 'Влево';

  @override
  String get remoteKeyRight => 'Вправо';

  @override
  String get remoteKeyOk => 'ОК';

  @override
  String get remoteKeyBack => 'Назад';

  @override
  String get remoteKeyHome => 'Главная';

  @override
  String get remoteKeyRewind => 'Перемотка назад';

  @override
  String get remoteKeyPlayPause => 'Воспр./Пауза';

  @override
  String get remoteKeyFastForward => 'Перемотка вперёд';

  @override
  String get remoteKeyNext => 'Далее';

  @override
  String get remoteKeyPrevious => 'Назад';

  @override
  String get remoteKeyVolumeUp => 'Громче';

  @override
  String get remoteKeyVolumeDown => 'Тише';

  @override
  String get remoteKeyMute => 'Без звука';

  @override
  String get remoteKeyChannelUp => 'Канал +';

  @override
  String get remoteKeyChannelDown => 'Канал -';

  @override
  String get remoteKeyPower => 'Питание';

  @override
  String get remoteKeySettings => 'Настройки';

  @override
  String get remoteKeyKeyboard => 'Клавиатура';

  @override
  String get keyboardTitle => 'Ввод на ТВ';

  @override
  String get keyboardHint => 'Выберите текстовое поле на ТВ и вводите здесь.';

  @override
  String get keyboardSendEnter => 'Отправить Enter';

  @override
  String get keyboardClose => 'Готово';

  @override
  String get keyboardNotSupported => 'Этот ТВ не поддерживает удалённый ввод.';

  @override
  String get iconNameUp => 'Вверх';

  @override
  String get iconNameDown => 'Вниз';

  @override
  String get iconNameLeft => 'Влево';

  @override
  String get iconNameRight => 'Вправо';

  @override
  String get iconNameOk => 'ОК';

  @override
  String get iconNameBack => 'Назад';

  @override
  String get iconNameHome => 'Главная';

  @override
  String get iconNameRewind => 'Перемотка назад';

  @override
  String get iconNameFastForward => 'Перемотка вперёд';

  @override
  String get iconNamePlayPause => 'Воспр. / Пауза';

  @override
  String get iconNamePlay => 'Воспр.';

  @override
  String get iconNamePause => 'Пауза';

  @override
  String get iconNameStop => 'Стоп';

  @override
  String get iconNameNext => 'Далее';

  @override
  String get iconNamePrevious => 'Назад';

  @override
  String get iconNameVolumeUp => 'Громче';

  @override
  String get iconNameVolumeDown => 'Тише';

  @override
  String get iconNameMute => 'Без звука';

  @override
  String get iconNameChannelUp => 'Канал +';

  @override
  String get iconNameChannelDown => 'Канал -';

  @override
  String get iconNamePower => 'Питание';

  @override
  String get iconNameMenu => 'Меню';

  @override
  String get iconNameSettings => 'Настройки';

  @override
  String get iconNameInfo => 'Инфо';

  @override
  String get iconNameMic => 'Микрофон';

  @override
  String get iconNameKeyboard => 'Клавиатура';

  @override
  String get failureDiscovery =>
      'Не удалось найти ТВ. Проверьте Wi-Fi и повторите.';

  @override
  String get failureConnection =>
      'Не удалось подключиться к ТВ. Убедитесь, что он включён и рядом.';

  @override
  String get failureCommand => 'Кнопка не сработала. Попробуйте снова.';

  @override
  String get failureUnknown => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get logoSemanticLabel => 'Логотип Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'Пульт Flixsy';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDone => 'Готово';

  @override
  String get removeAdsAction => 'Убрать рекламу';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Убрать рекламу — $price';
  }

  @override
  String get restorePurchasesAction => 'Восстановить покупки';

  @override
  String get removeAdsSuccess => 'Реклама отключена. Спасибо за поддержку!';

  @override
  String get removeAdsFailureCancelled => 'Покупка отменена.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Этот продукт сейчас недоступен. Повторите попытку позже.';

  @override
  String get removeAdsFailureNetwork =>
      'Не удалось связаться с магазином. Проверьте соединение и повторите.';

  @override
  String get removeAdsFailureNothingToRestore => 'Прежние покупки не найдены.';

  @override
  String get removeAdsFailureUnknown =>
      'Что-то пошло не так. Повторите попытку.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse доступен только на ТВ LG webOS.';

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
