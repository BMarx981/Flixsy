import 'package:flutter/material.dart';

import '../../../data/models/layout/remote_layout.dart';
import '../../remote_skin.dart';
import '../../standard/standard_remote.dart';
import 'cloud_background.dart';
import 'cloud_pulse_scope.dart';
import 'cloud_section_renderer.dart';

/// The `Cloud` skin: soft clouds drifting across a sky-blue gradient behind a
/// [StandardRemote] whose white panels breathe with a shared, slow pulse.
class CloudRemoteSkin extends StatefulWidget implements RemoteSkin {
  const CloudRemoteSkin({
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
  State<CloudRemoteSkin> createState() => _CloudRemoteSkinState();
}

class _CloudRemoteSkinState extends State<CloudRemoteSkin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
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
        const CloudBackground(),
        SafeArea(
          top: false,
          child: CloudPulseScope(
            pulse: CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            child: StandardRemote(
              layout: widget.layout,
              renderer: const CloudSectionRenderer(),
              onKeyPressed: widget.onKeyPressed,
              imagePaths: widget.imagePaths,
            ),
          ),
        ),
      ],
    );
  }
}
