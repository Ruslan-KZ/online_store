import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';

class CurrencyCard extends StatelessWidget {
  final Currency currency;

  const CurrencyCard({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CurrencyProvider>();
    final isFav = context.watch<CurrencyProvider>().isFavorite(currency.code);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            currency.code[0],
            style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(currency.code,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(currency.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.rate.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary),
                ),
                Text(
                  'Покупка ${(currency.rate * 0.998).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : scheme.outline,
              ),
              onPressed: () => provider.toggleFavorite(currency.code),
            ),
          ],
        ),
      ),
    );
  }
}