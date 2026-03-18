import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _from = 'USD';
  String _to = 'KZT';
  final _controller = TextEditingController(text: '1');
  double _result = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _convert());
  }

  void _convert() {
    final provider = context.read<CurrencyProvider>();
    final amount = double.tryParse(_controller.text) ?? 0;
    final rates = {
      for (var c in provider.currencies) c.code: c.rate
    };
    rates[provider.baseCurrency] = 1.0;

    if (rates.containsKey(_from) && rates.containsKey(_to)) {
      // Конвертация через базовую валюту
      final inBase = amount / (rates[_from] ?? 1);
      setState(() => _result = inBase * (rates[_to] ?? 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();
    final codes = provider.currencies.map((c) => c.code).toList()
      ..add(provider.baseCurrency);
    codes.sort();
    final unique = codes.toSet().toList()..sort();

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Конвертер валют',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // FROM
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Сумма',
                                border: OutlineInputBorder()),
                            onChanged: (_) => _convert(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: unique.contains(_from) ? _from : unique.first,
                          items: unique
                              .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _from = v);
                            _convert();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Swap button
                    IconButton.filled(
                      onPressed: () {
                        setState(() {
                          final tmp = _from;
                          _from = _to;
                          _to = tmp;
                        });
                        _convert();
                      },
                      icon: const Icon(Icons.swap_vert),
                    ),
                    const SizedBox(height: 16),
                    // TO
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _result.toStringAsFixed(4),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: unique.contains(_to) ? _to : unique.first,
                          items: unique
                              .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _to = v);
                            _convert();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (provider.lastUpdated != null)
              Center(
                child: Text(
                  'Курсы актуальны на ${provider.lastUpdated!.hour}:${provider.lastUpdated!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: scheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}