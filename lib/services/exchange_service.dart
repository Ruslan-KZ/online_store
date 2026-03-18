import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeService {
  static const String _base = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1';

  Future<Map<String, double>> getRates(String baseCurrency) async {
    final base = baseCurrency.toLowerCase();
    final response = await http.get(
      Uri.parse('$_base/currencies/$base.json'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawRates = data[base] as Map;
      final rates = Map<String, double>.from(
        rawRates.map((k, v) => MapEntry(
          (k as String).toUpperCase(),
          (v as num).toDouble(),
        )),
      );
      rates[baseCurrency.toUpperCase()] = 1.0;
      return rates;
    }
    throw Exception('Ошибка загрузки курсов: ${response.statusCode}');
  }

  Future<Map<String, double>> getWeekHistory(String from, String to) async {
    final f = from.toLowerCase();
    final t = to.toLowerCase();
    final history = <String, double>{};

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      try {
        final response = await http.get(
          Uri.parse(ni
              'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$dateStr/v1/currencies/$f.json'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rates = data[f] as Map;
          if (rates.containsKey(t)) {
            history[dateStr] = (rates[t] as num).toDouble();
          }
        }
      } catch (_) {}
    }
    return history;
  }
}