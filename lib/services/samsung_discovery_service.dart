import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import '../models/samsung_device.dart';

class SamsungDiscoveryService {
  static const _probeTimeout = Duration(seconds: 5);
  static const _srvTimeout = Duration(seconds: 2);
  static const _mdnsService = '_samsungctrl._tcp.local';

  /// REST probe: confirms Samsung TV at [ip] and returns its friendly name.
  /// Returns null if [ip] is unreachable or not a Samsung TV.
  Future<SamsungDevice?> probe(String ip) async {
    try {
      final uri = Uri.parse('http://$ip:8001/api/v2/');
      final response = await http.get(uri).timeout(_probeTimeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final device = body['device'] as Map<String, dynamic>?;
      final name = (device?['name'] as String?)?.isNotEmpty == true
          ? device!['name'] as String
          : (device?['modelName'] as String?) ?? 'Samsung TV';
      return SamsungDevice(ip: ip, name: name);
    } catch (_) {
      return null;
    }
  }

  /// mDNS scan for Samsung TVs advertising _samsungctrl._tcp.
  /// Confirms each result via [probe] before returning. 5 second scan window.
  Future<List<SamsungDevice>> scanMdns() async {
    final found = <SamsungDevice>[];
    final seenIps = <String>{};
    final client = MDnsClient();

    try {
      await client.start();

      final ptrStream = client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_mdnsService),
          )
          .timeout(
            _probeTimeout,
            onTimeout: (sink) => sink.close(),
          );

      await for (final ptr in ptrStream) {
        final srvStream = client
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(_srvTimeout, onTimeout: (sink) => sink.close());

        await for (final srv in srvStream) {
          final ipStream = client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(_srvTimeout, onTimeout: (sink) => sink.close());

          await for (final ipRecord in ipStream) {
            final ip = ipRecord.address.address;
            if (seenIps.contains(ip)) continue;
            seenIps.add(ip);
            final device = await probe(ip);
            if (device != null) found.add(device);
          }
        }
      }
    } catch (_) {
    } finally {
      client.stop();
    }

    return found;
  }
}
