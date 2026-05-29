// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Trouvez votre TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Assurez-vous que votre TV est allumé et connecté au même réseau Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'Impossible de lancer la recherche';

  @override
  String get discoveryErrorBody =>
      'Vérifiez votre connexion réseau et réessayez.';

  @override
  String get discoveryRetryButton => 'Réessayer';

  @override
  String get discoverySearching => 'Recherche sur votre réseau…';

  @override
  String get discoverySearchingHint => 'Cela peut prendre quelques secondes.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils trouvés',
      one: '1 appareil trouvé',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'votre TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Saisissez le code';

  @override
  String get discoveryPairingCheckTvTitle => 'Regardez votre TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName affiche un code à 6 chiffres. Saisissez-le ci-dessous pour terminer l\'appairage.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Acceptez la demande de connexion sur $deviceName avec sa télécommande.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Appairer';

  @override
  String get homeTitle => 'Télécommande';

  @override
  String get homeBackToRadarTooltip => 'Choisir un autre TV';

  @override
  String get renameDeviceDialogTitle => 'Renommer le TV';

  @override
  String get renameDeviceFieldLabel => 'Nom';

  @override
  String get renameDeviceSaveButton => 'Enregistrer';

  @override
  String get renameDeviceCancelButton => 'Annuler';

  @override
  String get renameDeviceResetButton => 'Réinitialiser';

  @override
  String get homeLayoutsTooltip => 'Dispositions';

  @override
  String get homeChangeSkinTooltip => 'Changer de thème';

  @override
  String get skinPickerApply => 'Appliquer';

  @override
  String get skinPickerCancel => 'Annuler';

  @override
  String get skinPickerPreviousTooltip => 'Thème précédent';

  @override
  String get skinPickerNextTooltip => 'Thème suivant';

  @override
  String get layoutPickerTitle => 'Dispositions';

  @override
  String layoutPickerLoadError(String error) {
    return 'Impossible de charger les dispositions.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Modèle intégré';

  @override
  String get layoutTypeCustom => 'Disposition personnalisée';

  @override
  String get layoutActionsTooltip => 'Actions de la disposition';

  @override
  String get layoutActionDuplicate => 'Dupliquer';

  @override
  String get layoutActionEdit => 'Modifier';

  @override
  String get layoutDeleteDialogTitle => 'Supprimer la disposition ?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '« $name » sera supprimée définitivement.';
  }

  @override
  String get editorTitle => 'Modifier la disposition';

  @override
  String get editorAddBlockButton => 'Ajouter un bloc';

  @override
  String get editorValidationName => 'Donnez un nom à la disposition.';

  @override
  String get editorValidationBlocks =>
      'Ajoutez au moins un bloc avant d\'enregistrer.';

  @override
  String get editorSavedSnack => 'Disposition enregistrée.';

  @override
  String get editorPreviewLabel => 'Aperçu';

  @override
  String get editorBlocksLabel => 'Blocs';

  @override
  String get editorNameFieldLabel => 'Nom de la disposition';

  @override
  String get editorEmptyPreview => 'Ajoutez un bloc pour voir un aperçu';

  @override
  String get editorRemoveBlockTooltip => 'Supprimer le bloc';

  @override
  String get editorEmptyCell => 'Vide';

  @override
  String get editorRemoveButtonTooltip => 'Supprimer le bouton';

  @override
  String get editorAddButtonChip => 'Ajouter';

  @override
  String get blockKindDpad => 'Croix directionnelle';

  @override
  String get blockKindButtonRow => 'Rangée de boutons';

  @override
  String get blockKindVolume => 'Bascule de volume';

  @override
  String get blockKindGrid => 'Grille';

  @override
  String get blockKindSpacer => 'Espaceur';

  @override
  String get blockDescDpad => 'Une croix directionnelle à cinq boutons';

  @override
  String get blockDescButtonRow =>
      'Une rangée de boutons régulièrement espacés';

  @override
  String get blockDescVolume => 'Volume bas / muet / volume haut';

  @override
  String get blockDescGrid => 'Une grille de boutons';

  @override
  String get blockDescSpacer => 'Espace vertical vide entre les blocs';

  @override
  String get buttonEditorTitle => 'Modifier le bouton';

  @override
  String get buttonEditorActionLabel => 'Action';

  @override
  String get buttonEditorIconLabel => 'Icône';

  @override
  String get buttonEditorShowLabel => 'Afficher le libellé';

  @override
  String get buttonEditorShowLabelOn => 'Un libellé est affiché sur le bouton';

  @override
  String get buttonEditorShowLabelOff => 'Le bouton n\'affiche aucun libellé';

  @override
  String get buttonEditorLabelField => 'Libellé';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Vide — utilisation de la valeur par défaut : $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Choisir une icône';

  @override
  String get iconPickerDefaultSubtitle => 'L\'icône standard pour cette action';

  @override
  String get iconPickerTextOnlySubtitle => 'Afficher le libellé, sans icône';

  @override
  String get iconPickerYourImages => 'Vos images';

  @override
  String get iconPickerAddImage => 'Ajouter';

  @override
  String get iconPackStandardName => 'Standard';

  @override
  String get appearanceDefault => 'Par défaut';

  @override
  String get appearanceTextOnly => 'Texte uniquement';

  @override
  String get appearancePackIcon => 'Icône du pack';

  @override
  String get appearanceCustomImage => 'Image personnalisée';

  @override
  String get appearanceCustomIcon => 'Icône personnalisée';

  @override
  String get keyRoleDpad => 'Directionnel';

  @override
  String get keyRoleNavigation => 'Navigation';

  @override
  String get keyRoleTransport => 'Lecture';

  @override
  String get keyRoleVolume => 'Volume';

  @override
  String get keyRoleChannel => 'Chaîne';

  @override
  String get keyRoleSystem => 'Système';

  @override
  String get remoteKeyUp => 'Haut';

  @override
  String get remoteKeyDown => 'Bas';

  @override
  String get remoteKeyLeft => 'Gauche';

  @override
  String get remoteKeyRight => 'Droite';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Retour';

  @override
  String get remoteKeyHome => 'Accueil';

  @override
  String get remoteKeyRewind => 'Retour rapide';

  @override
  String get remoteKeyPlayPause => 'Lecture/Pause';

  @override
  String get remoteKeyFastForward => 'Avance rapide';

  @override
  String get remoteKeyNext => 'Suivant';

  @override
  String get remoteKeyPrevious => 'Précédent';

  @override
  String get remoteKeyVolumeUp => 'Volume +';

  @override
  String get remoteKeyVolumeDown => 'Volume -';

  @override
  String get remoteKeyMute => 'Muet';

  @override
  String get remoteKeyChannelUp => 'Chaîne +';

  @override
  String get remoteKeyChannelDown => 'Chaîne -';

  @override
  String get remoteKeyPower => 'Marche/Arrêt';

  @override
  String get remoteKeySettings => 'Paramètres';

  @override
  String get remoteKeyKeyboard => 'Clavier';

  @override
  String get keyboardTitle => 'Saisir sur le TV';

  @override
  String get keyboardHint =>
      'Sélectionnez un champ de texte sur votre TV, puis saisissez ici.';

  @override
  String get keyboardSendEnter => 'Envoyer Entrée';

  @override
  String get keyboardClose => 'Terminé';

  @override
  String get keyboardNotSupported =>
      'Ce TV ne prend pas en charge la saisie à distance.';

  @override
  String get iconNameUp => 'Haut';

  @override
  String get iconNameDown => 'Bas';

  @override
  String get iconNameLeft => 'Gauche';

  @override
  String get iconNameRight => 'Droite';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Retour';

  @override
  String get iconNameHome => 'Accueil';

  @override
  String get iconNameRewind => 'Retour rapide';

  @override
  String get iconNameFastForward => 'Avance rapide';

  @override
  String get iconNamePlayPause => 'Lecture / Pause';

  @override
  String get iconNamePlay => 'Lecture';

  @override
  String get iconNamePause => 'Pause';

  @override
  String get iconNameStop => 'Arrêt';

  @override
  String get iconNameNext => 'Suivant';

  @override
  String get iconNamePrevious => 'Précédent';

  @override
  String get iconNameVolumeUp => 'Volume +';

  @override
  String get iconNameVolumeDown => 'Volume -';

  @override
  String get iconNameMute => 'Muet';

  @override
  String get iconNameChannelUp => 'Chaîne +';

  @override
  String get iconNameChannelDown => 'Chaîne -';

  @override
  String get iconNamePower => 'Marche/Arrêt';

  @override
  String get iconNameMenu => 'Menu';

  @override
  String get iconNameSettings => 'Paramètres';

  @override
  String get iconNameInfo => 'Infos';

  @override
  String get iconNameMic => 'Microphone';

  @override
  String get iconNameKeyboard => 'Clavier';

  @override
  String get failureDiscovery =>
      'Impossible de rechercher des TVs. Vérifiez votre Wi-Fi et réessayez.';

  @override
  String get failureConnection =>
      'Impossible de se connecter au TV. Assurez-vous qu\'il est allumé et à proximité.';

  @override
  String get failureCommand =>
      'Ce bouton n\'est pas passé. Veuillez réessayer.';

  @override
  String get failureUnknown =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get logoSemanticLabel => 'Logo Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'Télécommande Flixsy';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get removeAdsAction => 'Supprimer les publicités';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Supprimer les publicités — $price';
  }

  @override
  String get restorePurchasesAction => 'Restaurer les achats';

  @override
  String get removeAdsSuccess =>
      'Publicités supprimées. Merci pour votre soutien !';

  @override
  String get removeAdsFailureCancelled => 'Achat annulé.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Ce produit n\'est pas disponible pour le moment. Réessayez plus tard.';

  @override
  String get removeAdsFailureNetwork =>
      'Impossible de joindre la boutique. Vérifiez votre connexion et réessayez.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'Aucun achat précédent trouvé.';

  @override
  String get removeAdsFailureUnknown =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse n\'est disponible que sur les TVs LG webOS.';

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
