import 'dart:typed_data';

import 'package:flixsy/core/channels/proto_codec.dart';
import 'package:flutter_test/flutter_test.dart';

// Unit tests for the hand-written protobuf codec that backs the Android TV
// Remote v2 channel: field encoding round-trips, unknown-field skipping, and
// the varint-length frame reassembly.

void main() {
  group('ProtoWriter / ProtoReader', () {
    test('round-trips a varint field, including multi-byte values', () {
      final bytes =
          (ProtoWriter()
                ..writeVarint(1, 7)
                ..writeVarint(2, 200)
                ..writeVarint(3, 300000))
              .toBytes();
      final reader = ProtoReader.parse(bytes);

      expect(reader.readInt(1), 7);
      expect(reader.readInt(2), 200);
      expect(reader.readInt(3), 300000);
    });

    test('round-trips bool, string and bytes fields', () {
      final bytes =
          (ProtoWriter()
                ..writeBool(1, value: true)
                ..writeBool(2, value: false)
                ..writeString(3, 'Flixsy')
                ..writeBytes(4, const [0xde, 0xad, 0xbe, 0xef]))
              .toBytes();
      final reader = ProtoReader.parse(bytes);

      expect(reader.readInt(1), 1);
      expect(reader.readInt(2), 0);
      expect(reader.readBytes(3), Uint8List.fromList('Flixsy'.codeUnits));
      expect(
        reader.readBytes(4),
        Uint8List.fromList(const [0xde, 0xad, 0xbe, 0xef]),
      );
    });

    test('round-trips a nested message field', () {
      final inner = ProtoWriter()
        ..writeVarint(1, 23)
        ..writeVarint(2, 3);
      final bytes = (ProtoWriter()..writeMessage(10, inner)).toBytes();

      final reader = ProtoReader.parse(bytes);
      expect(reader.has(10), isTrue);
      final nested = reader.readMessage(10);
      expect(nested, isNotNull);
      expect(nested!.readInt(1), 23);
      expect(nested.readInt(2), 3);
    });

    test('reports presence and returns null for absent fields', () {
      final reader = ProtoReader.parse(
        (ProtoWriter()..writeVarint(5, 1)).toBytes(),
      );
      expect(reader.has(5), isTrue);
      expect(reader.has(6), isFalse);
      expect(reader.readInt(6), isNull);
      expect(reader.readBytes(6), isNull);
      expect(reader.readMessage(6), isNull);
    });

    test('skips unknown fixed-width fields and keeps reading', () {
      // Field 1 as a fixed64 (wire type 1), then field 2 as a varint.
      final raw = Uint8List.fromList(<int>[
        (1 << 3) | 1, 0, 0, 0, 0, 0, 0, 0, 0, // fixed64 field 1
        (2 << 3) | 0, 42, // varint field 2 = 42
      ]);
      final reader = ProtoReader.parse(raw);

      expect(reader.has(1), isFalse); // fixed64 skipped, not retained
      expect(reader.readInt(2), 42);
    });

    test('throws FormatException on a truncated varint', () {
      expect(
        () => ProtoReader.parse(Uint8List.fromList(const [0x08, 0x80])),
        throwsFormatException,
      );
    });
  });

  group('frameMessage / ProtoFrameDecoder', () {
    test('frames and recovers a single message', () {
      final body = (ProtoWriter()..writeVarint(1, 99)).toBytes();
      final framed = frameMessage(body);

      final frames = ProtoFrameDecoder().addChunk(framed);
      expect(frames, hasLength(1));
      expect(frames.single, body);
    });

    test('recovers several messages delivered in one chunk', () {
      final first = (ProtoWriter()..writeVarint(1, 1)).toBytes();
      final second = (ProtoWriter()..writeString(2, 'two')).toBytes();
      final chunk = <int>[...frameMessage(first), ...frameMessage(second)];

      final frames = ProtoFrameDecoder().addChunk(chunk);
      expect(frames, hasLength(2));
      expect(frames[0], first);
      expect(frames[1], second);
    });

    test('reassembles a message split across chunks', () {
      final body = (ProtoWriter()..writeString(1, 'hello world')).toBytes();
      final framed = frameMessage(body);
      final decoder = ProtoFrameDecoder();

      // Split mid-body — the first chunk yields nothing.
      expect(decoder.addChunk(framed.sublist(0, 3)), isEmpty);
      final frames = decoder.addChunk(framed.sublist(3));
      expect(frames, hasLength(1));
      expect(frames.single, body);
    });

    test('holds back a partial length prefix', () {
      // A multi-byte varint length prefix arriving one byte at a time.
      final body = Uint8List(200); // length 200 -> 2-byte varint prefix
      final framed = frameMessage(body);
      final decoder = ProtoFrameDecoder();

      expect(decoder.addChunk(framed.sublist(0, 1)), isEmpty);
      final frames = decoder.addChunk(framed.sublist(1));
      expect(frames, hasLength(1));
      expect(frames.single.length, 200);
    });
  });
}
