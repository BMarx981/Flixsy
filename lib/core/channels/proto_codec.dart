import 'dart:convert';
import 'dart:typed_data';

/// A minimal Protocol Buffers wire-format codec.
///
/// Flixsy speaks the Android TV Remote v2 protocol, which is protobuf carried
/// over TLS. Rather than pull in the `protoc` toolchain to generate message
/// classes, this hand-written codec covers the small slice of the wire format
/// those messages actually use: base-128 varints, length-delimited fields, and
/// nested messages. It is plain Dart and fully unit-testable.
///
/// See `android_tv_connect_channel.dart` for the message definitions built on
/// top of it.

/// Protobuf wire type for varint-encoded fields (`int32`, `bool`, enums).
const int _wireVarint = 0;

/// Protobuf wire type for length-delimited fields (`bytes`, `string`, nested
/// messages).
const int _wireLengthDelimited = 2;

/// Protobuf wire type for 64-bit fixed fields — recognised only so unknown
/// fields can be skipped; the Android TV messages never use it.
const int _wireFixed64 = 1;

/// Protobuf wire type for 32-bit fixed fields — recognised only so unknown
/// fields can be skipped; the Android TV messages never use it.
const int _wireFixed32 = 5;

/// Builds a single protobuf message by appending fields in order.
///
/// Only the field kinds the Android TV protocol needs are exposed. Nested
/// messages are written by building a child [ProtoWriter] and passing it to
/// [writeMessage].
class ProtoWriter {
  final BytesBuilder _builder = BytesBuilder();

  /// Writes a varint field — an `int32`, an enum, or (via [writeBool]) a
  /// `bool`.
  void writeVarint(int field, int value) {
    _writeTag(field, _wireVarint);
    _writeVarint(value);
  }

  /// Writes a `bool` field, encoded as the varint `0` or `1`.
  void writeBool(int field, {required bool value}) =>
      writeVarint(field, value ? 1 : 0);

  /// Writes a length-delimited `bytes` field.
  void writeBytes(int field, List<int> value) {
    _writeTag(field, _wireLengthDelimited);
    _writeVarint(value.length);
    _builder.add(value);
  }

  /// Writes a length-delimited `string` field, UTF-8 encoded.
  void writeString(int field, String value) =>
      writeBytes(field, utf8.encode(value));

  /// Writes a nested message field — [message]'s bytes as a length-delimited
  /// field.
  void writeMessage(int field, ProtoWriter message) =>
      writeBytes(field, message.toBytes());

  /// The encoded message bytes.
  Uint8List toBytes() => _builder.toBytes();

  void _writeTag(int field, int wireType) =>
      _writeVarint((field << 3) | wireType);

  void _writeVarint(int value) {
    var remaining = value;
    while (true) {
      final lowBits = remaining & 0x7f;
      remaining = remaining >>> 7;
      if (remaining == 0) {
        _builder.addByte(lowBits);
        return;
      }
      _builder.addByte(lowBits | 0x80);
    }
  }
}

/// Reads a single protobuf message into a field map.
///
/// Decoding is forgiving by design: every field is collected, unknown fields
/// (including the 32-/64-bit fixed wire types) are skipped, and accessors
/// return `null` rather than throwing when a field is absent or has an
/// unexpected wire type. Callers detect which oneof-style sub-message an
/// envelope carries with [has].
class ProtoReader {
  ProtoReader._(this._fields);

  /// Parses [bytes] into a [ProtoReader].
  ///
  /// Throws [FormatException] if the bytes are not a well-formed protobuf
  /// message (truncated varint, length running past the buffer, …).
  factory ProtoReader.parse(Uint8List bytes) {
    final fields = <int, List<Object>>{};
    var offset = 0;
    while (offset < bytes.length) {
      final tag = _decodeVarint(bytes, offset);
      offset = tag.end;
      final field = tag.value >> 3;
      final wireType = tag.value & 0x7;
      if (wireType == _wireVarint) {
        final value = _decodeVarint(bytes, offset);
        (fields[field] ??= <Object>[]).add(value.value);
        offset = value.end;
      } else if (wireType == _wireLengthDelimited) {
        final length = _decodeVarint(bytes, offset);
        final start = length.end;
        final end = start + length.value;
        if (end > bytes.length) {
          throw const FormatException('Protobuf length runs past the message');
        }
        (fields[field] ??= <Object>[]).add(
          Uint8List.sublistView(bytes, start, end),
        );
        offset = end;
      } else if (wireType == _wireFixed64) {
        offset += 8;
      } else if (wireType == _wireFixed32) {
        offset += 4;
      } else {
        throw FormatException('Unsupported protobuf wire type: $wireType');
      }
    }
    return ProtoReader._(fields);
  }

  /// field number -> decoded values. Each value is an `int` (varint field) or
  /// a `Uint8List` (length-delimited field).
  final Map<int, List<Object>> _fields;

  /// Whether [field] appears in the message at least once.
  bool has(int field) => _fields.containsKey(field);

  /// The last varint value for [field], or `null` if absent / not a varint.
  int? readInt(int field) {
    final value = _fields[field]?.last;
    return value is int ? value : null;
  }

  /// The last length-delimited value for [field], or `null` if absent / not
  /// length-delimited.
  Uint8List? readBytes(int field) {
    final value = _fields[field]?.last;
    return value is Uint8List ? value : null;
  }

  /// Parses [field] as a nested message, or returns `null` if it is absent.
  ProtoReader? readMessage(int field) {
    final raw = readBytes(field);
    return raw == null ? null : ProtoReader.parse(raw);
  }
}

/// Reassembles a stream of varint-length-prefixed protobuf frames.
///
/// Both Android TV Remote v2 ports (pairing and remote control) frame each
/// message as a varint byte length followed by that many message bytes. TCP
/// delivers no message boundaries, so [addChunk] buffers partial data and
/// hands back only the complete message bodies.
class ProtoFrameDecoder {
  final BytesBuilder _buffer = BytesBuilder();

  /// Appends [chunk] to the internal buffer and returns every complete message
  /// body now available, with the length prefix stripped. A trailing partial
  /// frame is retained for the next call.
  List<Uint8List> addChunk(List<int> chunk) {
    _buffer.add(chunk);
    final data = _buffer.toBytes();
    final frames = <Uint8List>[];
    var offset = 0;
    while (offset < data.length) {
      final prefix = _tryDecodeVarint(data, offset);
      if (prefix == null) break; // length prefix not fully arrived
      final bodyEnd = prefix.end + prefix.value;
      if (bodyEnd > data.length) break; // body not fully arrived
      frames.add(Uint8List.sublistView(data, prefix.end, bodyEnd));
      offset = bodyEnd;
    }
    _buffer.clear();
    if (offset < data.length) {
      _buffer.add(Uint8List.sublistView(data, offset));
    }
    return frames;
  }
}

/// Prefixes [body] with its length as a base-128 varint — the framing both
/// Android TV Remote v2 ports use on the wire.
Uint8List frameMessage(List<int> body) {
  final out = BytesBuilder();
  var remaining = body.length;
  while (true) {
    final lowBits = remaining & 0x7f;
    remaining = remaining >>> 7;
    if (remaining == 0) {
      out.addByte(lowBits);
      break;
    }
    out.addByte(lowBits | 0x80);
  }
  out.add(body);
  return out.toBytes();
}

/// Decodes a base-128 varint at [offset], throwing [FormatException] if it is
/// truncated.
({int value, int end}) _decodeVarint(Uint8List bytes, int offset) {
  final decoded = _tryDecodeVarint(bytes, offset);
  if (decoded == null) {
    throw const FormatException('Truncated protobuf varint');
  }
  return decoded;
}

/// Decodes a base-128 varint at [offset], or returns `null` if the buffer ends
/// before the varint does.
({int value, int end})? _tryDecodeVarint(Uint8List bytes, int offset) {
  var result = 0;
  var shift = 0;
  var position = offset;
  while (position < bytes.length) {
    final byte = bytes[position];
    position++;
    result |= (byte & 0x7f) << shift;
    if (byte & 0x80 == 0) {
      return (value: result, end: position);
    }
    shift += 7;
    if (shift > 63) {
      throw const FormatException('Protobuf varint exceeds 64 bits');
    }
  }
  return null;
}
