// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Trova la tua TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Assicurati che la TV sia accesa e collegata alla stessa rete Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'Impossibile avviare la ricerca';

  @override
  String get discoveryErrorBody =>
      'Controlla la tua connessione di rete e riprova.';

  @override
  String get discoveryRetryButton => 'Riprova';

  @override
  String get discoverySearching => 'Ricerca nella tua rete…';

  @override
  String get discoverySearchingHint => 'Potrebbe richiedere alcuni secondi.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivi trovati',
      one: '1 dispositivo trovato',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'la tua TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Inserisci il codice';

  @override
  String get discoveryPairingCheckTvTitle => 'Guarda la tua TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName sta mostrando un codice a 6 cifre. Digitalo qui sotto per completare l\'associazione.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Accetta la richiesta di connessione su $deviceName con il suo telecomando.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Associa';

  @override
  String get homeTitle => 'Telecomando';

  @override
  String get homeBackToRadarTooltip => 'Scegli un\'altra TV';

  @override
  String get renameDeviceDialogTitle => 'Rinomina TV';

  @override
  String get renameDeviceFieldLabel => 'Nome';

  @override
  String get renameDeviceSaveButton => 'Salva';

  @override
  String get renameDeviceCancelButton => 'Annulla';

  @override
  String get renameDeviceResetButton => 'Ripristina';

  @override
  String get homeLayoutsTooltip => 'Layout';

  @override
  String get homeChangeSkinTooltip => 'Cambia tema';

  @override
  String get skinPickerApply => 'Applica';

  @override
  String get skinPickerCancel => 'Annulla';

  @override
  String get skinPickerPreviousTooltip => 'Tema precedente';

  @override
  String get skinPickerNextTooltip => 'Tema successivo';

  @override
  String get layoutPickerTitle => 'Layout';

  @override
  String layoutPickerLoadError(String error) {
    return 'Impossibile caricare i layout.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Modello integrato';

  @override
  String get layoutTypeCustom => 'Layout personalizzato';

  @override
  String get layoutActionsTooltip => 'Azioni layout';

  @override
  String get layoutActionDuplicate => 'Duplica';

  @override
  String get layoutActionEdit => 'Modifica';

  @override
  String get layoutDeleteDialogTitle => 'Eliminare il layout?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\" verrà rimosso definitivamente.';
  }

  @override
  String get editorTitle => 'Modifica layout';

  @override
  String get editorAddBlockButton => 'Aggiungi blocco';

  @override
  String get editorValidationName => 'Assegna un nome al layout.';

  @override
  String get editorValidationBlocks =>
      'Aggiungi almeno un blocco prima di salvare.';

  @override
  String get editorSavedSnack => 'Layout salvato.';

  @override
  String get editorPreviewLabel => 'Anteprima';

  @override
  String get editorBlocksLabel => 'Blocchi';

  @override
  String get editorNameFieldLabel => 'Nome del layout';

  @override
  String get editorEmptyPreview =>
      'Aggiungi un blocco per vedere un\'anteprima';

  @override
  String get editorRemoveBlockTooltip => 'Rimuovi blocco';

  @override
  String get editorEmptyCell => 'Vuoto';

  @override
  String get editorRemoveButtonTooltip => 'Rimuovi pulsante';

  @override
  String get editorAddButtonChip => 'Aggiungi';

  @override
  String get blockKindDpad => 'Croce direzionale';

  @override
  String get blockKindButtonRow => 'Riga di pulsanti';

  @override
  String get blockKindVolume => 'Bilanciere volume';

  @override
  String get blockKindGrid => 'Griglia';

  @override
  String get blockKindSpacer => 'Spaziatore';

  @override
  String get blockDescDpad => 'Una croce direzionale a cinque pulsanti';

  @override
  String get blockDescButtonRow => 'Una riga di pulsanti equidistanti';

  @override
  String get blockDescVolume => 'Volume giù / muto / volume su';

  @override
  String get blockDescGrid => 'Una griglia di pulsanti';

  @override
  String get blockDescSpacer => 'Spazio verticale vuoto tra i blocchi';

  @override
  String get buttonEditorTitle => 'Modifica pulsante';

  @override
  String get buttonEditorActionLabel => 'Azione';

  @override
  String get buttonEditorIconLabel => 'Icona';

  @override
  String get buttonEditorShowLabel => 'Mostra etichetta';

  @override
  String get buttonEditorShowLabelOn =>
      'Sul pulsante viene mostrata una didascalia';

  @override
  String get buttonEditorShowLabelOff =>
      'Il pulsante non mostra alcuna didascalia';

  @override
  String get buttonEditorLabelField => 'Etichetta';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Vuoto — utilizzo del predefinito: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Scegli icona';

  @override
  String get iconPickerDefaultSubtitle => 'L\'icona standard per questa azione';

  @override
  String get iconPickerTextOnlySubtitle => 'Mostra l\'etichetta, senza icona';

  @override
  String get iconPickerYourImages => 'Le tue immagini';

  @override
  String get iconPickerAddImage => 'Aggiungi';

  @override
  String get iconPackStandardName => 'Standard';

  @override
  String get appearanceDefault => 'Predefinito';

  @override
  String get appearanceTextOnly => 'Solo testo';

  @override
  String get appearancePackIcon => 'Icona del pacchetto';

  @override
  String get appearanceCustomImage => 'Immagine personalizzata';

  @override
  String get appearanceCustomIcon => 'Icona personalizzata';

  @override
  String get keyRoleDpad => 'Direzionale';

  @override
  String get keyRoleNavigation => 'Navigazione';

  @override
  String get keyRoleTransport => 'Riproduzione';

  @override
  String get keyRoleVolume => 'Volume';

  @override
  String get keyRoleChannel => 'Canale';

  @override
  String get keyRoleSystem => 'Sistema';

  @override
  String get remoteKeyUp => 'Su';

  @override
  String get remoteKeyDown => 'Giù';

  @override
  String get remoteKeyLeft => 'Sinistra';

  @override
  String get remoteKeyRight => 'Destra';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Indietro';

  @override
  String get remoteKeyHome => 'Home';

  @override
  String get remoteKeyRewind => 'Riavvolgi';

  @override
  String get remoteKeyPlayPause => 'Play/Pausa';

  @override
  String get remoteKeyFastForward => 'Avanti veloce';

  @override
  String get remoteKeyNext => 'Avanti';

  @override
  String get remoteKeyPrevious => 'Precedente';

  @override
  String get remoteKeyVolumeUp => 'Volume +';

  @override
  String get remoteKeyVolumeDown => 'Volume -';

  @override
  String get remoteKeyMute => 'Muto';

  @override
  String get remoteKeyChannelUp => 'Canale +';

  @override
  String get remoteKeyChannelDown => 'Canale -';

  @override
  String get remoteKeyPower => 'Accensione';

  @override
  String get remoteKeySettings => 'Impostazioni';

  @override
  String get remoteKeyKeyboard => 'Tastiera';

  @override
  String get keyboardTitle => 'Scrivi sulla TV';

  @override
  String get keyboardHint =>
      'Seleziona un campo di testo sulla TV, poi digita qui.';

  @override
  String get keyboardSendEnter => 'Invia Invio';

  @override
  String get keyboardClose => 'Fine';

  @override
  String get keyboardNotSupported =>
      'Questa TV non supporta la digitazione remota.';

  @override
  String get iconNameUp => 'Su';

  @override
  String get iconNameDown => 'Giù';

  @override
  String get iconNameLeft => 'Sinistra';

  @override
  String get iconNameRight => 'Destra';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Indietro';

  @override
  String get iconNameHome => 'Home';

  @override
  String get iconNameRewind => 'Riavvolgi';

  @override
  String get iconNameFastForward => 'Avanti veloce';

  @override
  String get iconNamePlayPause => 'Play / Pausa';

  @override
  String get iconNamePlay => 'Play';

  @override
  String get iconNamePause => 'Pausa';

  @override
  String get iconNameStop => 'Stop';

  @override
  String get iconNameNext => 'Avanti';

  @override
  String get iconNamePrevious => 'Precedente';

  @override
  String get iconNameVolumeUp => 'Volume +';

  @override
  String get iconNameVolumeDown => 'Volume -';

  @override
  String get iconNameMute => 'Muto';

  @override
  String get iconNameChannelUp => 'Canale +';

  @override
  String get iconNameChannelDown => 'Canale -';

  @override
  String get iconNamePower => 'Accensione';

  @override
  String get iconNameMenu => 'Menu';

  @override
  String get iconNameSettings => 'Impostazioni';

  @override
  String get iconNameInfo => 'Info';

  @override
  String get iconNameMic => 'Microfono';

  @override
  String get iconNameKeyboard => 'Tastiera';

  @override
  String get failureDiscovery =>
      'Impossibile cercare TV. Controlla il Wi-Fi e riprova.';

  @override
  String get failureConnection =>
      'Impossibile connettersi alla TV. Assicurati che sia accesa e nelle vicinanze.';

  @override
  String get failureCommand => 'Quel pulsante non è arrivato. Riprova.';

  @override
  String get failureUnknown => 'Qualcosa è andato storto. Riprova.';

  @override
  String get logoSemanticLabel => 'Logo Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'Telecomando Flixsy';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonDone => 'Fine';

  @override
  String get removeAdsAction => 'Rimuovi pubblicità';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Rimuovi pubblicità — $price';
  }

  @override
  String get restorePurchasesAction => 'Ripristina acquisti';

  @override
  String get removeAdsSuccess =>
      'Pubblicità rimosse. Grazie per il tuo supporto!';

  @override
  String get removeAdsFailureCancelled => 'Acquisto annullato.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Questo prodotto non è disponibile al momento. Riprova più tardi.';

  @override
  String get removeAdsFailureNetwork =>
      'Impossibile raggiungere lo store. Controlla la connessione e riprova.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'Nessun acquisto precedente trovato.';

  @override
  String get removeAdsFailureUnknown => 'Qualcosa è andato storto. Riprova.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse è disponibile solo sulle TV LG webOS.';

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
