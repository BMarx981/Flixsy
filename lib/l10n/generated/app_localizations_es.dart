// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Busca tu TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Asegúrate de que tu TV esté encendido y conectado a la misma red Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'No se pudo iniciar la búsqueda';

  @override
  String get discoveryErrorBody =>
      'Comprueba tu conexión de red e inténtalo de nuevo.';

  @override
  String get discoveryRetryButton => 'Reintentar';

  @override
  String get discoverySearching => 'Buscando en tu red…';

  @override
  String get discoverySearchingHint => 'Esto puede tardar unos segundos.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos encontrados',
      one: '1 dispositivo encontrado',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'tu TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Introduce el código';

  @override
  String get discoveryPairingCheckTvTitle => 'Mira tu TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName está mostrando un código de 6 dígitos. Escríbelo abajo para finalizar el emparejamiento.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Acepta la solicitud de conexión en $deviceName con su mando a distancia.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Emparejar';

  @override
  String get homeTitle => 'Mando';

  @override
  String get homeBackToRadarTooltip => 'Elegir otro TV';

  @override
  String get renameDeviceDialogTitle => 'Renombrar TV';

  @override
  String get renameDeviceFieldLabel => 'Nombre';

  @override
  String get renameDeviceSaveButton => 'Guardar';

  @override
  String get renameDeviceCancelButton => 'Cancelar';

  @override
  String get renameDeviceResetButton => 'Restablecer';

  @override
  String get homeLayoutsTooltip => 'Diseños';

  @override
  String get homeChangeSkinTooltip => 'Cambiar tema';

  @override
  String get skinPickerApply => 'Aplicar';

  @override
  String get skinPickerCancel => 'Cancelar';

  @override
  String get skinPickerPreviousTooltip => 'Tema anterior';

  @override
  String get skinPickerNextTooltip => 'Tema siguiente';

  @override
  String get layoutPickerTitle => 'Diseños';

  @override
  String layoutPickerLoadError(String error) {
    return 'No se pudieron cargar los diseños.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Plantilla integrada';

  @override
  String get layoutTypeCustom => 'Diseño personalizado';

  @override
  String get layoutActionsTooltip => 'Acciones del diseño';

  @override
  String get layoutActionDuplicate => 'Duplicar';

  @override
  String get layoutActionEdit => 'Editar';

  @override
  String get layoutDeleteDialogTitle => '¿Eliminar diseño?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\" se eliminará de forma permanente.';
  }

  @override
  String get editorTitle => 'Editar diseño';

  @override
  String get editorAddBlockButton => 'Añadir bloque';

  @override
  String get editorValidationName => 'Asigna un nombre al diseño.';

  @override
  String get editorValidationBlocks =>
      'Añade al menos un bloque antes de guardar.';

  @override
  String get editorSavedSnack => 'Diseño guardado.';

  @override
  String get editorPreviewLabel => 'Vista previa';

  @override
  String get editorBlocksLabel => 'Bloques';

  @override
  String get editorNameFieldLabel => 'Nombre del diseño';

  @override
  String get editorEmptyPreview => 'Añade un bloque para ver una vista previa';

  @override
  String get editorRemoveBlockTooltip => 'Quitar bloque';

  @override
  String get editorEmptyCell => 'Vacío';

  @override
  String get editorRemoveButtonTooltip => 'Quitar botón';

  @override
  String get editorAddButtonChip => 'Añadir';

  @override
  String get blockKindDpad => 'Cruceta';

  @override
  String get blockKindButtonRow => 'Fila de botones';

  @override
  String get blockKindVolume => 'Control de volumen';

  @override
  String get blockKindGrid => 'Cuadrícula';

  @override
  String get blockKindSpacer => 'Espaciador';

  @override
  String get blockDescDpad => 'Una cruz direccional de cinco botones';

  @override
  String get blockDescButtonRow =>
      'Una fila de botones espaciados uniformemente';

  @override
  String get blockDescVolume => 'Bajar volumen / silenciar / subir volumen';

  @override
  String get blockDescGrid => 'Una cuadrícula de botones';

  @override
  String get blockDescSpacer => 'Espacio vertical en blanco entre bloques';

  @override
  String get buttonEditorTitle => 'Editar botón';

  @override
  String get buttonEditorActionLabel => 'Acción';

  @override
  String get buttonEditorIconLabel => 'Icono';

  @override
  String get buttonEditorShowLabel => 'Mostrar etiqueta';

  @override
  String get buttonEditorShowLabelOn => 'Se muestra un texto en el botón';

  @override
  String get buttonEditorShowLabelOff => 'El botón no muestra texto';

  @override
  String get buttonEditorLabelField => 'Etiqueta';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Vacío — usando el predeterminado: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Elegir icono';

  @override
  String get iconPickerDefaultSubtitle => 'El icono estándar para esta acción';

  @override
  String get iconPickerTextOnlySubtitle => 'Mostrar la etiqueta, sin icono';

  @override
  String get iconPickerYourImages => 'Tus imágenes';

  @override
  String get iconPickerAddImage => 'Añadir';

  @override
  String get iconPackStandardName => 'Estándar';

  @override
  String get appearanceDefault => 'Predeterminado';

  @override
  String get appearanceTextOnly => 'Solo texto';

  @override
  String get appearancePackIcon => 'Icono del paquete';

  @override
  String get appearanceCustomImage => 'Imagen personalizada';

  @override
  String get appearanceCustomIcon => 'Icono personalizado';

  @override
  String get keyRoleDpad => 'Direccional';

  @override
  String get keyRoleNavigation => 'Navegación';

  @override
  String get keyRoleTransport => 'Reproducción';

  @override
  String get keyRoleVolume => 'Volumen';

  @override
  String get keyRoleChannel => 'Canal';

  @override
  String get keyRoleSystem => 'Sistema';

  @override
  String get remoteKeyUp => 'Arriba';

  @override
  String get remoteKeyDown => 'Abajo';

  @override
  String get remoteKeyLeft => 'Izquierda';

  @override
  String get remoteKeyRight => 'Derecha';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Atrás';

  @override
  String get remoteKeyHome => 'Inicio';

  @override
  String get remoteKeyRewind => 'Rebobinar';

  @override
  String get remoteKeyPlayPause => 'Reproducir/Pausar';

  @override
  String get remoteKeyFastForward => 'Avance rápido';

  @override
  String get remoteKeyNext => 'Siguiente';

  @override
  String get remoteKeyPrevious => 'Anterior';

  @override
  String get remoteKeyVolumeUp => 'Subir volumen';

  @override
  String get remoteKeyVolumeDown => 'Bajar volumen';

  @override
  String get remoteKeyMute => 'Silenciar';

  @override
  String get remoteKeyChannelUp => 'Canal arriba';

  @override
  String get remoteKeyChannelDown => 'Canal abajo';

  @override
  String get remoteKeyPower => 'Encendido';

  @override
  String get remoteKeySettings => 'Ajustes';

  @override
  String get remoteKeyKeyboard => 'Teclado';

  @override
  String get keyboardTitle => 'Escribir en el TV';

  @override
  String get keyboardHint =>
      'Selecciona un campo de texto en tu TV y escribe aquí.';

  @override
  String get keyboardSendEnter => 'Enviar Intro';

  @override
  String get keyboardClose => 'Listo';

  @override
  String get keyboardNotSupported => 'Este TV no admite la escritura remota.';

  @override
  String get iconNameUp => 'Arriba';

  @override
  String get iconNameDown => 'Abajo';

  @override
  String get iconNameLeft => 'Izquierda';

  @override
  String get iconNameRight => 'Derecha';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Atrás';

  @override
  String get iconNameHome => 'Inicio';

  @override
  String get iconNameRewind => 'Rebobinar';

  @override
  String get iconNameFastForward => 'Avance rápido';

  @override
  String get iconNamePlayPause => 'Reproducir / Pausar';

  @override
  String get iconNamePlay => 'Reproducir';

  @override
  String get iconNamePause => 'Pausar';

  @override
  String get iconNameStop => 'Detener';

  @override
  String get iconNameNext => 'Siguiente';

  @override
  String get iconNamePrevious => 'Anterior';

  @override
  String get iconNameVolumeUp => 'Subir volumen';

  @override
  String get iconNameVolumeDown => 'Bajar volumen';

  @override
  String get iconNameMute => 'Silenciar';

  @override
  String get iconNameChannelUp => 'Canal arriba';

  @override
  String get iconNameChannelDown => 'Canal abajo';

  @override
  String get iconNamePower => 'Encendido';

  @override
  String get iconNameMenu => 'Menú';

  @override
  String get iconNameSettings => 'Ajustes';

  @override
  String get iconNameInfo => 'Información';

  @override
  String get iconNameMic => 'Micrófono';

  @override
  String get iconNameKeyboard => 'Teclado';

  @override
  String get failureDiscovery =>
      'No se pudieron buscar TVs. Comprueba tu Wi-Fi e inténtalo de nuevo.';

  @override
  String get failureConnection =>
      'No se pudo conectar al TV. Asegúrate de que esté encendido y cerca.';

  @override
  String get failureCommand => 'Ese botón no llegó. Inténtalo de nuevo.';

  @override
  String get failureUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get logoSemanticLabel => 'Logotipo de Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'Mando Flixsy';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDone => 'Listo';

  @override
  String get removeAdsAction => 'Quitar anuncios';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Quitar anuncios — $price';
  }

  @override
  String get restorePurchasesAction => 'Restaurar compras';

  @override
  String get removeAdsSuccess => 'Anuncios eliminados. ¡Gracias por tu apoyo!';

  @override
  String get removeAdsFailureCancelled => 'Compra cancelada.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Este producto no está disponible ahora. Inténtalo más tarde.';

  @override
  String get removeAdsFailureNetwork =>
      'No se pudo conectar con la tienda. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'No se encontraron compras anteriores.';

  @override
  String get removeAdsFailureUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse solo está disponible en TVs LG webOS.';

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
