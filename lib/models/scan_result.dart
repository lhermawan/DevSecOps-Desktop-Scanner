import 'vulnerability.dart';

class ScanResult {
  const ScanResult({
    this.id,
    required this.projectPath,
    required this.startedAt,
    required this.finishedAt,
    required this.vulnerabilities,
    this.errors = const [],
  });

  final int? id;
  final String projectPath;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<Vulnerability> vulnerabilities;
  final List<String> errors;

  Map<String, int> get severityCount {
    final map = <String, int>{'critical': 0, 'high': 0, 'medium': 0, 'low': 0};
    for (final v in vulnerabilities) {
      final key = v.severity.toLowerCase();
      if (map.containsKey(key)) {
        map[key] = map[key]! + 1;
      }
    }
    return map;
  }

  int get securityScore {
    if (vulnerabilities.isEmpty) return 100;

    final weightedMap = {'critical': 10, 'high': 6, 'medium': 3, 'low': 1};
    var weightedTotal = 0;
    for (final v in vulnerabilities) {
      weightedTotal += weightedMap[v.severity.toLowerCase()] ?? 2;
    }

    final score = 100 - (weightedTotal ~/ 2);
    return score.clamp(0, 100);
  }
}
