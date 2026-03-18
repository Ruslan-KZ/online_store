import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Все доступные коды без дублей
    final baseCodes = currencyProvider.currencies.map((c) => c.code).toSet().toList()..sort();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings_rounded, color: scheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Настройки',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Внешний вид'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded),
              title: const Text('Тёмная тема'),
              subtitle: Text(themeProvider.isDark ? 'Включена' : 'Выключена'),
              value: themeProvider.isDark,
              onChanged: themeProvider.toggleTheme,
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'Валюты'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Базовая валюта'),
                  subtitle: const Text('Все курсы считаются относительно неё'),
                  trailing: baseCodes.isNotEmpty
                      ? DropdownButton<String>(
                    value: baseCodes.contains(currencyProvider.baseCurrency)
                        ? currencyProvider.baseCurrency
                        : baseCodes.first,
                    underline: const SizedBox(),
                    items: baseCodes
                        .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) currencyProvider.setBaseCurrency(v);
                    },
                    dropdownColor: scheme.surface,
                  )
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Обновить курсы'),
                  subtitle: currencyProvider.lastUpdated != null
                      ? Text('Последнее: ${_formatTime(currencyProvider.lastUpdated!)}')
                      : null,
                  trailing: currencyProvider.isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  onTap: currencyProvider.isLoading ? null : currencyProvider.fetchRates,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: 'О приложении'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.public_rounded),
                  title: Text('Источник данных'),
                  subtitle: Text('fawazahmed0 currency API — 200+ валют'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.update_rounded),
                  title: Text('Обновление'),
                  subtitle: Text('Курсы обновляются каждый день'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Версия приложения'),
                  subtitle: Text('1.0.0 - создатель Руслан'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('CurrencyCharts © 2026',
                style: TextStyle(color: scheme.outline, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}.${dt.month}.${dt.year} $h:$m';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}