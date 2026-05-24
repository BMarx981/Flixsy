import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/data/models/layout/button_appearance.dart';

/// A single button in a layout.
///
/// A button is two independent parts (see `docs/custom_layouts_design.md` §3):
/// the [action] it sends — always present, the function — and its
/// [appearance] — how it looks, which never affects behaviour.
class RemoteButton {
  const RemoteButton({
    required this.action,
    this.appearance = const DefaultLook(),
  });

  /// What the button sends. Always present.
  final RemoteKey action;

  /// How the button looks. Defaults to the catalogue [DefaultLook].
  final ButtonAppearance appearance;

  Map<String, Object?> toJson() => {
    'action': action.code,
    'appearance': appearance.toJson(),
  };

  /// Parses a button, or `null` when [json] carries no resolvable action.
  ///
  /// A button must have an action, so an unknown key code is dropped rather
  /// than guessed — callers decide what an empty slot means. The appearance,
  /// by contrast, always resolves (it degrades to [DefaultLook]).
  static RemoteButton? fromJson(Map<String, Object?> json) {
    final code = json['action'];
    final action = code is String ? RemoteKey.fromCode(code) : null;
    if (action == null) return null;

    final rawAppearance = json['appearance'];
    return RemoteButton(
      action: action,
      appearance: rawAppearance is Map
          ? ButtonAppearance.fromJson(rawAppearance.cast<String, Object?>())
          : const DefaultLook(),
    );
  }
}
