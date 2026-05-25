// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => 'TV 찾기';

  @override
  String get discoveryHeaderSubtitle =>
      'TV가 켜져 있고 같은 Wi-Fi 네트워크에 연결되어 있는지 확인하세요.';

  @override
  String get discoveryErrorTitle => '검색을 시작할 수 없습니다';

  @override
  String get discoveryErrorBody => '네트워크 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get discoveryRetryButton => '다시 시도';

  @override
  String get discoverySearching => '네트워크에서 검색 중…';

  @override
  String get discoverySearchingHint => '몇 초 정도 걸릴 수 있습니다.';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '기기 $count대 찾음',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'TV';

  @override
  String get discoveryPairingEnterCodeTitle => '코드 입력';

  @override
  String get discoveryPairingCheckTvTitle => 'TV를 확인하세요';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName에 6자리 코드가 표시되어 있습니다. 아래에 입력하여 페어링을 완료하세요.';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return '$deviceName의 리모컨으로 연결 요청을 수락하세요.';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => '페어링';

  @override
  String get homeTitle => '리모컨';

  @override
  String get homeBackToRadarTooltip => '다른 TV 선택';

  @override
  String get renameDeviceDialogTitle => 'TV 이름 변경';

  @override
  String get renameDeviceFieldLabel => '이름';

  @override
  String get renameDeviceSaveButton => '저장';

  @override
  String get renameDeviceCancelButton => '취소';

  @override
  String get renameDeviceResetButton => '재설정';

  @override
  String get homeLayoutsTooltip => '레이아웃';

  @override
  String get homeChangeSkinTooltip => '스킨 변경';

  @override
  String get skinPickerApply => '적용';

  @override
  String get skinPickerCancel => '취소';

  @override
  String get skinPickerPreviousTooltip => '이전 스킨';

  @override
  String get skinPickerNextTooltip => '다음 스킨';

  @override
  String get layoutPickerTitle => '레이아웃';

  @override
  String layoutPickerLoadError(String error) {
    return '레이아웃을 불러올 수 없습니다.\n$error';
  }

  @override
  String get layoutTypeTemplate => '기본 제공 템플릿';

  @override
  String get layoutTypeCustom => '사용자 지정 레이아웃';

  @override
  String get layoutActionsTooltip => '레이아웃 작업';

  @override
  String get layoutActionDuplicate => '복제';

  @override
  String get layoutActionEdit => '편집';

  @override
  String get layoutDeleteDialogTitle => '레이아웃을 삭제할까요?';

  @override
  String layoutDeleteDialogBody(String name) {
    return '\"$name\"이(가) 영구적으로 삭제됩니다.';
  }

  @override
  String get editorTitle => '레이아웃 편집';

  @override
  String get editorAddBlockButton => '블록 추가';

  @override
  String get editorValidationName => '레이아웃 이름을 입력하세요.';

  @override
  String get editorValidationBlocks => '저장하기 전에 블록을 하나 이상 추가하세요.';

  @override
  String get editorSavedSnack => '레이아웃이 저장되었습니다.';

  @override
  String get editorPreviewLabel => '미리보기';

  @override
  String get editorBlocksLabel => '블록';

  @override
  String get editorNameFieldLabel => '레이아웃 이름';

  @override
  String get editorEmptyPreview => '블록을 추가하면 미리보기가 표시됩니다';

  @override
  String get editorRemoveBlockTooltip => '블록 제거';

  @override
  String get editorEmptyCell => '비어 있음';

  @override
  String get editorRemoveButtonTooltip => '버튼 제거';

  @override
  String get editorAddButtonChip => '추가';

  @override
  String get blockKindDpad => '방향 키';

  @override
  String get blockKindButtonRow => '버튼 행';

  @override
  String get blockKindVolume => '볼륨 컨트롤';

  @override
  String get blockKindGrid => '그리드';

  @override
  String get blockKindSpacer => '간격';

  @override
  String get blockDescDpad => '5버튼 방향 키';

  @override
  String get blockDescButtonRow => '균일한 간격의 버튼 행';

  @override
  String get blockDescVolume => '볼륨 다운 / 음소거 / 볼륨 업';

  @override
  String get blockDescGrid => '버튼 그리드';

  @override
  String get blockDescSpacer => '블록 사이의 빈 세로 공간';

  @override
  String get buttonEditorTitle => '버튼 편집';

  @override
  String get buttonEditorActionLabel => '동작';

  @override
  String get buttonEditorIconLabel => '아이콘';

  @override
  String get buttonEditorShowLabel => '라벨 표시';

  @override
  String get buttonEditorShowLabelOn => '버튼에 캡션이 표시됩니다';

  @override
  String get buttonEditorShowLabelOff => '버튼에 캡션이 표시되지 않습니다';

  @override
  String get buttonEditorLabelField => '라벨';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return '비어 있음 — 기본값 사용: $defaultLabel';
  }

  @override
  String get iconPickerTitle => '아이콘 선택';

  @override
  String get iconPickerDefaultSubtitle => '이 동작의 기본 아이콘';

  @override
  String get iconPickerTextOnlySubtitle => '아이콘 없이 라벨만 표시';

  @override
  String get iconPickerYourImages => '내 이미지';

  @override
  String get iconPickerAddImage => '추가';

  @override
  String get iconPackStandardName => '표준';

  @override
  String get appearanceDefault => '기본값';

  @override
  String get appearanceTextOnly => '텍스트만';

  @override
  String get appearancePackIcon => '팩 아이콘';

  @override
  String get appearanceCustomImage => '사용자 지정 이미지';

  @override
  String get appearanceCustomIcon => '사용자 지정 아이콘';

  @override
  String get keyRoleDpad => '방향';

  @override
  String get keyRoleNavigation => '탐색';

  @override
  String get keyRoleTransport => '재생';

  @override
  String get keyRoleVolume => '볼륨';

  @override
  String get keyRoleChannel => '채널';

  @override
  String get keyRoleSystem => '시스템';

  @override
  String get remoteKeyUp => '위';

  @override
  String get remoteKeyDown => '아래';

  @override
  String get remoteKeyLeft => '왼쪽';

  @override
  String get remoteKeyRight => '오른쪽';

  @override
  String get remoteKeyOk => '확인';

  @override
  String get remoteKeyBack => '뒤로';

  @override
  String get remoteKeyHome => '홈';

  @override
  String get remoteKeyRewind => '되감기';

  @override
  String get remoteKeyPlayPause => '재생/일시정지';

  @override
  String get remoteKeyFastForward => '빨리 감기';

  @override
  String get remoteKeyNext => '다음';

  @override
  String get remoteKeyPrevious => '이전';

  @override
  String get remoteKeyVolumeUp => '볼륨 업';

  @override
  String get remoteKeyVolumeDown => '볼륨 다운';

  @override
  String get remoteKeyMute => '음소거';

  @override
  String get remoteKeyChannelUp => '채널 +';

  @override
  String get remoteKeyChannelDown => '채널 -';

  @override
  String get remoteKeyPower => '전원';

  @override
  String get remoteKeySettings => '설정';

  @override
  String get remoteKeyKeyboard => '키보드';

  @override
  String get keyboardTitle => 'TV에 입력';

  @override
  String get keyboardHint => 'TV에서 텍스트 필드를 선택한 다음 여기에 입력하세요.';

  @override
  String get keyboardSendEnter => 'Enter 전송';

  @override
  String get keyboardClose => '완료';

  @override
  String get keyboardNotSupported => '이 TV는 원격 입력을 지원하지 않습니다.';

  @override
  String get iconNameUp => '위';

  @override
  String get iconNameDown => '아래';

  @override
  String get iconNameLeft => '왼쪽';

  @override
  String get iconNameRight => '오른쪽';

  @override
  String get iconNameOk => '확인';

  @override
  String get iconNameBack => '뒤로';

  @override
  String get iconNameHome => '홈';

  @override
  String get iconNameRewind => '되감기';

  @override
  String get iconNameFastForward => '빨리 감기';

  @override
  String get iconNamePlayPause => '재생 / 일시정지';

  @override
  String get iconNamePlay => '재생';

  @override
  String get iconNamePause => '일시정지';

  @override
  String get iconNameStop => '정지';

  @override
  String get iconNameNext => '다음';

  @override
  String get iconNamePrevious => '이전';

  @override
  String get iconNameVolumeUp => '볼륨 업';

  @override
  String get iconNameVolumeDown => '볼륨 다운';

  @override
  String get iconNameMute => '음소거';

  @override
  String get iconNameChannelUp => '채널 +';

  @override
  String get iconNameChannelDown => '채널 -';

  @override
  String get iconNamePower => '전원';

  @override
  String get iconNameMenu => '메뉴';

  @override
  String get iconNameSettings => '설정';

  @override
  String get iconNameInfo => '정보';

  @override
  String get iconNameMic => '마이크';

  @override
  String get iconNameKeyboard => '키보드';

  @override
  String get failureDiscovery => 'TV를 검색할 수 없습니다. Wi-Fi를 확인하고 다시 시도하세요.';

  @override
  String get failureConnection => 'TV에 연결할 수 없습니다. 켜져 있고 가까이 있는지 확인하세요.';

  @override
  String get failureCommand => '버튼이 전달되지 않았습니다. 다시 시도하세요.';

  @override
  String get failureUnknown => '문제가 발생했습니다. 다시 시도하세요.';

  @override
  String get logoSemanticLabel => 'Flixsy 로고';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy 리모컨';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonSave => '저장';

  @override
  String get commonDone => '완료';

  @override
  String get removeAdsAction => '광고 제거';

  @override
  String removeAdsActionWithPrice(String price) {
    return '광고 제거 — $price';
  }

  @override
  String get restorePurchasesAction => '구매 복원';

  @override
  String get removeAdsSuccess => '광고가 제거되었습니다. 지원해 주셔서 감사합니다!';

  @override
  String get removeAdsFailureCancelled => '구매가 취소되었습니다.';

  @override
  String get removeAdsFailureProductNotFound =>
      '이 상품은 현재 사용할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String get removeAdsFailureNetwork => '스토어에 연결할 수 없습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get removeAdsFailureNothingToRestore => '이전 구매 내역이 없습니다.';

  @override
  String get removeAdsFailureUnknown => '문제가 발생했습니다. 다시 시도하세요.';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse는 LG webOS TV에서만 사용할 수 있습니다.';
}
