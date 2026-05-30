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
  String get discoveryHeaderTitle => 'テレビを探す';

  @override
  String get discoveryHeaderSubtitle =>
      'テレビの電源を入れ、同じ Wi-Fi ネットワークに接続していることを確認してください。';

  @override
  String get discoveryErrorTitle => '検索を開始できませんでした';

  @override
  String get discoveryErrorBody => 'ネットワーク接続を確認してもう一度お試しください。';

  @override
  String get discoveryRetryButton => '再試行';

  @override
  String get discoverySearching => 'ネットワークを検索中…';

  @override
  String get discoverySearchingHint => '数秒かかる場合があります。';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台のデバイスが見つかりました',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => 'テレビ';

  @override
  String get discoveryPairingEnterCodeTitle => 'コードを入力';

  @override
  String get discoveryPairingCheckTvTitle => 'テレビを確認';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName に 6 桁のコードが表示されています。下に入力してペアリングを完了してください。';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return '$deviceName のリモコンで接続リクエストを承認してください。';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => 'ペアリング';

  @override
  String get homeTitle => 'リモコン';

  @override
  String get homeBackToRadarTooltip => '別のテレビを選ぶ';

  @override
  String get renameDeviceDialogTitle => 'テレビの名前を変更';

  @override
  String get renameDeviceFieldLabel => '名前';

  @override
  String get renameDeviceSaveButton => '保存';

  @override
  String get renameDeviceCancelButton => 'キャンセル';

  @override
  String get renameDeviceResetButton => 'リセット';

  @override
  String get homeLayoutsTooltip => 'レイアウト';

  @override
  String get homeChangeSkinTooltip => 'スキンを変更';

  @override
  String get skinPickerApply => '適用';

  @override
  String get skinPickerCancel => 'キャンセル';

  @override
  String get skinPickerPreviousTooltip => '前のスキン';

  @override
  String get skinPickerNextTooltip => '次のスキン';

  @override
  String get layoutPickerTitle => 'レイアウト';

  @override
  String layoutPickerLoadError(String error) {
    return 'レイアウトを読み込めませんでした。\n$error';
  }

  @override
  String get layoutTypeTemplate => '組み込みテンプレート';

  @override
  String get layoutTypeCustom => 'カスタム レイアウト';

  @override
  String get layoutActionsTooltip => 'レイアウトの操作';

  @override
  String get layoutActionDuplicate => '複製';

  @override
  String get layoutActionEdit => '編集';

  @override
  String get layoutDeleteDialogTitle => 'レイアウトを削除しますか？';

  @override
  String layoutDeleteDialogBody(String name) {
    return '「$name」は完全に削除されます。';
  }

  @override
  String get editorTitle => 'レイアウトを編集';

  @override
  String get editorAddBlockButton => 'ブロックを追加';

  @override
  String get editorValidationName => 'レイアウトに名前を付けてください。';

  @override
  String get editorValidationBlocks => '保存する前に少なくとも 1 つのブロックを追加してください。';

  @override
  String get editorSavedSnack => 'レイアウトを保存しました。';

  @override
  String get editorPreviewLabel => 'プレビュー';

  @override
  String get editorBlocksLabel => 'ブロック';

  @override
  String get editorNameFieldLabel => 'レイアウト名';

  @override
  String get editorEmptyPreview => 'ブロックを追加するとプレビューが表示されます';

  @override
  String get editorRemoveBlockTooltip => 'ブロックを削除';

  @override
  String get editorEmptyCell => '空';

  @override
  String get editorRemoveButtonTooltip => 'ボタンを削除';

  @override
  String get editorAddButtonChip => '追加';

  @override
  String get blockKindDpad => '十字キー';

  @override
  String get blockKindButtonRow => 'ボタンの列';

  @override
  String get blockKindVolume => '音量コントロール';

  @override
  String get blockKindGrid => 'グリッド';

  @override
  String get blockKindSpacer => 'スペーサー';

  @override
  String get blockDescDpad => '5 ボタンの十字キー';

  @override
  String get blockDescButtonRow => '等間隔に並んだボタンの列';

  @override
  String get blockDescVolume => '音量ダウン / ミュート / 音量アップ';

  @override
  String get blockDescGrid => 'ボタンのグリッド';

  @override
  String get blockDescSpacer => 'ブロック間の縦方向の空白';

  @override
  String get buttonEditorTitle => 'ボタンを編集';

  @override
  String get buttonEditorActionLabel => 'アクション';

  @override
  String get buttonEditorIconLabel => 'アイコン';

  @override
  String get buttonEditorShowLabel => 'ラベルを表示';

  @override
  String get buttonEditorShowLabelOn => 'ボタンにキャプションが表示されます';

  @override
  String get buttonEditorShowLabelOff => 'ボタンにキャプションは表示されません';

  @override
  String get buttonEditorLabelField => 'ラベル';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return '空欄 — デフォルトを使用: $defaultLabel';
  }

  @override
  String get iconPickerTitle => 'アイコンを選択';

  @override
  String get iconPickerDefaultSubtitle => 'このアクションの標準アイコン';

  @override
  String get iconPickerTextOnlySubtitle => 'アイコンなしでラベルを表示';

  @override
  String get iconPickerYourImages => 'あなたの画像';

  @override
  String get iconPickerAddImage => '追加';

  @override
  String get iconPackStandardName => '標準';

  @override
  String get appearanceDefault => 'デフォルト';

  @override
  String get appearanceTextOnly => 'テキストのみ';

  @override
  String get appearancePackIcon => 'パックアイコン';

  @override
  String get appearanceCustomImage => 'カスタム画像';

  @override
  String get appearanceCustomIcon => 'カスタムアイコン';

  @override
  String get keyRoleDpad => '方向';

  @override
  String get keyRoleNavigation => 'ナビゲーション';

  @override
  String get keyRoleTransport => '再生';

  @override
  String get keyRoleVolume => '音量';

  @override
  String get keyRoleChannel => 'チャンネル';

  @override
  String get keyRoleSystem => 'システム';

  @override
  String get remoteKeyUp => '上';

  @override
  String get remoteKeyDown => '下';

  @override
  String get remoteKeyLeft => '左';

  @override
  String get remoteKeyRight => '右';

  @override
  String get remoteKeyOk => 'OK';

  @override
  String get remoteKeyBack => '戻る';

  @override
  String get remoteKeyHome => 'ホーム';

  @override
  String get remoteKeyRewind => '巻き戻し';

  @override
  String get remoteKeyPlayPause => '再生/一時停止';

  @override
  String get remoteKeyFastForward => '早送り';

  @override
  String get remoteKeyNext => '次へ';

  @override
  String get remoteKeyPrevious => '前へ';

  @override
  String get remoteKeyVolumeUp => '音量アップ';

  @override
  String get remoteKeyVolumeDown => '音量ダウン';

  @override
  String get remoteKeyMute => 'ミュート';

  @override
  String get remoteKeyChannelUp => 'チャンネル +';

  @override
  String get remoteKeyChannelDown => 'チャンネル -';

  @override
  String get remoteKeyPower => '電源';

  @override
  String get remoteKeySettings => '設定';

  @override
  String get remoteKeyKeyboard => 'キーボード';

  @override
  String get keyboardTitle => 'テレビに入力';

  @override
  String get keyboardHint => 'テレビのテキストフィールドを選択してからここに入力してください。';

  @override
  String get keyboardSendEnter => 'Enter を送信';

  @override
  String get keyboardClose => '完了';

  @override
  String get keyboardNotSupported => 'このテレビはリモート入力に対応していません。';

  @override
  String get iconNameUp => '上';

  @override
  String get iconNameDown => '下';

  @override
  String get iconNameLeft => '左';

  @override
  String get iconNameRight => '右';

  @override
  String get iconNameOk => 'OK';

  @override
  String get iconNameBack => '戻る';

  @override
  String get iconNameHome => 'ホーム';

  @override
  String get iconNameRewind => '巻き戻し';

  @override
  String get iconNameFastForward => '早送り';

  @override
  String get iconNamePlayPause => '再生 / 一時停止';

  @override
  String get iconNamePlay => '再生';

  @override
  String get iconNamePause => '一時停止';

  @override
  String get iconNameStop => '停止';

  @override
  String get iconNameNext => '次へ';

  @override
  String get iconNamePrevious => '前へ';

  @override
  String get iconNameVolumeUp => '音量アップ';

  @override
  String get iconNameVolumeDown => '音量ダウン';

  @override
  String get iconNameMute => 'ミュート';

  @override
  String get iconNameChannelUp => 'チャンネル +';

  @override
  String get iconNameChannelDown => 'チャンネル -';

  @override
  String get iconNamePower => '電源';

  @override
  String get iconNameMenu => 'メニュー';

  @override
  String get iconNameSettings => '設定';

  @override
  String get iconNameInfo => '情報';

  @override
  String get iconNameMic => 'マイク';

  @override
  String get iconNameKeyboard => 'キーボード';

  @override
  String get failureDiscovery => 'テレビを検索できませんでした。Wi-Fi を確認してもう一度お試しください。';

  @override
  String get failureConnection => 'テレビに接続できませんでした。電源が入っていて近くにあることを確認してください。';

  @override
  String get failureCommand => 'そのボタンは届きませんでした。もう一度お試しください。';

  @override
  String get failureUnknown => '問題が発生しました。もう一度お試しください。';

  @override
  String get logoSemanticLabel => 'Flixsy ロゴ';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy リモコン';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonSave => '保存';

  @override
  String get commonDone => '完了';

  @override
  String get removeAdsAction => '広告を削除';

  @override
  String removeAdsActionWithPrice(String price) {
    return '広告を削除 — $price';
  }

  @override
  String get restorePurchasesAction => '購入を復元';

  @override
  String get removeAdsSuccess => '広告を削除しました。ご支援ありがとうございます！';

  @override
  String get removeAdsFailureCancelled => '購入をキャンセルしました。';

  @override
  String get removeAdsFailureProductNotFound => '現在この商品は利用できません。後でもう一度お試しください。';

  @override
  String get removeAdsFailureNetwork => 'ストアに接続できませんでした。接続を確認してもう一度お試しください。';

  @override
  String get removeAdsFailureNothingToRestore => '以前の購入は見つかりませんでした。';

  @override
  String get removeAdsFailureUnknown => '問題が発生しました。もう一度お試しください。';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip =>
      'Magic Mouse は LG webOS テレビでのみ使用できます。';

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
  String get powerSetupWebosTitle => 'Flixsy からテレビを起動する';

  @override
  String get powerSetupWebosIntro =>
      'Flixsy が待機状態からテレビを起動できるよう、LG テレビで設定を 1 つ有効にする必要があります。';

  @override
  String get powerSetupWebosStep1 => 'テレビの設定を開きます。';

  @override
  String get powerSetupWebosStep2 =>
      '「Mobile TV On」を探します — 機種によっては「TV On With Mobile」または「Wake On LAN」と表示されることもあります。通常は 一般 → ネットワーク、または 接続 → モバイル接続管理 にあります。';

  @override
  String get powerSetupWebosStep3 => 'オンにします。';

  @override
  String get powerSetupWebosTipTitle => '確実に起動するために';

  @override
  String get powerSetupWebosTipBody =>
      'テレビの電源プラグは挿したままにしてください。スマートフォンとテレビが同じ Wi-Fi ネットワークに接続されていることを確認してください。';

  @override
  String get powerSetupDismiss => 'OK';
}
