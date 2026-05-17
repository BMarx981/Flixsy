import 'package:flutter/material.dart';

import '../../remote_skin.dart';

class ClassicRemoteSkin extends StatelessWidget implements RemoteSkin {
  const ClassicRemoteSkin({
    super.key,
    required this.onKeyPressed,
  });

  @override
  final void Function(String key) onKeyPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RemoteButton(label: '▲', keyCode: 'UP', onPressed: onKeyPressed),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RemoteButton(label: '◀', keyCode: 'LEFT', onPressed: onKeyPressed),
              _RemoteButton(label: 'OK', keyCode: 'OK', onPressed: onKeyPressed),
              _RemoteButton(label: '▶', keyCode: 'RIGHT', onPressed: onKeyPressed),
            ],
          ),
          _RemoteButton(label: '▼', keyCode: 'DOWN', onPressed: onKeyPressed),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RemoteButton(label: '⏪', keyCode: 'REWIND', onPressed: onKeyPressed),
              _RemoteButton(label: '⏯', keyCode: 'PLAY_PAUSE', onPressed: onKeyPressed),
              _RemoteButton(label: '⏩', keyCode: 'FAST_FORWARD', onPressed: onKeyPressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoteButton extends StatelessWidget {
  const _RemoteButton({
    required this.label,
    required this.keyCode,
    required this.onPressed,
  });

  final String label;
  final String keyCode;
  final void Function(String key) onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => onPressed(keyCode),
        child: Text(label),
      ),
    );
  }
}
