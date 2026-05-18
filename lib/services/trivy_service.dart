import 'dart:convert';

import '../models/vulnerability.dart';

class TrivyService {
  List<Vulnerability> parse(String rawOutput) {
    final parsed = jsonDecode(rawOutput);
    final results = parsed['Results'];
    if (results is! List) return [];

    final items = <Vulnerability>[];
    for (final result in results) {
      final vulns = result['Vulnerabilities'];
      if (vulns is! List) continue;

      for (final vuln in vulns) {
        items.add(
          Vulnerability(
            scanner: 'Trivy',
            severity: vuln['Severity']?.toString() ?? 'Medium',
            file: result['Target']?.toString() ?? '-',
            line: 0,
            issue: vuln['Title']?.toString() ?? vuln['VulnerabilityID']?.toString() ?? 'Dependency vulnerability',
            remediation: vuln['FixedVersion'] != null
                ? 'Upgrade package to ${vuln['FixedVersion']}'
                : 'Upgrade dependency to latest patched version.',
          ),
        );
      }
    }
    return items;
  }
}
