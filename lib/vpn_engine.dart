import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Real WireGuard engine used by HQ VPN.
/// No fake/simulated connection is reported: the UI follows the native
/// WireGuard engine state and traffic counters.
class HqVpnEngine extends ChangeNotifier {
  HqVpnEngine() {
    _stageSub = _wg.vpnStageSnapshot.listen((stage) {
      _stage = stage.toString();
      final normalized = stage.toString().toLowerCase();
      _connected = normalized.endsWith('.connected') || normalized == 'connected';
      if (_connected) {
        _connectedAt ??= DateTime.now();
      } else if (normalized.endsWith('.disconnected') || normalized == 'disconnected') {
        _connectedAt = null;
      }
      notifyListeners();
    });
    _trafficSub = _wg.trafficSnapshot.listen((stats) {
      _rx = _trafficBytes(stats, 'rx', 'totalDownload', 'received', 'download');
      _tx = _trafficBytes(stats, 'tx', 'totalUpload', 'sent', 'upload');
      notifyListeners();
    });
  }

  final _wg = WireGuardFlutter.instance;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  StreamSubscription<dynamic>? _stageSub;
  StreamSubscription<dynamic>? _trafficSub;

  bool _initialized = false;
  bool _connected = false;
  bool _connecting = false;
  String _stage = 'down';
  int _rx = 0;
  int _tx = 0;
  DateTime? _connectedAt;
  Timer? _refreshTimer;

  bool get connected => _connected;
  bool get connecting => _connecting;
  String get stage => _stage;
  int get rx => _rx;
  int get tx => _tx;
  Duration get elapsed => _connectedAt == null ? Duration.zero : DateTime.now().difference(_connectedAt!);

  Future<void> initialize() async {
    if (_initialized) return;
    await _wg.initialize(
      interfaceName: 'hq0',
      vpnName: 'HQ VPN',
      iosAppGroup: 'group.com.hqvpn.app',
    );
    _initialized = true;
  }

  Future<bool> hasConfig(String serverId) async {
    final value = await _secure.read(key: _key(serverId));
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> saveConfig(String serverId, String config) async {
    _validateConfig(config);
    await _secure.write(key: _key(serverId), value: config.trim());
  }

  Future<String?> readConfig(String serverId) => _secure.read(key: _key(serverId));

  Future<void> deleteConfig(String serverId) => _secure.delete(key: _key(serverId));

  Future<void> connect({required String serverId, required String endpoint}) async {
    if (_connected || _connecting) return;
    final config = await readConfig(serverId);
    if (config == null || config.trim().isEmpty) {
      throw StateError('No WireGuard profile is configured for this server.');
    }
    _validateConfig(config);
    await initialize();

    _connecting = true;
    _stage = 'preparing';
    _rx = 0;
    _tx = 0;
    notifyListeners();

    try {
      final actualEndpoint = _extractEndpoint(config) ?? endpoint;
      if (actualEndpoint == 'YOUR_SERVER_IP:51820' || actualEndpoint.trim().isEmpty) {
        throw const FormatException('Set a real WireGuard Endpoint in the client profile.');
      }
      await _wg.startVpn(
        serverAddress: actualEndpoint,
        wgQuickConfig: config,
        providerBundleIdentifier: 'com.hqvpn.app.WGExtension',
      );
      _connectedAt = DateTime.now();
      _startRefresh();
    } catch (_) {
      _connecting = false;
      _connected = false;
      _stage = 'error';
      notifyListeners();
      rethrow;
    }
    _connecting = false;
    _connected = await _wg.isConnected();
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _wg.stopVpn();
    } finally {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      _connected = false;
      _connecting = false;
      _connectedAt = null;
      _stage = 'down';
      notifyListeners();
    }
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        _connected = await _wg.isConnected();
        final stats = await _wg.trafficStats();
        _rx = _trafficBytes(stats, 'rx', 'totalDownload', 'received', 'download');
        _tx = _trafficBytes(stats, 'tx', 'totalUpload', 'sent', 'upload');
        notifyListeners();
      } catch (_) {
        // Native stream remains the source of truth; transient stats errors
        // must not make a live VPN appear disconnected.
      }
    });
  }

  static int _trafficBytes(Map<String, dynamic> stats, String a, String b, String c, String d) {
    final value = stats[a] ?? stats[b] ?? stats[c] ?? stats[d] ?? 0;
    final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    // wireguard_flutter_plus exposes totalDownload/totalUpload in KiB.
    if (stats.containsKey(b)) return (n * 1024).round();
    return n.round();
  }

  static String? _extractEndpoint(String config) {
    final match = RegExp(r'(?mi)^\s*Endpoint\s*=\s*(\S+)').firstMatch(config);
    return match?.group(1);
  }

  static void _validateConfig(String config) {
    final c = config.replaceAll('\r\n', '\n');
    if (!RegExp(r'(?m)^\s*\[Interface\]\s*$').hasMatch(c) ||
        !RegExp(r'(?m)^\s*\[Peer\]\s*$').hasMatch(c)) {
      throw const FormatException('WireGuard config must contain [Interface] and [Peer].');
    }
    if (!RegExp(r'(?mi)^\s*PrivateKey\s*=\s*\S+').hasMatch(c)) {
      throw const FormatException('WireGuard config is missing Interface PrivateKey.');
    }
    if (!RegExp(r'(?mi)^\s*PublicKey\s*=\s*\S+').hasMatch(c)) {
      throw const FormatException('WireGuard config is missing Peer PublicKey.');
    }
    if (!RegExp(r'(?mi)^\s*Endpoint\s*=\s*\S+').hasMatch(c)) {
      throw const FormatException('WireGuard config is missing Peer Endpoint.');
    }
  }

  String _key(String serverId) => 'hqvpn.wireguard.$serverId';

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _stageSub?.cancel();
    _trafficSub?.cancel();
    super.dispose();
  }
}
