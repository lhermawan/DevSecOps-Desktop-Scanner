import 'dart:convert';

import '../models/vulnerability.dart';

class SemgrepService {
  List<Vulnerability> parse(String rawOutput) {
    final parsed = jsonDecode(rawOutput);
    final results = parsed['results'];
    if (results is! List) return [];

    return results.map<Vulnerability>((item) {
      final extra = item['extra'] as Map<String, dynamic>? ?? {};
      final severity = (extra['severity']?.toString() ?? 'medium').toLowerCase();
      return Vulnerability(
        scanner: 'Semgrep',
        severity: severity[0].toUpperCase() + severity.substring(1),
        file: item['path']?.toString() ?? '-',
        line: item['start']?['line'] as int? ?? 0,
        issue: extra['message']?.toString() ?? 'SAST issue detected',
        remediation: 'Review rule recommendation and apply secure coding practice.',
      );
    }).toList();
  }
}
