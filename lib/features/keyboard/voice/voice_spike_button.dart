// PHASE 0 SPIKE — DELETE AFTER VERIFIED.
//
// Throwaway AppBar action used to confirm `speech_to_text` initialises on
// real devices (iPhone + Android phone) with on-device recognition in the
// app locale. Once confirmed, the whole `voice_spike_button.dart` file and
// its single import in `home_screen.dart` are deleted; Phase 1 builds the
// real service.
//
// What it does on tap:
//   1. Calls `SpeechToText().initialize()` (triggers mic + speech-recognition
//      permission prompts the first time on iOS; mic prompt on Android).
//   2. Logs availability + supported-locale count to debug print.
//   3. For each supported app locale (intersected with the recognizer's),
//      logs whether the recognizer is available.
//   4. Performs a brief 4-second listen and logs the partial + final result.
//   5. Surfaces a one-line summary as a snackbar so it's visible without a
//      debugger attached.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSpikeButton extends StatefulWidget {
  const VoiceSpikeButton({super.key});

  @override
  State<VoiceSpikeButton> createState() => _VoiceSpikeButtonState();
}

class _VoiceSpikeButtonState extends State<VoiceSpikeButton> {
  final SpeechToText _speech = SpeechToText();
  bool _busy = false;

  Future<void> _runSpike() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final appLocale = Localizations.localeOf(context);

    String? lastPartial;
    String? lastFinal;

    try {
      final available = await _speech.initialize(
        onError: (SpeechRecognitionError e) {
          debugPrint('[voice-spike] error: ${e.errorMsg} '
              '(permanent=${e.permanent})');
        },
        onStatus: (status) => debugPrint('[voice-spike] status=$status'),
      );

      debugPrint('[voice-spike] initialize() → $available');

      if (!available) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Voice spike: speech_to_text NOT available.'),
        ));
        return;
      }

      final locales = await _speech.locales();
      debugPrint('[voice-spike] recognizer supports '
          '${locales.length} locales');
      final matched = locales
          .where((l) =>
              l.localeId.toLowerCase().startsWith(appLocale.languageCode))
          .toList();
      debugPrint('[voice-spike] app locale=${appLocale.toLanguageTag()}; '
          'recognizer match count=${matched.length} '
          '${matched.map((m) => m.localeId).toList()}');

      final localeId = matched.isNotEmpty
          ? matched.first.localeId
          : (await _speech.systemLocale())?.localeId;
      debugPrint('[voice-spike] using localeId=$localeId');

      // On iOS 13+ `onDevice: true` forces SFSpeechRecognizer on-device. On
      // Android it's a hint; the platform picks on-device when available.
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          if (r.finalResult) {
            lastFinal = r.recognizedWords;
            debugPrint('[voice-spike] FINAL: "${r.recognizedWords}" '
                '(confidence=${r.confidence})');
          } else {
            lastPartial = r.recognizedWords;
            debugPrint('[voice-spike] partial: "${r.recognizedWords}"');
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 4),
          pauseFor: const Duration(milliseconds: 1500),
          onDevice: true,
          partialResults: true,
          cancelOnError: true,
        ),
      );

      // Give the platform up to 4.5s to deliver the final result.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (_speech.isListening && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await _speech.stop();

      final summary = (lastFinal ?? lastPartial)?.trim();
      messenger.showSnackBar(SnackBar(
        content: Text(summary == null || summary.isEmpty
            ? 'Voice spike: initialized; no speech captured.'
            : 'Voice spike heard: "$summary"'),
      ));
    } catch (e, st) {
      debugPrint('[voice-spike] threw: $e\n$st');
      messenger.showSnackBar(SnackBar(
        content: Text('Voice spike threw: $e'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.mic_none),
      tooltip: context.l10n.voiceSpikeTooltip,
      onPressed: _busy ? null : _runSpike,
    );
  }
}
