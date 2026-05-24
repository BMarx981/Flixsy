import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flixsy/theming/skins/punk/punk_background.dart';
import 'package:flixsy/theming/skins/punk/punk_pulse_scope.dart';
import 'package:flixsy/theming/skins/punk/punk_section_renderer.dart';

/// The `Punk` skin: a graffitied alley — dark brick wall, two torn band
/// posters stapled crooked, spray-paint splatters and slow drips, and a
/// hot-magenta Flixsy sparkle-star tag in the upper-centre — with a
/// [StandardRemote] floating over it. Button chrome breathes magenta in time
/// with the shared pulse so the spray-tag's heat reads on the remote surface.
class PunkRemoteSkin extends StatefulWidget implements RemoteSkin {
  const PunkRemoteSkin({
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
  State<PunkRemoteSkin> createState() => _PunkRemoteSkinState();
}

class _PunkRemoteSkinState extends State<PunkRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // A faster, harder-driving tempo than the calmer skins — closer to a
    // dive-bar bassline than a slow dance.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
        const PunkBackground(),
        SafeArea(
          top: false,
          child: PunkPulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const PunkSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
