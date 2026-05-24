import 'package:flutter/material.dart';

import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flixsy/theming/skins/ocean/ocean_background.dart';
import 'package:flixsy/theming/skins/ocean/ocean_pulse_scope.dart';
import 'package:flixsy/theming/skins/ocean/ocean_section_renderer.dart';

/// The `Ocean` skin: a horizon between a sky that cycles through sunrise,
/// midday, sunset and night, and a calm sea below it. A [StandardRemote]
/// floats over the water with constant dark-frosted button chrome.
class OceanRemoteSkin extends StatefulWidget implements RemoteSkin {
  const OceanRemoteSkin({
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
  State<OceanRemoteSkin> createState() => _OceanRemoteSkinState();
}

class _OceanRemoteSkinState extends State<OceanRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
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
        const OceanBackground(),
        SafeArea(
          top: false,
          child: OceanPulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const OceanSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
