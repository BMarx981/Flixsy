import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flixsy/theming/skins/waterfall/waterfall_background.dart';
import 'package:flixsy/theming/skins/waterfall/waterfall_pulse_scope.dart';
import 'package:flixsy/theming/skins/waterfall/waterfall_section_renderer.dart';

/// The `Waterfall` skin: animated wavy blue bands drifting behind a [StandardRemote]
/// whose buttons pulse gently in sync with a single shared animation.
class WaterfallRemoteSkin extends StatefulWidget implements RemoteSkin {
  const WaterfallRemoteSkin({
    super.key,
    required this.layout,
    required this.imagePaths,
    required this.onKeyPressed,
  });

  final RemoteLayout layout;
  final Map<String, String> imagePaths;

  @override
  final void Function(String key) onKeyPressed;

  @override
  State<WaterfallRemoteSkin> createState() => _WaterfallRemoteSkinState();
}

class _WaterfallRemoteSkinState extends State<WaterfallRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background bleeds to every edge of the body.
        const WaterfallBackground(),
        // Buttons stay clear of bottom/side system insets; the app bar
        // already handles the top.
        SafeArea(
          top: false,
          child: WaterfallPulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const WaterfallSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
