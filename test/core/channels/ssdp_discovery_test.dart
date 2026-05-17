import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SsdpResponse.parse', () {
    // A representative M-SEARCH response from a Roku device.
    const rokuResponse =
        'HTTP/1.1 200 OK\r\n'
        'Cache-Control: max-age=3600\r\n'
        'ST: roku:ecp\r\n'
        'USN: uuid:roku:ecp:P0A070000007\r\n'
        'Ext: \r\n'
        'Server: Roku UPnP/1.0 MiniUPnPd/1.4\r\n'
        'LOCATION: http://192.168.1.7:8060/\r\n'
        '\r\n';

    test('parses a Roku response into typed fields', () {
      final response = SsdpResponse.parse(rokuResponse);
      expect(response, isNotNull);
      expect(response!.usn, 'uuid:roku:ecp:P0A070000007');
      expect(response.location, 'http://192.168.1.7:8060/');
      expect(response.host, '192.168.1.7');
      expect(response.searchTarget, 'roku:ecp');
      expect(response.server, 'Roku UPnP/1.0 MiniUPnPd/1.4');
    });

    test('lower-cases header keys regardless of source casing', () {
      const mixedCase =
          'HTTP/1.1 200 OK\r\n'
          'lOcAtIoN: http://192.168.1.42:1976/\r\n'
          'uSn: uuid:webos-1234\r\n'
          '\r\n';
      final response = SsdpResponse.parse(mixedCase);
      expect(response, isNotNull);
      expect(response!.location, 'http://192.168.1.42:1976/');
      expect(response.host, '192.168.1.42');
      expect(response.usn, 'uuid:webos-1234');
    });

    test('falls back to the NT header when ST is absent (NOTIFY)', () {
      const notify =
          'NOTIFY * HTTP/1.1\r\n'
          'LOCATION: http://192.168.1.55:7676/\r\n'
          'USN: uuid:samsung-9999\r\n'
          'NT: urn:samsung.com:device:RemoteControlReceiver:1\r\n'
          '\r\n';
      final response = SsdpResponse.parse(notify);
      expect(response, isNotNull);
      expect(
        response!.searchTarget,
        'urn:samsung.com:device:RemoteControlReceiver:1',
      );
    });

    test('returns null when the LOCATION header is missing', () {
      const noLocation =
          'HTTP/1.1 200 OK\r\n'
          'USN: uuid:roku:ecp:P0A070000007\r\n'
          '\r\n';
      expect(SsdpResponse.parse(noLocation), isNull);
    });

    test('returns null when the USN header is missing', () {
      const noUsn =
          'HTTP/1.1 200 OK\r\n'
          'LOCATION: http://192.168.1.7:8060/\r\n'
          '\r\n';
      expect(SsdpResponse.parse(noUsn), isNull);
    });

    test('returns null for empty or junk input', () {
      expect(SsdpResponse.parse(''), isNull);
      expect(SsdpResponse.parse('not an ssdp datagram'), isNull);
    });

    test('tolerates LF-only line endings', () {
      const lfOnly =
          'HTTP/1.1 200 OK\n'
          'LOCATION: http://192.168.1.7:8060/\n'
          'USN: uuid:roku:ecp:P0A070000007\n';
      final response = SsdpResponse.parse(lfOnly);
      expect(response, isNotNull);
      expect(response!.host, '192.168.1.7');
    });

    test('host is empty or null when LOCATION carries no host', () {
      const noHost =
          'HTTP/1.1 200 OK\r\n'
          'LOCATION: /relative/path/only\r\n'
          'USN: uuid:weird\r\n'
          '\r\n';
      final response = SsdpResponse.parse(noHost);
      expect(response, isNotNull);
      expect(response!.host, anyOf(isNull, isEmpty));
    });
  });
}
