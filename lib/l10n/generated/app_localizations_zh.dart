// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flixsy';

  @override
  String get discoveryHeaderTitle => '查找你的电视';

  @override
  String get discoveryHeaderSubtitle => '请确保电视已打开并连接到同一 Wi-Fi 网络。';

  @override
  String get discoveryErrorTitle => '无法开始搜索';

  @override
  String get discoveryErrorBody => '请检查网络连接后重试。';

  @override
  String get discoveryRetryButton => '重试';

  @override
  String get discoverySearching => '正在搜索你的网络…';

  @override
  String get discoverySearchingHint => '可能需要几秒钟。';

  @override
  String discoveryDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到 $count 个设备',
    );
    return '$_temp0';
  }

  @override
  String get discoveryDeviceFallbackName => '电视';

  @override
  String get discoveryPairingEnterCodeTitle => '输入验证码';

  @override
  String get discoveryPairingCheckTvTitle => '查看你的电视';

  @override
  String discoveryPairingEnterCodeBody(String deviceName) {
    return '$deviceName 正在显示一个 6 位代码。请在下方输入以完成配对。';
  }

  @override
  String discoveryPairingCheckTvBody(String deviceName) {
    return '请用 $deviceName 的遥控器接受连接请求。';
  }

  @override
  String get discoveryPairingCodeHint => '000000';

  @override
  String get discoveryPairButton => '配对';

  @override
  String get homeTitle => '遥控器';

  @override
  String get homeBackToRadarTooltip => '选择其他电视';

  @override
  String get renameDeviceDialogTitle => '重命名电视';

  @override
  String get renameDeviceFieldLabel => '名称';

  @override
  String get renameDeviceSaveButton => '保存';

  @override
  String get renameDeviceCancelButton => '取消';

  @override
  String get renameDeviceResetButton => '重置';

  @override
  String get homeLayoutsTooltip => '布局';

  @override
  String get homeChangeSkinTooltip => '更换皮肤';

  @override
  String get skinPickerApply => '应用';

  @override
  String get skinPickerCancel => '取消';

  @override
  String get skinPickerPreviousTooltip => '上一个皮肤';

  @override
  String get skinPickerNextTooltip => '下一个皮肤';

  @override
  String get layoutPickerTitle => '布局';

  @override
  String layoutPickerLoadError(String error) {
    return '无法加载布局。\n$error';
  }

  @override
  String get layoutTypeTemplate => '内置模板';

  @override
  String get layoutTypeCustom => '自定义布局';

  @override
  String get layoutActionsTooltip => '布局操作';

  @override
  String get layoutActionDuplicate => '复制';

  @override
  String get layoutActionEdit => '编辑';

  @override
  String get layoutDeleteDialogTitle => '删除此布局？';

  @override
  String layoutDeleteDialogBody(String name) {
    return '“$name”将被永久删除。';
  }

  @override
  String get editorTitle => '编辑布局';

  @override
  String get editorAddBlockButton => '添加块';

  @override
  String get editorValidationName => '请为布局命名。';

  @override
  String get editorValidationBlocks => '保存前请至少添加一个块。';

  @override
  String get editorSavedSnack => '布局已保存。';

  @override
  String get editorPreviewLabel => '预览';

  @override
  String get editorBlocksLabel => '块';

  @override
  String get editorNameFieldLabel => '布局名称';

  @override
  String get editorEmptyPreview => '添加块后即可预览';

  @override
  String get editorRemoveBlockTooltip => '移除块';

  @override
  String get editorEmptyCell => '空';

  @override
  String get editorRemoveButtonTooltip => '移除按钮';

  @override
  String get editorAddButtonChip => '添加';

  @override
  String get blockKindDpad => '方向键';

  @override
  String get blockKindButtonRow => '按钮行';

  @override
  String get blockKindVolume => '音量摇杆';

  @override
  String get blockKindGrid => '网格';

  @override
  String get blockKindSpacer => '间隔';

  @override
  String get blockDescDpad => '五按钮方向十字键';

  @override
  String get blockDescButtonRow => '等间距排列的按钮行';

  @override
  String get blockDescVolume => '音量减 / 静音 / 音量加';

  @override
  String get blockDescGrid => '按钮网格';

  @override
  String get blockDescSpacer => '块之间的空白垂直间距';

  @override
  String get buttonEditorTitle => '编辑按钮';

  @override
  String get buttonEditorActionLabel => '操作';

  @override
  String get buttonEditorIconLabel => '图标';

  @override
  String get buttonEditorShowLabel => '显示标签';

  @override
  String get buttonEditorShowLabelOn => '按钮上显示标题';

  @override
  String get buttonEditorShowLabelOff => '按钮不显示标题';

  @override
  String get buttonEditorLabelField => '标签';

  @override
  String buttonEditorLabelHelper(String defaultLabel) {
    return '空白 — 使用默认值：$defaultLabel';
  }

  @override
  String get iconPickerTitle => '选择图标';

  @override
  String get iconPickerDefaultSubtitle => '此操作的标准图标';

  @override
  String get iconPickerTextOnlySubtitle => '只显示标签，不显示图标';

  @override
  String get iconPickerYourImages => '你的图片';

  @override
  String get iconPickerAddImage => '添加';

  @override
  String get iconPackStandardName => '标准';

  @override
  String get appearanceDefault => '默认';

  @override
  String get appearanceTextOnly => '仅文字';

  @override
  String get appearancePackIcon => '图标包图标';

  @override
  String get appearanceCustomImage => '自定义图片';

  @override
  String get appearanceCustomIcon => '自定义图标';

  @override
  String get keyRoleDpad => '方向键';

  @override
  String get keyRoleNavigation => '导航';

  @override
  String get keyRoleTransport => '播放';

  @override
  String get keyRoleVolume => '音量';

  @override
  String get keyRoleChannel => '频道';

  @override
  String get keyRoleSystem => '系统';

  @override
  String get remoteKeyUp => '上';

  @override
  String get remoteKeyDown => '下';

  @override
  String get remoteKeyLeft => '左';

  @override
  String get remoteKeyRight => '右';

  @override
  String get remoteKeyOk => '确定';

  @override
  String get remoteKeyBack => '返回';

  @override
  String get remoteKeyHome => '主页';

  @override
  String get remoteKeyRewind => '倒退';

  @override
  String get remoteKeyPlayPause => '播放/暂停';

  @override
  String get remoteKeyFastForward => '快进';

  @override
  String get remoteKeyNext => '下一个';

  @override
  String get remoteKeyPrevious => '上一个';

  @override
  String get remoteKeyVolumeUp => '音量 +';

  @override
  String get remoteKeyVolumeDown => '音量 -';

  @override
  String get remoteKeyMute => '静音';

  @override
  String get remoteKeyChannelUp => '频道 +';

  @override
  String get remoteKeyChannelDown => '频道 -';

  @override
  String get remoteKeyPower => '电源';

  @override
  String get remoteKeySettings => '设置';

  @override
  String get remoteKeyKeyboard => '键盘';

  @override
  String get keyboardTitle => '在电视上输入';

  @override
  String get keyboardHint => '在电视上选择文本框，然后在此输入。';

  @override
  String get keyboardSendEnter => '发送回车';

  @override
  String get keyboardClose => '完成';

  @override
  String get keyboardNotSupported => '此电视不支持远程输入。';

  @override
  String get iconNameUp => '上';

  @override
  String get iconNameDown => '下';

  @override
  String get iconNameLeft => '左';

  @override
  String get iconNameRight => '右';

  @override
  String get iconNameOk => '确定';

  @override
  String get iconNameBack => '返回';

  @override
  String get iconNameHome => '主页';

  @override
  String get iconNameRewind => '倒退';

  @override
  String get iconNameFastForward => '快进';

  @override
  String get iconNamePlayPause => '播放 / 暂停';

  @override
  String get iconNamePlay => '播放';

  @override
  String get iconNamePause => '暂停';

  @override
  String get iconNameStop => '停止';

  @override
  String get iconNameNext => '下一个';

  @override
  String get iconNamePrevious => '上一个';

  @override
  String get iconNameVolumeUp => '音量 +';

  @override
  String get iconNameVolumeDown => '音量 -';

  @override
  String get iconNameMute => '静音';

  @override
  String get iconNameChannelUp => '频道 +';

  @override
  String get iconNameChannelDown => '频道 -';

  @override
  String get iconNamePower => '电源';

  @override
  String get iconNameMenu => '菜单';

  @override
  String get iconNameSettings => '设置';

  @override
  String get iconNameInfo => '信息';

  @override
  String get iconNameMic => '麦克风';

  @override
  String get iconNameKeyboard => '键盘';

  @override
  String get failureDiscovery => '无法搜索电视。请检查 Wi-Fi 后重试。';

  @override
  String get failureConnection => '无法连接到电视。请确保它已打开并在附近。';

  @override
  String get failureCommand => '该按钮未送达。请重试。';

  @override
  String get failureUnknown => '出了点问题。请重试。';

  @override
  String get logoSemanticLabel => 'Flixsy 标志';

  @override
  String get mainRemoteSemanticLabel => 'Flixsy 遥控器';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonDone => '完成';

  @override
  String get removeAdsAction => '移除广告';

  @override
  String removeAdsActionWithPrice(String price) {
    return '移除广告 — $price';
  }

  @override
  String get restorePurchasesAction => '恢复购买';

  @override
  String get removeAdsSuccess => '广告已移除，感谢你的支持！';

  @override
  String get removeAdsFailureCancelled => '购买已取消。';

  @override
  String get removeAdsFailureProductNotFound => '此商品当前不可用。请稍后重试。';

  @override
  String get removeAdsFailureNetwork => '无法连接到应用商店。请检查网络后重试。';

  @override
  String get removeAdsFailureNothingToRestore => '未找到以前的购买记录。';

  @override
  String get removeAdsFailureUnknown => '出了点问题。请重试。';

  @override
  String get magicMouseLabel => 'Magic Mouse';

  @override
  String get magicMouseUnsupportedTooltip => 'Magic Mouse 仅适用于 LG webOS 电视。';

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
