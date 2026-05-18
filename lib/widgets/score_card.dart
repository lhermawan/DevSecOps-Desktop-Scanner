import 'package:fluent_ui/fluent_ui.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('$score/100', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
