// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'Encontre a sua TV';

  @override
  String get discoveryHeaderSubtitle =>
      'Verifique se a sua TV está ligada e conectada à mesma rede Wi-Fi.';

  @override
  String get discoveryErrorTitle => 'Não foi possível iniciar a busca';

  @override
  String get discoveryErrorBody =>
      'Verifique a sua conexão de rede e tente novamente.';

  @override
  String get discoveryRetryButton => 'Tentar de novo';

  @override
  String get discoverySearching => 'Procurando na sua rede…';

  @override
  String get discoverySearchingHint => 'Isto pode levar alguns segundos.';

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
  String get discoveryDeviceFallbackName => 'a sua TV';

  @override
  String get discoveryPairingEnterCodeTitle => 'Digite o código';

  @override
  String get discoveryPairingCheckTvTitle => 'Olhe para a sua TV';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName está exibindo um código de 6 dígitos. Digite-o abaixo para concluir o pareamento.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return 'Aceite a solicitação de conexão na $deviceName usando o seu controle remoto.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'Parear';

  @override
  String get homeTitle => 'Controle';

  @override
  String get homeBackToRadarTooltip => 'Escolher outra TV';

  @override
  String get renameDeviceDialogTitle => 'Renomear TV';

  @override
  String get renameDeviceFieldLabel => 'Nome';

  @override
  String get renameDeviceSaveButton => 'Salvar';

  @override
  String get renameDeviceCancelButton => 'Cancelar';

  @override
  String get renameDeviceResetButton => 'Redefinir';

  @override
  String get homeLayoutsTooltip => 'Layouts';

  @override
  String get homeChangeSkinTooltip => 'Alterar tema';

  @override
  String get skinPickerApply => 'Aplicar';

  @override
  String get skinPickerCancel => 'Cancelar';

  @override
  String get skinPickerPreviousTooltip => 'Tema anterior';

  @override
  String get skinPickerNextTooltip => 'Próximo tema';

  @override
  String get layoutPickerTitle => 'Layouts';

  @override
  String layoutPickerLoadError(String error) {
    return 'Não foi possível carregar os layouts.\n$error';
  }

  @override
  String get layoutTypeTemplate => 'Modelo integrado';

  @override
  String get layoutTypeCustom => 'Layout personalizado';

  @override
  String get layoutActionsTooltip => 'Ações do layout';

  @override
  String get layoutActionDuplicate => 'Duplicar';

  @override
  String get layoutActionEdit => 'Editar';

  @override
  String get layoutDeleteDialogTitle => 'Excluir layout?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\" será removido permanentemente.';
  }

  @override
  String get editorTitle => 'Editar layout';

  @override
  String get editorAddBlockButton => 'Adicionar bloco';

  @override
  String get editorValidationName => 'Dê um nome ao layout.';

  @override
  String get editorValidationBlocks =>
      'Adicione pelo menos um bloco antes de salvar.';

  @override
  String get editorSavedSnack => 'Layout salvo.';

  @override
  String get editorPreviewLabel => 'Pré-visualização';

  @override
  String get editorBlocksLabel => 'Blocos';

  @override
  String get editorNameFieldLabel => 'Nome do layout';

  @override
  String get editorEmptyPreview =>
      'Adicione um bloco para ver uma pré-visualização';

  @override
  String get editorRemoveBlockTooltip => 'Remover bloco';

  @override
  String get editorEmptyCell => 'Vazio';

  @override
  String get editorRemoveButtonTooltip => 'Remover botão';

  @override
  String get editorAddButtonChip => 'Adicionar';

  @override
  String get blockKindDpad => 'Direcional';

  @override
  String get blockKindButtonRow => 'Linha de botões';

  @override
  String get blockKindVolume => 'Controle de volume';

  @override
  String get blockKindGrid => 'Grade';

  @override
  String get blockKindSpacer => 'Espaçador';

  @override
  String get blockDescDpad => 'Uma cruz direcional de cinco botões';

  @override
  String get blockDescButtonRow =>
      'Uma linha de botões uniformemente espaçados';

  @override
  String get blockDescVolume => 'Diminuir / mudo / aumentar volume';

  @override
  String get blockDescGrid => 'Uma grade de botões';

  @override
  String get blockDescSpacer => 'Espaço vertical em branco entre blocos';

  @override
  String get buttonEditorTitle => 'Editar botão';

  @override
  String get buttonEditorActionLabel => 'Ação';

  @override
  String get buttonEditorIconLabel => 'Ícone';

  @override
  String get buttonEditorShowLabel => 'Mostrar rótulo';

  @override
  String get buttonEditorShowLabelOn => 'Um rótulo é mostrado no botão';

  @override
  String get buttonEditorShowLabelOff => 'O botão não mostra rótulo';

  @override
  String get buttonEditorLabelField => 'Rótulo';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return 'Vazio — usando o padrão: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'Escolher ícone';

  @override
  String get iconPickerDefaultSubtitle => 'O ícone padrão para esta ação';

  @override
  String get iconPickerTextOnlySubtitle => 'Mostrar o rótulo, sem ícone';

  @override
  String get iconPickerYourImages => 'Suas imagens';

  @override
  String get iconPickerAddImage => 'Adicionar';

  @override
  String get iconPackStandardName => 'Padrão';

  @override
  String get appearanceDefault => 'Padrão';

  @override
  String get appearanceTextOnly => 'Apenas texto';

  @override
  String get appearancePackIcon => 'Ícone do pacote';

  @override
  String get appearanceCustomImage => 'Imagem personalizada';

  @override
  String get appearanceCustomIcon => 'Ícone personalizado';

  @override
  String get keyRoleDpad => 'Direcional';

  @override
  String get keyRoleNavigation => 'Navegação';

  @override
  String get keyRoleTransport => 'Reprodução';

  @override
  String get keyRoleVolume => 'Volume';

  @override
  String get keyRoleChannel => 'Canal';

  @override
  String get keyRoleSystem => 'Sistema';

  @override
  String get remoteKeyUp => 'Cima';

  @override
  String get remoteKeyDown => 'Baixo';

  @override
  String get remoteKeyLeft => 'Esquerda';

  @override
  String get remoteKeyRight => 'Direita';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => 'Voltar';

  @override
  String get remoteKeyHome => 'Início';

  @override
  String get remoteKeyRewind => 'Retroceder';

  @override
  String get remoteKeyPlayPause => 'Reproduzir/Pausar';

  @override
  String get remoteKeyFastForward => 'Avançar rápido';

  @override
  String get remoteKeyNext => 'Próximo';

  @override
  String get remoteKeyPrevious => 'Anterior';

  @override
  String get remoteKeyVolumeUp => 'Aumentar volume';

  @override
  String get remoteKeyVolumeDown => 'Diminuir volume';

  @override
  String get remoteKeyMute => 'Mudo';

  @override
  String get remoteKeyChannelUp => 'Canal +';

  @override
  String get remoteKeyChannelDown => 'Canal -';

  @override
  String get remoteKeyPower => 'Energia';

  @override
  String get remoteKeySettings => 'Configurações';

  @override
  String get remoteKeyKeyboard => 'Teclado';

  @override
  String get keyboardTitle => 'Digitar na TV';

  @override
  String get keyboardHint =>
      'Selecione um campo de texto na sua TV e digite aqui.';

  @override
  String get keyboardSendEnter => 'Enviar Enter';

  @override
  String get keyboardClose => 'Concluído';

  @override
  String get keyboardNotSupported => 'Esta TV não suporta digitação remota.';

  @override
  String get iconNameUp => 'Cima';

  @override
  String get iconNameDown => 'Baixo';

  @override
  String get iconNameLeft => 'Esquerda';

  @override
  String get iconNameRight => 'Direita';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => 'Voltar';

  @override
  String get iconNameHome => 'Início';

  @override
  String get iconNameRewind => 'Retroceder';

  @override
  String get iconNameFastForward => 'Avançar rápido';

  @override
  String get iconNamePlayPause => 'Reproduzir / Pausar';

  @override
  String get iconNamePlay => 'Reproduzir';

  @override
  String get iconNamePause => 'Pausar';

  @override
  String get iconNameStop => 'Parar';

  @override
  String get iconNameNext => 'Próximo';

  @override
  String get iconNamePrevious => 'Anterior';

  @override
  String get iconNameVolumeUp => 'Aumentar volume';

  @override
  String get iconNameVolumeDown => 'Diminuir volume';

  @override
  String get iconNameMute => 'Mudo';

  @override
  String get iconNameChannelUp => 'Canal +';

  @override
  String get iconNameChannelDown => 'Canal -';

  @override
  String get iconNamePower => 'Energia';

  @override
  String get iconNameMenu => 'Menu';

  @override
  String get iconNameSettings => 'Configurações';

  @override
  String get iconNameInfo => 'Informações';

  @override
  String get iconNameMic => 'Microfone';

  @override
  String get iconNameKeyboard => 'Teclado';

  @override
  String get failureDiscovery =>
      'Não foi possível buscar TVs. Verifique o seu Wi-Fi e tente novamente.';

  @override
  String get failureConnection =>
      'Não foi possível conectar à TV. Verifique se ela está ligada e por perto.';

  @override
  String get failureCommand => 'Esse botão não foi entregue. Tente novamente.';

  @override
  String get failureUnknown => 'Algo deu errado. Tente novamente.';

  @override
  String get logoSemanticLabel => 'Logotipo Flixsy';

  @override
  String get mainRemoteSemanticLabel => 'Controle Flixsy';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonDone => 'Concluído';

  @override
  String get removeAdsAction => 'Remover anúncios';

  @override
  String removeAdsActionWithPrice(String price) {
    return 'Remover anúncios — $price';
  }

  @override
  String get restorePurchasesAction => 'Restaurar compras';

  @override
  String get removeAdsSuccess => 'Anúncios removidos. Obrigado pelo apoio!';

  @override
  String get removeAdsFailureCancelled => 'Compra cancelada.';

  @override
  String get removeAdsFailureProductNotFound =>
      'Este produto não está disponível no momento. Tente novamente mais tarde.';

  @override
  String get removeAdsFailureNetwork =>
      'Não foi possível acessar a loja. Verifique a sua conexão e tente novamente.';

  @override
  String get removeAdsFailureNothingToRestore =>
      'Nenhuma compra anterior encontrada.';

  @override
  String get removeAdsFailureUnknown => 'Algo deu errado. Tente novamente.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse só está disponível em TVs LG webOS.';
}
