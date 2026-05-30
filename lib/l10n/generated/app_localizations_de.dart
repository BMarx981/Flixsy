// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Finde deinen TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Stelle sicher, dass dein TV eingeschaltet und im selben WLAN ist.';

  @override
  String get discoveryErrorTitle => 'Suche konnte nicht gestartet werden';

  @override
  String get discoveryErrorBody =>
      'Überprüfe deine Netzwerkverbindung und versuche es erneut.';

  @override
  String get discoveryRetryButton => 'Erneut versuchen';

  @override
  String get discoverySearching => 'Netzwerk wird durchsucht…';

  @override
  String get discoverySearchingHint => 'Das kann ein paar Sekunden dauern.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte gefunden',
      one: '1 Gerät gefunden',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'deinem TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Code eingeben';

  @override
  String get discoveryPairingCheckTvTitle => 'Schau auf deinen TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName zeigt einen 6-stelligen Code an. Gib ihn unten ein, um die Kopplung abzuschließen.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Bestätige die Verbindungsanfrage auf $deviceName mit dessen Fernbedienung.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Koppeln';

  @override
  String get homeTitle => 'Fernbedienung';

  @override
  String get homeBackToRadarTooltip => 'Anderen TV wählen';

  @override
  String get renameDeviceDialogTitle => 'TV umbenennen';

  @override
  String get renameDeviceFieldLabel => 'Name';

  @override
  String get renameDeviceSaveButton => 'Speichern';

  @override
  String get renameDeviceCancelButton => 'Abbrechen';

  @override
  String get renameDeviceResetButton => 'Zurücksetzen';

  @override
  String get homeLayoutsTooltip => 'Layouts';

  @override
  String get homeChangeSkinTooltip => 'Skin ändern';

  @override
  String get skinPickerApply => 'Übernehmen';

  @override
  String get skinPickerCancel => 'Abbrechen';

  @override
  String get skinPickerPreviousTooltip => 'Vorheriger Skin';

  @override
  String get skinPickerNextTooltip => 'Nächster Skin';

  @override
  String get layoutPickerTitle => 'Layouts';

  @override
  String layoutPickerLoadError(String error) {
    return 'Layouts konnten nicht geladen werden.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Integrierte Vorlage';

  @override
  String get layoutTypeCustom => 'Benutzerdefiniertes Layout';

  @override
  String get layoutActionsTooltip => 'Layout-Aktionen';

  @override
  String get layoutActionDuplicate => 'Duplizieren';

  @override
  String get layoutActionEdit => 'Bearbeiten';

  @override
  String get layoutDeleteDialogTitle => 'Layout löschen?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '„$name“ wird dauerhaft entfernt.';
  }

  @override
  String get editorTitle => 'Layout bearbeiten';

  @override
  String get editorAddBlockButton => 'Block hinzufügen';

  @override
  String get editorValidationName => 'Gib dem Layout einen Namen.';

  @override
  String get editorValidationBlocks =>
      'Füge mindestens einen Block hinzu, bevor du speicherst.';

  @override
  String get editorSavedSnack => 'Layout gespeichert.';

  @override
  String get editorPreviewLabel => 'Vorschau';

  @override
  String get editorBlocksLabel => 'Blöcke';

  @override
  String get editorNameFieldLabel => 'Layoutname';

  @override
  String get editorEmptyPreview =>
      'Füge einen Block hinzu, um eine Vorschau zu sehen';

  @override
  String get editorRemoveBlockTooltip => 'Block entfernen';

  @override
  String get editorEmptyCell => 'Leer';

  @override
  String get editorRemoveButtonTooltip => 'Schaltfläche entfernen';

  @override
  String get editorAddButtonChip => 'Hinzufügen';

  @override
  String get blockKindDpad => 'Steuerkreuz';

  @override
  String get blockKindButtonRow => 'Tastenreihe';

  @override
  String get blockKindVolume => 'Lautstärkewippe';

  @override
  String get blockKindGrid => 'Raster';

  @override
  String get blockKindSpacer => 'Abstand';

  @override
  String get blockDescDpad => 'Ein Steuerkreuz mit fünf Tasten';

  @override
  String get blockDescButtonRow => 'Eine Reihe gleichmäßig verteilter Tasten';

  @override
  String get blockDescVolume => 'Leiser / stumm / lauter';

  @override
  String get blockDescGrid => 'Ein Raster aus Tasten';

  @override
  String get blockDescSpacer => 'Leerer vertikaler Abstand zwischen Blöcken';

  @override
  String get buttonEditorTitle => 'Taste bearbeiten';

  @override
  String get buttonEditorActionLabel => 'Aktion';

  @override
  String get buttonEditorIconLabel => 'Symbol';

  @override
  String get buttonEditorShowLabel => 'Beschriftung zeigen';

  @override
  String get buttonEditorShowLabelOn =>
      'Eine Beschriftung wird auf der Taste angezeigt';

  @override
  String get buttonEditorShowLabelOff => 'Die Taste zeigt keine Beschriftung';

  @override
  String get buttonEditorLabelField => 'Beschriftung';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Leer — Standard wird verwendet: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Symbol auswählen';

  @override
  String get iconPickerDefaultSubtitle => 'Das Standardsymbol für diese Aktion';

  @override
  String get iconPickerTextOnlySubtitle => 'Beschriftung anzeigen, kein Symbol';

  @override
  String get iconPickerYourImages => 'Deine Bilder';

  @override
  String get iconPickerAddImage => 'Hinzufügen';

  @override
  String get iconPackStandardName => 'Standard';

  @override
  String get appearanceDefault => 'Standard';

  @override
  String get appearanceTextOnly => 'Nur Text';

  @override
  String get appearancePackIcon => 'Pack-Symbol';

  @override
  String get appearanceCustomImage => 'Eigenes Bild';

  @override
  String get appearanceCustomIcon => 'Eigenes Symbol';

  @override
  String get keyRoleDpad => 'Richtung';

  @override
  String get keyRoleNavigation => 'Navigation';

  @override
  String get keyRoleTransport => 'Wiedergabe';

  @override
  String get keyRoleVolume => 'Lautstärke';

  @override
  String get keyRoleChannel => 'Kanal';

  @override
  String get keyRoleSystem => 'System';

  @override
  String get remoteKeyUp => 'Hoch';

  @override
  String get remoteKeyDown => 'Runter';

  @override
  String get remoteKeyLeft => 'Links';

  @override
  String get remoteKeyRight => 'Rechts';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Zurück';

  @override
  String get remoteKeyHome => 'Startseite';

  @override
  String get remoteKeyRewind => 'Zurückspulen';

  @override
  String get remoteKeyPlayPause => 'Wiedergabe/Pause';

  @override
  String get remoteKeyFastForward => 'Vorspulen';

  @override
  String get remoteKeyNext => 'Weiter';

  @override
  String get remoteKeyPrevious => 'Zurück';

  @override
  String get remoteKeyVolumeUp => 'Lauter';

  @override
  String get remoteKeyVolumeDown => 'Leiser';

  @override
  String get remoteKeyMute => 'Stumm';

  @override
  String get remoteKeyChannelUp => 'Kanal +';

  @override
  String get remoteKeyChannelDown => 'Kanal -';

  @override
  String get remoteKeyPower => 'Ein/Aus';

  @override
  String get remoteKeySettings => 'Einstellungen';

  @override
  String get remoteKeyKeyboard => 'Tastatur';

  @override
  String get keyboardTitle => 'Auf TV tippen';

  @override
  String get keyboardHint => 'Wähle ein Textfeld auf deinem TV und tippe hier.';

  @override
  String get keyboardSendEnter => 'Eingabe senden';

  @override
  String get keyboardClose => 'Fertig';

  @override
  String get keyboardNotSupported =>
      'Dieser TV unterstützt die Texteingabe nicht.';

  @override
  String get iconNameUp => 'Hoch';

  @override
  String get iconNameDown => 'Runter';

  @override
  String get iconNameLeft => 'Links';

  @override
  String get iconNameRight => 'Rechts';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Zurück';

  @override
  String get iconNameHome => 'Startseite';

  @override
  String get iconNameRewind => 'Zurückspulen';

  @override
  String get iconNameFastForward => 'Vorspulen';

  @override
  String get iconNamePlayPause => 'Wiedergabe / Pause';

  @override
  String get iconNamePlay => 'Wiedergabe';

  @override
  String get iconNamePause => 'Pause';

  @override
  String get iconNameStop => 'Stopp';

  @override
  String get iconNameNext => 'Weiter';

  @override
  String get iconNamePrevious => 'Zurück';

  @override
  String get iconNameVolumeUp => 'Lauter';

  @override
  String get iconNameVolumeDown => 'Leiser';

  @override
  String get iconNameMute => 'Stumm';

  @override
  String get iconNameChannelUp => 'Kanal +';

  @override
  String get iconNameChannelDown => 'Kanal -';

  @override
  String get iconNamePower => 'Ein/Aus';

  @override
  String get iconNameMenu => 'Menü';

  @override
  String get iconNameSettings => 'Einstellungen';

  @override
  String get iconNameInfo => 'Info';

  @override
  String get iconNameMic => 'Mikrofon';

  @override
  String get iconNameKeyboard => 'Tastatur';

  @override
  String get failureDiscovery =>
      'TVs konnten nicht gesucht werden. Überprüfe dein WLAN und versuche es erneut.';

  @override
  String get failureConnection =>
      'Verbindung zum TV nicht möglich. Stelle sicher, dass er eingeschaltet und in der Nähe ist.';

  @override
  String get failureCommand =>
      'Diese Taste kam nicht an. Bitte versuche es erneut.';

  @override
  String get failureUnknown =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get logoSemanticLabel => 'Flixsy-Logo';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy-Fernbedienung';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDone => 'Fertig';

  @override
  String get removeAdsAction => 'Werbung entfernen';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Werbung entfernen — $price';
  }

  @override
  String get restorePurchasesAction => 'Käufe wiederherstellen';

  @override
  String get removeAdsSuccess =>
      'Werbung entfernt. Danke für deine Unterstützung!';

  @override
  String get removeAdsFailureCancelled => 'Kauf abgebrochen.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Dieses Produkt ist gerade nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get removeAdsFailureNetwork =>
      'Store nicht erreichbar. Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'Keine früheren Käufe gefunden.';

  @override
  String get removeAdsFailureUnknown =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse ist nur auf LG webOS TVs verfügbar.';

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
  String get powerSetupWebosTitle => 'Schalte deinen TV mit Flixsy ein';

  @override
  String get powerSetupWebosIntro =>
      'Damit Flixsy deinen LG TV aus dem Standby aufwecken kann, muss eine Einstellung am TV aktiviert sein.';

  @override
  String get powerSetupWebosStep1 => 'Öffne die Einstellungen auf deinem TV.';

  @override
  String get powerSetupWebosStep2 =>
      'Suche „Mobile TV On“ — je nach Modell auch „TV On With Mobile“ oder „Wake On LAN“. Es befindet sich meist unter Allgemein → Netzwerk oder Verbindung → Mobile Verbindungsverwaltung.';

  @override
  String get powerSetupWebosStep3 => 'Aktiviere es.';

  @override
  String get powerSetupWebosTipTitle => 'Für zuverlässiges Aufwecken';

  @override
  String get powerSetupWebosTipBody =>
      'Lass deinen TV eingesteckt. Achte darauf, dass dein Telefon im selben Wi-Fi-Netzwerk wie der TV ist.';

  @override
  String get powerSetupDismiss => 'Verstanden';
}
