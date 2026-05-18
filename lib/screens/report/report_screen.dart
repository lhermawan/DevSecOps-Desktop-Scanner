import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: PageHeader(
          title: const Text('Vulnerability Report'),
          leading: Button(onPressed: () => context.go('/'), child: const Text('← Kembali')),
        ),
        content: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Halaman report scan & histori akan ditampilkan di sini (SQLite + SOC API).'),
        ),
      ),
    );
  }
}
