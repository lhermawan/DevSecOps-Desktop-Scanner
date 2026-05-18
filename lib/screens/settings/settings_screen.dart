import 'package:fluent_ui/fluent_ui.dart';

import '../../services/tool_installer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _installer = ToolInstallerService();
  Map<String, bool> _toolStatus = {};
  String _installHint = 'Klik check untuk cek semua tools scanner.';

  Future<void> _checkAllTools() async {
    final result = await _installer.checkAllTools();
    setState(() {
      _toolStatus = result;
      _installHint = 'Pilih tool lalu klik tombol panduan install.';
    });
  }

  Future<void> _showInstallHint(String tool) async {
    final message = await _installer.getInstallCommand(tool);
    setState(() => _installHint = '[$tool] $message');
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Settings')),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text('Scanner Tools Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Cek ketersediaan semua tools scanner dan lihat command install resmi per OS.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _checkAllTools, child: const Text('Check All Tools')),
              const SizedBox(height: 12),
              ...ToolInstallerService.supportedTools.map(
                (tool) {
                  final status = _toolStatus[tool];
                  final statusText = status == null ? 'Belum dicek' : (status ? 'Terpasang ✅' : 'Belum ❌');
                  return Card(
                    child: ListTile(
                      title: Text(tool),
                      subtitle: Text(statusText),
                      trailing: Button(
                        onPressed: () => _showInstallHint(tool),
                        child: const Text('Install Guide'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              InfoBar(
                title: const Text('Install Hint'),
                content: Text(_installHint),
                severity: InfoBarSeverity.info,
              ),
              const SizedBox(height: 16),
              const Text('WhatsApp API Endpoint'),
              const SizedBox(height: 8),
              const TextBox(placeholder: 'https://soc-internal/api/wa-notify'),
              const SizedBox(height: 16),
              const Text('SOC Laravel API Endpoint'),
              const SizedBox(height: 8),
              const TextBox(placeholder: 'https://soc-internal/api/scans'),
            ],
          ),
        ),
      ),
    );
  }
}
