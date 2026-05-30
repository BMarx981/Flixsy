import 'package:flutter/material.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/features/layout_editor/widgets/glass_sheet.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';

/// Shows the Wake-on-LAN setup instructions for [vendor] in a glass bottom
/// sheet. Returns once the user dismisses the sheet.
///
/// Vendor is a per-channel id (e.g. `'webos'`). Vendors without dedicated
/// instructions are a no-op so callers don't need to filter.
Future<void> showPowerSetupSheet(
  BuildContext context, {
  required String vendor,
}) async {
  final content = _PowerSetupContent.forVendor(vendor);
  if (content == null) return;
  await showGlassModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _PowerSetupSheet(content: content),
  );
}

/// Per-vendor copy. Looked up at build time so the strings resolve against the
/// active locale, not the locale when the sheet was scheduled.
class _PowerSetupContent {
  const _PowerSetupContent({
    required this.title,
    required this.intro,
    required this.steps,
    required this.tipTitle,
    required this.tipBody,
  });

  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) intro;
  final List<String> Function(AppLocalizations l10n) steps;
  final String Function(AppLocalizations l10n) tipTitle;
  final String Function(AppLocalizations l10n) tipBody;

  static _PowerSetupContent? forVendor(String vendor) => switch (vendor) {
    'webos' => _PowerSetupContent(
      title: (l) => l.powerSetupWebosTitle,
      intro: (l) => l.powerSetupWebosIntro,
      steps: (l) => [
        l.powerSetupWebosStep1,
        l.powerSetupWebosStep2,
        l.powerSetupWebosStep3,
      ],
      tipTitle: (l) => l.powerSetupWebosTipTitle,
      tipBody: (l) => l.powerSetupWebosTipBody,
    ),
    _ => null,
  };
}

class _PowerSetupSheet extends StatelessWidget {
  const _PowerSetupSheet({required this.content});

  final _PowerSetupContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final steps = content.steps(l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  content.title(l10n),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content.intro(l10n),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < steps.length; i++) ...[
            _Step(number: i + 1, body: steps[i]),
            if (i < steps.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.tipTitle(l10n),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.tipBody(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.powerSetupDismiss),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.body});

  final int number;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
