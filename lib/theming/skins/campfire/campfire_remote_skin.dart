import 'package:flutter/material.dart';

import '../../../data/models/layout/remote_layout.dart';
import '../../remote_skin.dart';
import '../../standard/standard_remote.dart';
import 'campfire_background.dart';
import 'campfire_pulse_scope.dart';
import 'campfire_section_renderer.dart';

/// The `Campfire` skin: a desert-night scene — starlit sky, crescent moon,
/// layered mesa silhouettes, and an animated campfire at the base — with a
/// [StandardRemote] floating over it. Button chrome glows ember-warm in time
/// with the shared pulse so the fire's warmth reads on the remote surface.
class CampfireRemoteSkin extends StatefulWidget implements RemoteSkin {
  const CampfireRemoteSkin({
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
  State<CampfireRemoteSkin> createState() => _CampfireRemoteSkinState();
}

class _CampfireRemoteSkinState extends State<CampfireRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Slightly faster than the ocean skin's pulse — embers and flame flicker
    // give the scene a quicker rhythm than rolling water.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
        const CampfireBackground(),
        SafeArea(
          top: false,
          child: CampfirePulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const CampfireSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
