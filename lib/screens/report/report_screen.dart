import 'package:fluent_ui/fluent_ui.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(title: const Text('Vulnerability Report')),
      content: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Halaman report scan & histori akan ditampilkan di sini (SQLite + SOC API).'),
      ),
    );
  }
}
