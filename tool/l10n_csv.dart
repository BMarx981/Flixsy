// Round-trips Flutter ARB localization files through a single CSV file, so
// translations can be edited in a spreadsheet such as Google Sheets.
//
//   dart run tool/l10n_csv.dart export   # lib/l10n/*.arb  -> l10n_strings.csv
//   dart run tool/l10n_csv.dart import   # l10n_strings.csv -> lib/l10n/*.arb
//
// `lib/l10n/app_en.arb` is the source of truth. `export` always takes the key
// list, English text, and translator descriptions from it; any translations
// already present in the other `app_<locale>.arb` files are carried into the
// CSV so a round-trip never loses work. `import` writes every non-English
// `app_<locale>.arb` from the CSV — a blank cell is omitted so that key falls
// back to English at runtime.
//
// After `import`, run `flutter gen-l10n` to regenerate the Dart localizations.

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

/// Directory holding the ARB files, relative to the project root.
const _l10nDir = 'lib/l10n';

/// The CSV exchanged with translators, relative to the project root.
const _csvPath = 'l10n_strings.csv';

/// The source-of-truth locale. Its ARB is never overwritten by `import`.
const _templateLocale = 'en';

/// Every locale the app ships, template first. Keep this in sync with the
/// `app_<locale>.arb` files and with `AppLocalizations.supportedLocales`.
const _locales = <String>[
  'en',
  'es',
  'fr',
  'de',
  'pt',
  'ja',
  'zh',
  'hi',
  'ar',
  'ru',
  'it',
  'ko',
];

void main(List<String> args) {
  final mode = args.isEmpty ? '' : args.first;
  switch (mode) {
    case 'export':
      _export();
    case 'import':
      _import();
    default:
      stderr.writeln('Usage: dart run tool/l10n_csv.dart <export|import>');
      exitCode = 64;
  }
}

/// The path of the ARB file for [locale].
String _arbPath(String locale) => '$_l10nDir/app_$locale.arb';

/// Reads an ARB file as a map, or `{}` when the file does not exist.
Map<String, dynamic> _readArb(String locale) {
  final file = File(_arbPath(locale));
  if (!file.existsSync()) return {};
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// The message keys of an ARB map, in file order — everything that is not the
/// `@@locale` marker or an `@key` metadata entry.
Iterable<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

// ─── export: ARB -> CSV ──────────────────────────────────────────────────────

void _export() {
  final template = _readArb(_templateLocale);
  if (template.isEmpty) {
    stderr.writeln('Missing or empty ${_arbPath(_templateLocale)}');
    exitCode = 66;
    return;
  }

  // Existing per-locale translations, so a round-trip preserves them.
  final translations = {
    for (final locale in _locales) locale: _readArb(locale),
  };

  final rows = <List<String>>[
    ['key', 'description', ..._locales],
  ];
  for (final key in _messageKeys(template)) {
    final description =
        (template['@$key'] as Map<String, dynamic>?)?['description'] as String?;
    rows.add([
      key,
      description ?? '',
      for (final locale in _locales)
        (translations[locale]?[key] as String?) ?? '',
    ]);
  }

  File(_csvPath).writeAsStringSync(const ListToCsvConverter().convert(rows));
  stdout.writeln('Wrote $_csvPath (${rows.length - 1} strings).');
}

// ─── import: CSV -> ARB ──────────────────────────────────────────────────────

void _import() {
  final csvFile = File(_csvPath);
  if (!csvFile.existsSync()) {
    stderr.writeln('Missing $_csvPath — run `export` first.');
    exitCode = 66;
    return;
  }

  final rows = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(csvFile.readAsStringSync().replaceAll('\r\n', '\n'));
  if (rows.isEmpty) {
    stderr.writeln('$_csvPath is empty.');
    exitCode = 66;
    return;
  }

  final header = rows.first.map((c) => '$c').toList();
  final keyCol = header.indexOf('key');
  if (keyCol == -1) {
    stderr.writeln('$_csvPath has no "key" column.');
    exitCode = 65;
    return;
  }

  for (final locale in _locales) {
    if (locale == _templateLocale) continue; // app_en.arb is the source.
    final col = header.indexOf(locale);
    if (col == -1) {
      stdout.writeln('Skipped $locale — no column in CSV.');
      continue;
    }

    final arb = <String, String>{'@@locale': locale};
    var translated = 0;
    for (final row in rows.skip(1)) {
      if (row.length <= keyCol) continue;
      final key = '${row[keyCol]}'.trim();
      if (key.isEmpty) continue;
      final value = col < row.length ? '${row[col]}' : '';
      // A blank cell is left out so the key falls back to English at runtime.
      if (value.isEmpty) continue;
      arb[key] = value;
      translated++;
    }

    File(
      _arbPath(locale),
    ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(arb)}\n');
    stdout.writeln('Wrote ${_arbPath(locale)} ($translated translated).');
  }
  stdout.writeln('Now run: flutter gen-l10n');
}
