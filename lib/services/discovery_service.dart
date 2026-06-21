// Samsung TV discovery via REST probe on port 8001.
// GET http://{ip}:8001/api/v2/ must return a 200 with device info
// before a WebSocket connection is attempted.
// Manual IP entry is the primary discovery path.

class DiscoveryService {
  // TODO: implement REST probe to confirm Samsung TV at given IP
  // Response contains device name, model, and token support info.
  Future<bool> probe(String ip) async {
    throw UnimplementedError('DiscoveryService.probe not yet implemented');
  }
}
