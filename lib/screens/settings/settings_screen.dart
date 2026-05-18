import 'package:fluent_ui/fluent_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Settings')),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: const [
              Text('Scanner Path'),
              SizedBox(height: 8),
              TextBox(placeholder: 'Path gitleaks/semgrep/trivy'),
              SizedBox(height: 16),
              Text('WhatsApp API Endpoint'),
              SizedBox(height: 8),
              TextBox(placeholder: 'https://soc-internal/api/wa-notify'),
              SizedBox(height: 16),
              Text('SOC Laravel API Endpoint'),
              SizedBox(height: 8),
              TextBox(placeholder: 'https://soc-internal/api/scans'),
            ],
          ),
        ),
      ),
    );
  }
}
