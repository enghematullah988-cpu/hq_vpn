import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vpn_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HQVpnApp());
}

class HQVpnApp extends StatelessWidget {
  const HQVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HQ VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061225),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1677FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const HQHomePage(),
    );
  }
}

class VpnServer {
  final String country;
  final String city;
  final String flag;
  final int ping;
  final String endpoint;
  final String id;
  final bool favorite;

  const VpnServer({
    required this.country,
    required this.city,
    required this.flag,
    required this.ping,
    required this.endpoint,
    required this.id,
    this.favorite = false,
  });
}

const servers = <VpnServer>[
  VpnServer(country: 'Canada', city: 'Toronto', flag: '🇨🇦', ping: 42, endpoint: 'YOUR_SERVER_IP:51820', id: 'ca-toronto'),
  VpnServer(country: 'France', city: 'Paris', flag: '🇫🇷', ping: 51, endpoint: 'YOUR_SERVER_IP:51820', id: 'fr-paris'),
  VpnServer(country: 'Japan', city: 'Tokyo', flag: '🇯🇵', ping: 88, endpoint: 'YOUR_SERVER_IP:51820', id: 'jp-tokyo'),
  VpnServer(country: 'Estonia', city: 'Tallinn', flag: '🇪🇪', ping: 67, endpoint: 'YOUR_SERVER_IP:51820', id: 'ee-tallinn'),
  VpnServer(country: 'Italy', city: 'Milan', flag: '🇮🇹', ping: 59, endpoint: 'YOUR_SERVER_IP:51820', id: 'it-milan'),
  VpnServer(country: 'Germany', city: 'Frankfurt', flag: '🇩🇪', ping: 48, endpoint: 'YOUR_SERVER_IP:51820', id: 'de-frankfurt'),
  VpnServer(country: 'Netherlands', city: 'Amsterdam', flag: '🇳🇱', ping: 54, endpoint: 'YOUR_SERVER_IP:51820', id: 'nl-amsterdam'),
];

class HQVpnController extends ChangeNotifier {
  HQVpnController() {
    engine.addListener(_relay);
    _restoreSelected();
  }

  final HqVpnEngine engine = HqVpnEngine();
  bool autoSelect = true;
  bool killSwitch = true;
  VpnServer selected = servers.first;

  bool get connected => engine.connected;
  bool get connecting => engine.connecting;
  Duration get elapsed => engine.elapsed;
  int get down => engine.rx;
  int get up => engine.tx;

  void _relay() => notifyListeners();

  Future<void> _restoreSelected() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('selectedCity');
    VpnServer? match;
    for (final server in servers) {
      if (server.city == city) { match = server; break; }
    }
    if (match != null) {
      selected = match;
      notifyListeners();
    }
  }

  Future<void> connect() async {
    await engine.connect(serverId: selected.id, endpoint: selected.endpoint);
  }

  Future<void> disconnect() => engine.disconnect();

  Future<bool> hasConfig(VpnServer server) => engine.hasConfig(server.id);

  Future<void> saveConfig(VpnServer server, String config) => engine.saveConfig(server.id, config);

  Future<String?> readConfig(VpnServer server) => engine.readConfig(server.id);

  Future<void> deleteConfig(VpnServer server) => engine.deleteConfig(server.id);

  Future<void> select(VpnServer server) async {
    if (connected) await disconnect();
    selected = server;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', server.city);
    notifyListeners();
  }

  @override
  void dispose() {
    engine.removeListener(_relay);
    engine.dispose();
    super.dispose();
  }
}

class HQHomePage extends StatefulWidget {
  const HQHomePage({super.key});

  @override
  State<HQHomePage> createState() => _HQHomePageState();
}

class _HQHomePageState extends State<HQHomePage> {
  final controller = HQVpnController();
  bool autoSelect = true;
  bool killSwitch = true;
  bool darkMode = true;
  String language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      autoSelect = prefs.getBool('autoSelect') ?? true;
      killSwitch = prefs.getBool('killSwitch') ?? true;
      language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSelect', autoSelect);
    await prefs.setBool('killSwitch', killSwitch);
    await prefs.setString('language', language);
  }

  String get title {
    if (language == 'Pashto') return 'HQ VPN';
    if (language == 'Dari') return 'HQ VPN';
    return 'HQ VPN';
  }

  String tr(String en, String ps, String fa) {
    if (language == 'Pashto') return ps;
    if (language == 'Dari') return fa;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final desktop = MediaQuery.sizeOf(context).width >= 900;
        return Scaffold(
          body: SafeArea(
            child: desktop ? _desktop(context) : _mobile(context),
          ),
        );
      },
    );
  }

  Widget _mobile(BuildContext context) {
    final c = controller;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF061225),
                  const Color(0xFF071A34),
                  const Color(0xFF020A16),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: 12,
          child: Row(
            children: [
              _iconButton(Icons.grid_view_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2A50),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.diamond_outlined, size: 16, color: Color(0xFF3C8CFF)),
                    SizedBox(width: 7),
                    Text('Pro', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          top: 78,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
            child: Column(
              children: [
                Text(
                  c.connected
                      ? tr('✓ Connected', '✓ وصل دی', '✓ متصل است')
                      : tr('Not Connected', 'لا نه دی وصل', 'متصل نیست'),
                  style: TextStyle(
                    color: c.connected ? const Color(0xFF3D8BFF) : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _formatDuration(c.elapsed),
                  style: const TextStyle(fontSize: 51, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 16),
                _serverCard(c),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metric(Icons.arrow_downward, 'Downloaded', _formatRate(c.down))),
                    const SizedBox(width: 10),
                    Expanded(child: _metric(Icons.arrow_upward, 'Uploaded', _formatRate(c.up))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: c.connecting ? null : (c.connected ? () => _disconnect(c) : () => _connect(c)),
                    icon: Icon(c.connected ? Icons.power_settings_new : Icons.power_settings_new),
                    label: Text(
                      c.connecting
                          ? tr('Connecting…', 'نښلي…', 'در حال اتصال…')
                          : c.connected
                              ? tr('Disconnect', 'قطع کول', 'قطع اتصال')
                              : tr('Connect', 'وصل کول', 'اتصال'),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1677FF), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(tr('Select servers', 'سرورونه وټاکئ', 'انتخاب سرورها')),
                const SizedBox(height: 10),
                _serverPicker(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _serverCard(HQVpnController c) {
    return InkWell(
      onTap: () => _showServers(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101F35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1C385A)),
        ),
        child: Row(
          children: [
            Text(c.selected.flag, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.selected.country, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(c.selected.city, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            _bars(c.selected.ping),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A304C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2F86FF)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _serverPicker(BuildContext context) {
    return Column(
      children: [
        for (final s in servers.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: () {
                controller.select(s);
                if (controller.connected) controller.disconnect();
              },
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1D31),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: controller.selected.country == s.country
                        ? const Color(0xFF176DDA)
                        : const Color(0xFF172E48),
                  ),
                ),
                child: Row(
                  children: [
                    Text(s.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.country, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(s.city, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    _bars(s.ping),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_border_rounded, size: 20, color: Colors.white60),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => _showServers(context),
          child: Text(tr('View all servers', 'ټول سرورونه وګورئ', 'مشاهده همه سرورها')),
        ),
      ],
    );
  }

  Widget _desktop(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 74,
          color: const Color(0xFF091A2E),
          child: Column(
            children: [
              const SizedBox(height: 22),
              const Icon(Icons.home_rounded, size: 28, color: Colors.white),
              const SizedBox(height: 24),
              ...[
                Icons.public_rounded,
                Icons.shield_outlined,
                Icons.folder_outlined,
                Icons.share_outlined,
                Icons.gps_fixed,
              ].map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Icon(i, color: Colors.white54, size: 23),
                  )),
              const Spacer(),
              const Icon(Icons.help_outline_rounded, color: Colors.white54),
              const SizedBox(height: 25),
              IconButton(
                onPressed: () => _settings(context),
                icon: const Icon(Icons.settings_outlined, color: Colors.white54),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F7FA),
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text('HQ VPN', style: TextStyle(color: Color(0xFF0B1730), fontSize: 20, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined, color: Color(0xFF3D4A5E))),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF3D4A5E))),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _desktopConnectionCard()),
                        const SizedBox(width: 22),
                        Expanded(child: _desktopStatsCard()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopConnectionCard() {
    final c = controller;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 22, spreadRadius: 1, color: Color(0x14000000))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.connected ? 'CONNECTED' : 'NOT CONNECTED',
            style: TextStyle(
              color: c.connected ? const Color(0xFF2E78F7) : const Color(0xFFE85A52),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            c.connected ? 'Connected to VPN' : 'Connect to VPN',
            style: const TextStyle(color: Color(0xFF172033), fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: c.connecting ? null : (c.connected ? () => _disconnect(c) : () => _connect(c)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F5DF4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                c.connecting ? 'Connecting…' : c.connected ? 'Disconnect' : 'Quick Connect',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recent connections', style: TextStyle(color: Color(0xFF263246), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 13),
          for (final s in [servers[1], servers[5]])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(s.flag, style: const TextStyle(fontSize: 27)),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.country, style: const TextStyle(color: Color(0xFF1D293A), fontWeight: FontWeight.w700)),
                      const Text('Fastest server', style: TextStyle(color: Color(0xFF8A94A3), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search countries',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF6F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide.none,
              ),
            ),
            onTap: () => _showServers(context),
          ),
        ],
      ),
    );
  }

  Widget _desktopStatsCard() {
    return Column(
      children: [
        _desktopPanel(
          'Weekly connection time',
          Icons.bar_chart_rounded,
          SizedBox(
            height: 185,
            child: CustomPaint(
              painter: WeeklyBarsPainter(),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 110),
                  child: Text('Mon      Tue      Wed      Thu      Fri      Sat      Sun',
                      style: TextStyle(color: Color(0xFF7C8798), fontSize: 11)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _desktopPanel(
          'Threat Protection Pro',
          Icons.security_rounded,
          Container(
            height: 130,
            alignment: Alignment.center,
            child: const Text(
              'Protection dashboard ready',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _desktopPanel(
          'HQ VPN Servers',
          Icons.public_rounded,
          _desktopServerRows(),
        ),
      ],
    );
  }

  Widget _desktopPanel(String heading, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 22, spreadRadius: 1, color: Color(0x14000000))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF42A4F5)),
              const SizedBox(width: 9),
              Text(heading, style: const TextStyle(color: Color(0xFF1B2738), fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _desktopServerRows() {
    return Column(
      children: [
        for (final s in servers.take(5))
          ListTile(
            dense: true,
            leading: Text(s.flag, style: const TextStyle(fontSize: 22)),
            title: Text(s.country, style: const TextStyle(color: Color(0xFF273448), fontWeight: FontWeight.w600)),
            subtitle: Text(s.city, style: const TextStyle(color: Color(0xFF8A94A3))),
            trailing: Text('${s.ping} ms', style: const TextStyle(color: Color(0xFF68758A))),
            onTap: () {
              controller.select(s);
              _showServers(context);
            },
          ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );

  Widget _bars(int ping) {
    final active = ping < 60 ? 4 : ping < 80 ? 3 : 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        4,
        (i) => Container(
          width: 3,
          height: 5.0 + i * 4,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: i < active ? const Color(0xFF1F84FF) : const Color(0xFF34465E),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0E2038),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19),
      );

  Future<void> _showServers(BuildContext context) async {
    final selected = await showModalBottomSheet<VpnServer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF081A30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ServerSheet(current: controller.selected),
    );
    if (selected != null) {
      controller.select(selected);
    }
  }

  Future<void> _connect(HQVpnController c) async {
    try {
      await c.connect();
    } catch (e) {
      if (!mounted) return;
      await _showConfigRequired(context, c.selected, e.toString());
    }
  }

  Future<void> _disconnect(HQVpnController c) async {
    try {
      await c.disconnect();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('VPN disconnect failed: $e')));
    }
  }

  Future<void> _showConfigRequired(BuildContext context, VpnServer server, String error) async {
    final existing = await controller.readConfig(server);
    final text = TextEditingController(text: existing ?? '');
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1B30),
        title: Text('WireGuard • ${server.city}'),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Real VPN mode is enabled. Add the WireGuard client profile for this server before connecting.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: text,
                minLines: 8,
                maxLines: 14,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '[Interface]\nPrivateKey = ...\nAddress = 10.8.0.2/32\nDNS = 1.1.1.1\n\n[Peer]\nPublicKey = ...\nAllowedIPs = 0.0.0.0/0, ::/0\nEndpoint = server:51820',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await controller.saveConfig(server, text.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WireGuard profile saved securely.')));
              } catch (e) {
                if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _settings(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF081A30),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('HQ VPN Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, color: Color(0xFF2385FF)),
                  title: const Text('WireGuard server profiles'),
                  subtitle: const Text('Install or replace the real .conf profile for each server'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showServers(context);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto server selection'),
                  value: autoSelect,
                  onChanged: (v) {
                    setSheetState(() => autoSelect = v);
                    setState(() {});
                    _saveSettings();
                  },
                ),
                SwitchListTile(
                  title: const Text('Kill switch (policy)'),
                  value: killSwitch,
                  onChanged: (v) {
                    setSheetState(() => killSwitch = v);
                    setState(() {});
                    _saveSettings();
                  },
                ),
                ListTile(
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: language,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Pashto', child: Text('پښتو')),
                      DropdownMenuItem(value: 'Dari', child: Text('دری')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setSheetState(() => language = v);
                      setState(() {});
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _formatRate(int bytes) {
    if (bytes <= 0) return '0 Mb/s';
    final mbps = (bytes * 8) / 1000000;
    return '${mbps.toStringAsFixed(1)} Mb/s';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _ServerSheet extends StatefulWidget {
  final VpnServer current;
  const _ServerSheet({required this.current});

  @override
  State<_ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends State<_ServerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = servers.where((s) {
      final q = query.toLowerCase();
      return s.country.toLowerCase().contains(q) || s.city.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .76,
      minChildSize: .5,
      maxChildSize: .92,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          children: [
            Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 18),
            const Text('Select servers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF10243D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF10243D), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _tab('Global', true),
                  _tab('Special', false),
                  _tab('Selected', false),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Auto selection'),
              subtitle: const Text('Uses server metadata; live health can be connected later'),
              value: true,
              onChanged: (_) {},
              secondary: const Icon(Icons.sync_rounded, color: Color(0xFF2385FF)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      onTap: () => Navigator.pop(context, s),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: BorderSide(
                          color: widget.current.country == s.country
                              ? const Color(0xFF1677FF)
                              : const Color(0xFF1A304C),
                        ),
                      ),
                      tileColor: const Color(0xFF0C1C30),
                      leading: Text(s.flag, style: const TextStyle(fontSize: 28)),
                      title: Text(s.country, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(s.city, style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _bars(s.ping),
                          const SizedBox(width: 12),
                          const Icon(Icons.star_border_rounded, color: Colors.white54),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, bool active) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1677FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(text),
        ),
      );

  Widget _bars(int ping) {
    final active = ping < 60 ? 4 : ping < 80 ? 3 : 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        4,
        (i) => Container(
          width: 3,
          height: 5.0 + i * 4,
          margin: const EdgeInsets.only(left: 2),
          color: i < active ? const Color(0xFF1F84FF) : const Color(0xFF34465E),
        ),
      ),
    );
  }
}

class WeeklyBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD3D8DF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final List<double> xs = [45.0, 105.0, 165.0, 225.0, 285.0, 345.0, 405.0];
    final List<double> heights = [118.0, 94.0, 112.0, 72.0, 50.0, 104.0, 18.0];
    for (var i = 0; i < xs.length; i++) {
      canvas.drawLine(Offset(xs[i], 10), Offset(xs[i], heights[i]), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
