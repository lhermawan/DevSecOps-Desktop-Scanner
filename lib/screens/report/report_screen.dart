import 'package:fluent_ui/fluent_ui.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Laporan scan akan tampil di sini (severity, file, issue, remediation).'),
        ),
      ),
    );
  }
}
