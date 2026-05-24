import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_background.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_pulse_scope.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_section_renderer.dart';

/// The `Honkytonk` skin: a dim country-bar interior — wood-plank walls, a
/// row of warm pendant bulbs, a neon guitar sign behind, drifting smoke and
/// a wooden floor — with a [StandardRemote] floating over it. Button chrome
/// breathes hot-pink in time with the shared pulse so the neon's warmth reads
/// on the remote surface.
class HonkytonkRemoteSkin extends StatefulWidget implements RemoteSkin {
  const HonkytonkRemoteSkin({
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
  State<HonkytonkRemoteSkin> createState() => _HonkytonkRemoteSkinState();
}

class _HonkytonkRemoteSkinState extends State<HonkytonkRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // A touch slower than the campfire skin — closer to a slow-dance tempo,
    // which fits the bar mood better than a quick flicker.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
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
        const HonkytonkBackground(),
        SafeArea(
          top: false,
          child: HonkytonkPulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const HonkytonkSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
