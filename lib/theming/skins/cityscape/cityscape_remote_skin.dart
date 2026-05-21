import 'package:flutter/material.dart';

import '../../../data/models/layout/remote_layout.dart';
import '../../remote_skin.dart';
import '../../standard/standard_remote.dart';
import 'cityscape_background.dart';
import 'cityscape_pulse_scope.dart';
import 'cityscape_section_renderer.dart';

/// The `Cityscape` skin: a night skyline — deep indigo sky, layered building
/// silhouettes speckled with lit windows, a soft moon, and blinking aircraft
/// warning lights atop the tallest towers — with a [StandardRemote] floating
/// over it. Button chrome breathes cool cyan in time with the shared pulse
/// so the city's window glow reads on the remote surface.
class CityscapeRemoteSkin extends StatefulWidget implements RemoteSkin {
  const CityscapeRemoteSkin({
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
  State<CityscapeRemoteSkin> createState() => _CityscapeRemoteSkinState();
}

class _CityscapeRemoteSkinState extends State<CityscapeRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // A slow, calm tempo — night cityscape mood, slightly faster than the
    // honkytonk slow-dance breath but slower than the campfire's flicker.
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
        const CityscapeBackground(),
        SafeArea(
          top: false,
          child: CityscapePulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const CityscapeSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
