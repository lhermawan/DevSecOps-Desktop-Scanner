import 'package:fluent_ui/fluent_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _SecurityCard(title: 'Threat Level', value: 'Low', icon: FluentIcons.shield),
          _SecurityCard(title: 'Critical Findings', value: '0', icon: FluentIcons.error),
          _SecurityCard(title: 'High Findings', value: '1', icon: FluentIcons.warning),
          _SecurityCard(title: 'Security Score', value: '92/100', icon: FluentIcons.completed),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
