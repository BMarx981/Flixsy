import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The application name, shown as the OS task/window title.
  ///
  /// In en, this message translates to:
  /// **'Flixsy'**
  String get appTitle;

  /// Heading on the device-discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Find Your TV'**
  String get discoveryHeaderTitle;

  /// Sub-heading explaining the network requirement on the discovery screen.
  ///
  /// In en, this message translates to:
  /// **'Make sure your TV is on and connected to the same Wi-Fi network.'**
  String get discoveryHeaderSubtitle;

  /// Title shown when device discovery fails to start.
  ///
  /// In en, this message translates to:
  /// **'Could not start search'**
  String get discoveryErrorTitle;

  /// Body text shown when device discovery fails to start.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and try again.'**
  String get discoveryErrorBody;

  /// Button that restarts a failed device search.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get discoveryRetryButton;

  /// Status text shown while scanning the network for TVs.
  ///
  /// In en, this message translates to:
  /// **'Searching your network…'**
  String get discoverySearching;

  /// Reassurance shown beneath the searching status text.
  ///
  /// In en, this message translates to:
  /// **'This can take a few seconds.'**
  String get discoverySearchingHint;

  /// Count of TVs found by discovery.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device found} other{{count} devices found}}'**
  String discoveryDevicesFound(int count);

  /// Stand-in name used when a device's real name is unknown, e.g. 'Accept the request on your TV'.
  ///
  /// In en, this message translates to:
  /// **'your TV'**
  String get discoveryDeviceFallbackName;

  /// Title of the pairing banner when the TV shows a code to type in.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get discoveryPairingEnterCodeTitle;

  /// Title of the pairing banner when the user must accept a prompt on the TV.
  ///
  /// In en, this message translates to:
  /// **'Check your TV'**
  String get discoveryPairingCheckTvTitle;

  /// Instructions for entering the code the TV displays.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} is showing a 6-digit code. Type it below to finish pairing.'**
  String discoveryPairingEnterCodeBody(String deviceName);

  /// Instructions for accepting the pairing prompt on the TV itself.
  ///
  /// In en, this message translates to:
  /// **'Accept the connection request on {deviceName} using its remote.'**
  String discoveryPairingCheckTvBody(String deviceName);

  /// Placeholder text in the 6-digit pairing-code input. Keep it as six digits.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get discoveryPairingCodeHint;

  /// Button that submits the typed pairing code.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get discoveryPairButton;

  /// App-bar title of the main remote-control screen, shown when no TV is connected.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get homeTitle;

  /// Tooltip for the app-bar back button on the remote screen — returns to the device discovery (radar) screen so the user can pick another TV. The connection to the current TV stays alive.
  ///
  /// In en, this message translates to:
  /// **'Choose a different TV'**
  String get homeBackToRadarTooltip;

  /// Title of the dialog where the user can give a connected TV a custom name.
  ///
  /// In en, this message translates to:
  /// **'Rename TV'**
  String get renameDeviceDialogTitle;

  /// Label for the text field in the rename-TV dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get renameDeviceFieldLabel;

  /// Button that persists the typed nickname in the rename-TV dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get renameDeviceSaveButton;

  /// Button that dismisses the rename-TV dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get renameDeviceCancelButton;

  /// Button that clears the user's custom nickname for a TV, reverting to the name the TV advertises over the network.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get renameDeviceResetButton;

  /// Tooltip for the app-bar action that opens the layout picker.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get homeLayoutsTooltip;

  /// Tooltip for the app-bar action that switches the visual skin.
  ///
  /// In en, this message translates to:
  /// **'Change skin'**
  String get homeChangeSkinTooltip;

  /// Confirms the previewed skin in the swipe picker and persists it.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get skinPickerApply;

  /// Exits the skin picker without changing the saved skin.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get skinPickerCancel;

  /// Tooltip for the arrow that scrolls the skin picker to the previous skin.
  ///
  /// In en, this message translates to:
  /// **'Previous skin'**
  String get skinPickerPreviousTooltip;

  /// Tooltip for the arrow that scrolls the skin picker to the next skin.
  ///
  /// In en, this message translates to:
  /// **'Next skin'**
  String get skinPickerNextTooltip;

  /// App-bar title of the layout-picker screen.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get layoutPickerTitle;

  /// Shown when the saved layouts fail to load. {error} is a technical detail and is not translated.
  ///
  /// In en, this message translates to:
  /// **'Could not load layouts.\n{error}'**
  String layoutPickerLoadError(String error);

  /// Subtitle marking a layout as a read-only built-in template.
  ///
  /// In en, this message translates to:
  /// **'Built-in template'**
  String get layoutTypeTemplate;

  /// Subtitle marking a layout as a user-created custom layout.
  ///
  /// In en, this message translates to:
  /// **'Custom layout'**
  String get layoutTypeCustom;

  /// Tooltip for the overflow menu on a layout row.
  ///
  /// In en, this message translates to:
  /// **'Layout actions'**
  String get layoutActionsTooltip;

  /// Menu action that copies a layout.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get layoutActionDuplicate;

  /// Menu action that opens a layout in the editor.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get layoutActionEdit;

  /// Title of the confirm-delete dialog for a layout.
  ///
  /// In en, this message translates to:
  /// **'Delete layout?'**
  String get layoutDeleteDialogTitle;

  /// Body of the confirm-delete dialog for a layout.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed.'**
  String layoutDeleteDialogBody(String name);

  /// App-bar title of the layout-editor screen.
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get editorTitle;

  /// Floating button that adds a new block to the layout.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get editorAddBlockButton;

  /// Validation message shown when saving a layout with no name.
  ///
  /// In en, this message translates to:
  /// **'Give the layout a name.'**
  String get editorValidationName;

  /// Validation message shown when saving a layout with no blocks.
  ///
  /// In en, this message translates to:
  /// **'Add at least one block before saving.'**
  String get editorValidationBlocks;

  /// Confirmation shown after a layout is saved.
  ///
  /// In en, this message translates to:
  /// **'Layout saved.'**
  String get editorSavedSnack;

  /// Section label above the live layout preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreviewLabel;

  /// Section label above the list of editable blocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get editorBlocksLabel;

  /// Label of the text field for the layout's name.
  ///
  /// In en, this message translates to:
  /// **'Layout name'**
  String get editorNameFieldLabel;

  /// Placeholder shown in the preview box when the layout has no blocks.
  ///
  /// In en, this message translates to:
  /// **'Add a block to see a preview'**
  String get editorEmptyPreview;

  /// Tooltip for the button that deletes a block.
  ///
  /// In en, this message translates to:
  /// **'Remove block'**
  String get editorRemoveBlockTooltip;

  /// Label for an empty cell in a grid block.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get editorEmptyCell;

  /// Tooltip for the small × that removes a single button from a row or grid in the layout editor.
  ///
  /// In en, this message translates to:
  /// **'Remove button'**
  String get editorRemoveButtonTooltip;

  /// Label of the trailing chip that appends a new button to a row or grid in the layout editor.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get editorAddButtonChip;

  /// Name of the directional-cross block type.
  ///
  /// In en, this message translates to:
  /// **'D-pad'**
  String get blockKindDpad;

  /// Name of the horizontal button-row block type.
  ///
  /// In en, this message translates to:
  /// **'Button row'**
  String get blockKindButtonRow;

  /// Name of the volume-rocker block type.
  ///
  /// In en, this message translates to:
  /// **'Volume rocker'**
  String get blockKindVolume;

  /// Name of the grid block type.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get blockKindGrid;

  /// Name of the spacer block type (blank space).
  ///
  /// In en, this message translates to:
  /// **'Spacer'**
  String get blockKindSpacer;

  /// Description of the D-pad block type.
  ///
  /// In en, this message translates to:
  /// **'A five-button directional cross'**
  String get blockDescDpad;

  /// Description of the button-row block type.
  ///
  /// In en, this message translates to:
  /// **'An evenly spaced row of buttons'**
  String get blockDescButtonRow;

  /// Description of the volume-rocker block type.
  ///
  /// In en, this message translates to:
  /// **'Volume down / mute / volume up'**
  String get blockDescVolume;

  /// Description of the grid block type.
  ///
  /// In en, this message translates to:
  /// **'A grid of buttons'**
  String get blockDescGrid;

  /// Description of the spacer block type.
  ///
  /// In en, this message translates to:
  /// **'Blank vertical space between blocks'**
  String get blockDescSpacer;

  /// Title of the button-editor bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit button'**
  String get buttonEditorTitle;

  /// Label of the row that picks which key a button sends.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get buttonEditorActionLabel;

  /// Label of the row that picks a button's icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get buttonEditorIconLabel;

  /// Label of the toggle that shows or hides a button's caption.
  ///
  /// In en, this message translates to:
  /// **'Show label'**
  String get buttonEditorShowLabel;

  /// Sub-text when the show-label toggle is on.
  ///
  /// In en, this message translates to:
  /// **'A caption is shown on the button'**
  String get buttonEditorShowLabelOn;

  /// Sub-text when the show-label toggle is off.
  ///
  /// In en, this message translates to:
  /// **'The button shows no caption'**
  String get buttonEditorShowLabelOff;

  /// Label of the text field for a button's custom caption.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get buttonEditorLabelField;

  /// Helper text shown when the custom-label field is empty.
  ///
  /// In en, this message translates to:
  /// **'Empty — using the default: {defaultLabel}'**
  String buttonEditorLabelHelper(String defaultLabel);

  /// Title of the icon-picker bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get iconPickerTitle;

  /// Sub-text for the 'Default' icon choice.
  ///
  /// In en, this message translates to:
  /// **'The standard icon for this action'**
  String get iconPickerDefaultSubtitle;

  /// Sub-text for the 'Text only' icon choice.
  ///
  /// In en, this message translates to:
  /// **'Show the label, no icon'**
  String get iconPickerTextOnlySubtitle;

  /// Section header above the user's imported button images.
  ///
  /// In en, this message translates to:
  /// **'Your images'**
  String get iconPickerYourImages;

  /// Label of the tile that imports a new button image.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get iconPickerAddImage;

  /// Display name of the built-in 'Standard' icon pack.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get iconPackStandardName;

  /// Name of the default button appearance / icon choice.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get appearanceDefault;

  /// Name of the text-only button appearance / icon choice.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get appearanceTextOnly;

  /// Description of a button using an icon-pack icon.
  ///
  /// In en, this message translates to:
  /// **'Pack icon'**
  String get appearancePackIcon;

  /// Description of a button using a user-imported image.
  ///
  /// In en, this message translates to:
  /// **'Custom image'**
  String get appearanceCustomImage;

  /// Fallback description of a button icon that cannot be named.
  ///
  /// In en, this message translates to:
  /// **'Custom icon'**
  String get appearanceCustomIcon;

  /// Group header for the directional keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'Directional'**
  String get keyRoleDpad;

  /// Group header for the navigation keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get keyRoleNavigation;

  /// Group header for the playback keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get keyRoleTransport;

  /// Group header for the volume keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get keyRoleVolume;

  /// Group header for the channel keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get keyRoleChannel;

  /// Group header for the system keys in the action picker.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get keyRoleSystem;

  /// Remote key label: D-pad up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get remoteKeyUp;

  /// Remote key label: D-pad down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get remoteKeyDown;

  /// Remote key label: D-pad left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get remoteKeyLeft;

  /// Remote key label: D-pad right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get remoteKeyRight;

  /// Remote key label: D-pad centre / select.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get remoteKeyOk;

  /// Remote key label: back / return.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get remoteKeyBack;

  /// Remote key label: home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get remoteKeyHome;

  /// Remote key label: rewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind'**
  String get remoteKeyRewind;

  /// Remote key label: toggle play and pause.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get remoteKeyPlayPause;

  /// Remote key label: fast-forward.
  ///
  /// In en, this message translates to:
  /// **'Fast Forward'**
  String get remoteKeyFastForward;

  /// Remote key label: skip to next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get remoteKeyNext;

  /// Remote key label: skip to previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get remoteKeyPrevious;

  /// Remote key label: raise volume.
  ///
  /// In en, this message translates to:
  /// **'Volume Up'**
  String get remoteKeyVolumeUp;

  /// Remote key label: lower volume.
  ///
  /// In en, this message translates to:
  /// **'Volume Down'**
  String get remoteKeyVolumeDown;

  /// Remote key label: mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get remoteKeyMute;

  /// Remote key label: next channel.
  ///
  /// In en, this message translates to:
  /// **'Channel Up'**
  String get remoteKeyChannelUp;

  /// Remote key label: previous channel.
  ///
  /// In en, this message translates to:
  /// **'Channel Down'**
  String get remoteKeyChannelDown;

  /// Remote key label: power on/off.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get remoteKeyPower;

  /// Remote key label: opens the TV's settings or menu.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get remoteKeySettings;

  /// Remote key label: opens the in-app keyboard sheet so the user can type into a TV text field.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get remoteKeyKeyboard;

  /// Title of the keyboard bottom sheet — the surface users open to type into a focused text field on their TV.
  ///
  /// In en, this message translates to:
  /// **'Type to TV'**
  String get keyboardTitle;

  /// Placeholder hint shown inside the keyboard sheet's text input before the user types anything.
  ///
  /// In en, this message translates to:
  /// **'Focus a text field on your TV, then type here.'**
  String get keyboardHint;

  /// Button on the keyboard sheet that submits the current TV field (ENTER / IME action done) without closing the sheet.
  ///
  /// In en, this message translates to:
  /// **'Send Enter'**
  String get keyboardSendEnter;

  /// Button on the keyboard sheet that closes it.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keyboardClose;

  /// Snackbar shown when the user taps the Keyboard button but the connected TV — or no TV at all — doesn't expose a text-input capability.
  ///
  /// In en, this message translates to:
  /// **'This TV doesn\'t support remote typing.'**
  String get keyboardNotSupported;

  /// Icon name in the Standard pack: up arrow.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get iconNameUp;

  /// Icon name in the Standard pack: down arrow.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get iconNameDown;

  /// Icon name in the Standard pack: left arrow.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get iconNameLeft;

  /// Icon name in the Standard pack: right arrow.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get iconNameRight;

  /// Icon name in the Standard pack: select / OK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get iconNameOk;

  /// Icon name in the Standard pack: back arrow.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get iconNameBack;

  /// Icon name in the Standard pack: home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get iconNameHome;

  /// Icon name in the Standard pack: rewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind'**
  String get iconNameRewind;

  /// Icon name in the Standard pack: fast-forward.
  ///
  /// In en, this message translates to:
  /// **'Fast forward'**
  String get iconNameFastForward;

  /// Icon name in the Standard pack: play/pause.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get iconNamePlayPause;

  /// Icon name in the Standard pack: play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get iconNamePlay;

  /// Icon name in the Standard pack: pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get iconNamePause;

  /// Icon name in the Standard pack: stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get iconNameStop;

  /// Icon name in the Standard pack: skip next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get iconNameNext;

  /// Icon name in the Standard pack: skip previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get iconNamePrevious;

  /// Icon name in the Standard pack: volume up.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get iconNameVolumeUp;

  /// Icon name in the Standard pack: volume down.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get iconNameVolumeDown;

  /// Icon name in the Standard pack: mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get iconNameMute;

  /// Icon name in the Standard pack: channel up.
  ///
  /// In en, this message translates to:
  /// **'Channel up'**
  String get iconNameChannelUp;

  /// Icon name in the Standard pack: channel down.
  ///
  /// In en, this message translates to:
  /// **'Channel down'**
  String get iconNameChannelDown;

  /// Icon name in the Standard pack: power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get iconNamePower;

  /// Icon name in the Standard pack: menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get iconNameMenu;

  /// Icon name in the Standard pack: settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get iconNameSettings;

  /// Icon name in the Standard pack: info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get iconNameInfo;

  /// Icon name in the Standard pack: microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get iconNameMic;

  /// Icon name in the Standard pack: keyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get iconNameKeyboard;

  /// User-facing message for a device-discovery failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search for TVs. Check your Wi-Fi and try again.'**
  String get failureDiscovery;

  /// User-facing message for a connection failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to the TV. Make sure it\'s on and nearby.'**
  String get failureConnection;

  /// User-facing message for a failed remote-key command.
  ///
  /// In en, this message translates to:
  /// **'That button didn\'t go through. Please try again.'**
  String get failureCommand;

  /// User-facing message for an unclassified failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureUnknown;

  /// Accessibility label for the Flixsy brand logo image.
  ///
  /// In en, this message translates to:
  /// **'Flixsy logo'**
  String get logoSemanticLabel;

  /// Accessibility label for the logo-shaped remote control surface.
  ///
  /// In en, this message translates to:
  /// **'Flixsy remote'**
  String get mainRemoteSemanticLabel;

  /// Generic 'Cancel' button used in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic 'Delete' action used in menus and dialogs.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic 'Save' button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic 'Done' button that confirms and closes a sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Menu action that opens the 'Remove Ads' in-app purchase. Used when the localized price isn't yet known.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAdsAction;

  /// Menu action that opens the 'Remove Ads' in-app purchase. {price} is the localized store price (already formatted with currency).
  ///
  /// In en, this message translates to:
  /// **'Remove Ads — {price}'**
  String removeAdsActionWithPrice(String price);

  /// Menu action that asks the store to restore any previous purchases made by the user.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchasesAction;

  /// Confirmation snackbar after a successful 'Remove Ads' purchase.
  ///
  /// In en, this message translates to:
  /// **'Ads removed. Thanks for your support!'**
  String get removeAdsSuccess;

  /// User-facing message when the user cancels the purchase sheet.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get removeAdsFailureCancelled;

  /// User-facing message when the store doesn't return the Remove Ads product.
  ///
  /// In en, this message translates to:
  /// **'This product isn\'t available right now. Please try again later.'**
  String get removeAdsFailureProductNotFound;

  /// User-facing message for an IAP network failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the store. Check your connection and try again.'**
  String get removeAdsFailureNetwork;

  /// Snackbar shown after Restore Purchases when nothing was restored.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found.'**
  String get removeAdsFailureNothingToRestore;

  /// User-facing message for an unclassified IAP failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get removeAdsFailureUnknown;

  /// Label on the toggle button that activates the free-cursor / accelerometer pointer (LG webOS Magic Remote-style). Shown next to the D-pad.
  ///
  /// In en, this message translates to:
  /// **'Magic Mouse'**
  String get magicMouseLabel;

  /// Tooltip shown on the Magic Mouse toggle when the connected TV does not support a free cursor.
  ///
  /// In en, this message translates to:
  /// **'Magic Mouse is only available on LG webOS TVs.'**
  String get magicMouseUnsupportedTooltip;

  /// Tooltip on the throwaway Phase-0 voice-recognition test button in the AppBar; deleted once Phase 1 ships.
  ///
  /// In en, this message translates to:
  /// **'Voice spike (Phase 0)'**
  String get voiceSpikeTooltip;

  /// Screen-reader announcement after the active skin changes.
  ///
  /// In en, this message translates to:
  /// **'Switched to {skinName} skin'**
  String accessibilitySkinChangedAnnouncement(String skinName);

  /// Screen-reader announcement after a TV connection succeeds.
  ///
  /// In en, this message translates to:
  /// **'Connected to {deviceName}'**
  String accessibilityDeviceConnectedAnnouncement(String deviceName);

  /// Screen-reader announcement after a TV is disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from TV'**
  String get accessibilityDeviceDisconnectedAnnouncement;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
