// lib/models/calculation_history.dart
import 'dart:convert';

class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      expression: json['expression'],
      result: json['result'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  static String encodeList(List<CalculationHistory> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  static List<CalculationHistory> decodeList(String jsonStr) {
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => CalculationHistory.fromJson(e)).toList();
  }
}
