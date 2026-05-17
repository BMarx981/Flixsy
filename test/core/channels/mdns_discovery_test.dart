import 'package:flixsy/core/channels/mdns_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

// The mDNS network path (PTR -> SRV -> A record resolution) needs a real
// multicast socket and is covered by integration testing, not here. These
// unit tests cover the value type and the lifecycle guards.
void main() {
  group('MdnsService', () {
    test('exposes its resolved fields', () {
      final service = MdnsService(
        name: 'Living Room TV._androidtvremote2._tcp.local',
        host: 'android-1234.local',
        port: 6466,
        address: '192.168.1.31',
      );
      expect(service.name, contains('_androidtvremote2._tcp'));
      expect(service.host, 'android-1234.local');
      expect(service.port, 6466);
      expect(service.address, '192.168.1.31');
    });
  });

  group('MdnsDiscovery', () {
    test('is not running before start', () {
      final discovery = MdnsDiscovery(serviceType: '_androidtvremote2._tcp');
      expect(discovery.isRunning, isFalse);
    });

    test('dispose before start does not throw and closes the stream', () async {
      final discovery = MdnsDiscovery(serviceType: '_androidtvremote2._tcp');
      await discovery.dispose();
      expect(discovery.isRunning, isFalse);
      // The services stream is closed, so listening completes immediately.
      await expectLater(discovery.services, emitsDone);
    });
  });
}
