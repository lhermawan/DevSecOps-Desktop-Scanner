import 'vulnerability.dart';

class ScanResult {
  const ScanResult({
    required this.projectPath,
    required this.startedAt,
    required this.finishedAt,
    required this.vulnerabilities,
  });

  final String projectPath;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<Vulnerability> vulnerabilities;

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
    final penaltyMap = {'critical': 30, 'high': 20, 'medium': 10, 'low': 5};
    var score = 100;
    for (final v in vulnerabilities) {
      score -= penaltyMap[v.severity.toLowerCase()] ?? 0;
    }
    return score.clamp(0, 100);
  }
}
