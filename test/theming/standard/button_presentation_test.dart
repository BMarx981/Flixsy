import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/theming/icons/icon_catalog.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/standard/button_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IconData iconOf(ButtonPresentation p) => (p.glyph as IconGlyph).icon;
  String textOf(ButtonPresentation p) => (p.glyph as TextGlyph).text;

  group('resolveButton', () {
    test('DefaultLook resolves to the action default icon + caption', () {
      final p = resolveButton(const RemoteButton(action: RemoteKey.playPause));

      expect(p.glyph, isA<IconGlyph>());
      expect(iconOf(p), defaultIconFor(RemoteKey.playPause));
      expect(p.caption, 'Play/Pause');
      expect(p.semanticLabel, 'Play/Pause');
    });

    test('BuiltInIcon resolves to the named Standard-pack icon', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.home,
          appearance: BuiltInIcon(iconId: 'mic'),
        ),
      );

      expect(iconOf(p), Icons.mic);
    });

    test('an unknown icon id degrades to the action default icon', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.power,
          appearance: BuiltInIcon(iconId: 'nonexistent'),
        ),
      );

      expect(iconOf(p), defaultIconFor(RemoteKey.power));
    });

    test('a PackIcon for an unregistered pack degrades to the default', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.power,
          appearance: PackIcon(packId: 'mystery', iconId: 'whatever'),
        ),
      );

      expect(iconOf(p), defaultIconFor(RemoteKey.power));
    });

    test('a CustomImage resolves to an ImageGlyph when its file is known', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.home,
          appearance: CustomImage(imageId: 'img-1'),
        ),
        imagePaths: const {'img-1': '/images/img-1.png'},
      );

      expect(p.glyph, isA<ImageGlyph>());
      expect((p.glyph as ImageGlyph).path, '/images/img-1.png');
    });

    test('a CustomImage degrades to the default icon without a path', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.home,
          appearance: CustomImage(imageId: 'img-1'),
        ),
      );

      expect(iconOf(p), defaultIconFor(RemoteKey.home));
    });

    test('a CustomImage degrades when its id is absent from the map', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.power,
          appearance: CustomImage(imageId: 'missing'),
        ),
        imagePaths: const {'other': '/images/other.png'},
      );

      expect(iconOf(p), defaultIconFor(RemoteKey.power));
    });

    test('TextOnly uses its override as the glyph, with no caption', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.home,
          appearance: TextOnly(labelOverride: 'Menu'),
        ),
      );

      expect(p.glyph, isA<TextGlyph>());
      expect(textOf(p), 'Menu');
      expect(p.caption, isNull);
      expect(p.semanticLabel, 'Menu');
    });

    test('TextOnly with no override falls back to the action label', () {
      final p = resolveButton(
        const RemoteButton(action: RemoteKey.home, appearance: TextOnly()),
      );

      expect(textOf(p), 'Home');
    });

    test('a label override replaces the caption on an icon button', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.power,
          appearance: DefaultLook(labelOverride: 'Sleep'),
        ),
      );

      expect(p.caption, 'Sleep');
      expect(p.semanticLabel, 'Sleep');
    });

    test('an empty override hides the caption but keeps the semantics', () {
      final p = resolveButton(
        const RemoteButton(
          action: RemoteKey.power,
          appearance: DefaultLook(labelOverride: ''),
        ),
      );

      expect(p.caption, isNull);
      expect(p.semanticLabel, 'Power');
    });
  });
}
