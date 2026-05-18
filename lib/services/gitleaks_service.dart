import 'dart:convert';

import '../models/vulnerability.dart';

class GitleaksService {
  List<Vulnerability> parse(String rawOutput) {
    final parsed = jsonDecode(rawOutput);
    if (parsed is! List) return [];

    return parsed.map<Vulnerability>((item) {
      return Vulnerability(
        scanner: 'Gitleaks',
        severity: 'High',
        file: item['File']?.toString() ?? '-',
        line: int.tryParse(item['StartLine']?.toString() ?? '') ?? 0,
        issue: item['Description']?.toString() ?? 'Potential secret leak',
        remediation: 'Move secret to vault/.env and rotate key.',
      );
    }).toList();
  }
}
