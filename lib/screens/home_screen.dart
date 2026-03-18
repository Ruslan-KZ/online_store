import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/currency_provider.dart';
import '../widgets/currency_card.dart';
import 'converter_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _RatesTab(search: _search, onSearch: (v) => setState(() => _search = v)),
      const ConverterScreen(),
      const FavoritesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Курсы'),
          NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), label: 'Конвертер'),
          NavigationDestination(icon: Icon(Icons.star_rounded), label: 'Избранное'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Настройки'),
        ],
      ),
    );
  }
}

class _RatesTab extends StatefulWidget {
  final String search;
  final ValueChanged<String> onSearch;
  const _RatesTab({required this.search, required this.onSearch});

  @override
  State<_RatesTab> createState() => _RatesTabState();
}

class _RatesTabState extends State<_RatesTab> {
  String _chartCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();
    final scheme = Theme.of(context).colorScheme;

    final filtered = provider.currencies
        .where((c) =>
    c.code.toLowerCase().contains(widget.search.toLowerCase()) ||
        c.name.toLowerCase().contains(widget.search.toLowerCase()))
        .toList();

    final baseCodes = provider.currencies.map((c) => c.code).toSet().toList()..sort();

    // Список для графика — все валюты кроме базовой
    final chartCodes = baseCodes.where((c) => c != provider.baseCurrency).toList();

    // Если выбранная валюта пропала из списка — берём первую доступную
    if (chartCodes.isNotEmpty && !chartCodes.contains(_chartCurrency)) {
      _chartCurrency = chartCodes.first;
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchRates,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.currency_exchange, color: scheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Курсы валют',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            if (provider.lastUpdated != null)
                              Text('Обновлено ${DateFormat('HH:mm').format(provider.lastUpdated!)}',
                                  style: TextStyle(color: scheme.outline, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Базовая валюта
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, size: 18, color: scheme.outline),
                          const SizedBox(width: 8),
                          Text('База: ', style: TextStyle(color: scheme.outline)),
                          if (baseCodes.isNotEmpty)
                            DropdownButton<String>(
                              value: baseCodes.contains(provider.baseCurrency)
                                  ? provider.baseCurrency
                                  : baseCodes.first,
                              items: baseCodes
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) provider.setBaseCurrency(v);
                              },
                              underline: const SizedBox(),
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                              dropdownColor: scheme.surface,
                            ),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: provider.isLoading ? null : provider.fetchRates,
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Селектор пары для графика
                    if (chartCodes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.show_chart_rounded, size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text('График: ', style: TextStyle(color: scheme.outline, fontSize: 13)),
                            DropdownButton<String>(
                              value: chartCodes.contains(_chartCurrency) ? _chartCurrency : chartCodes.first,
                              items: chartCodes
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _chartCurrency = v);
                                  provider.loadHistoryForPair(v, provider.baseCurrency);
                                }
                              },
                              underline: const SizedBox(),
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                              dropdownColor: scheme.surface,
                            ),
                            Text(
                              ' / ${provider.baseCurrency}',
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // График
                    if (provider.weekHistory.isNotEmpty)
                      _ChartCard(
                        history: provider.weekHistory,
                        label: '$_chartCurrency/${provider.baseCurrency}',
                      ),
                    const SizedBox(height: 12),

                    // Поиск
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск валюты (USD, EUR...)',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: widget.onSearch,
                    ),
                    const SizedBox(height: 4),
                    if (provider.lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          'Последнее обновление: ${DateFormat('dd.MM.yyyy HH:mm').format(provider.lastUpdated!)}',
                          style: TextStyle(color: scheme.outline, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (provider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (provider.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 64, color: scheme.outline),
                        const SizedBox(height: 16),
                        Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.outline)),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: provider.fetchRates,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Text('Ничего не найдено', style: TextStyle(color: scheme.outline))),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => CurrencyCard(currency: filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Map<String, double> history;
  final String label;
  const _ChartCard({required this.history, required this.label});

  String _formatRate(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(3);
    return value.toStringAsFixed(5);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = history.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (sorted.isEmpty) return const SizedBox();

    final spots = sorted.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final values = sorted.map((e) => e.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final diff = maxY - minY;
    final pad = diff == 0 ? minY * 0.01 : diff * 0.2;

    final firstVal = values.first;
    final lastVal = values.last;
    final change = lastVal - firstVal;
    final changePct = firstVal != 0 ? (change / firstVal * 100) : 0.0;
    final isPositive = change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Text('за 7 дней', style: TextStyle(color: scheme.outline, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 13, color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text('${changePct.abs().toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: changeColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatRate(lastVal),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.primary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: minY - pad,
                maxY: maxY + pad,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: diff == 0 ? 1 : diff / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.outline.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 62,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(_formatRate(value),
                              style: TextStyle(fontSize: 9, color: scheme.outline)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox();
                        final mid = sorted.length ~/ 2;
                        if (idx != 0 && idx != mid && idx != sorted.length - 1) return const SizedBox();
                        final parts = sorted[idx].key.split('-');
                        if (parts.length < 3) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${parts[2]}.${parts[1]}',
                              style: TextStyle(fontSize: 9, color: scheme.outline)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final parts = idx < sorted.length ? sorted[idx].key.split('-') : [];
                        final dateLabel = parts.length >= 3
                            ? '${parts[2]}.${parts[1]}.${parts[0]}'
                            : '';
                        return LineTooltipItem(
                          '$dateLabel\n${_formatRate(s.y)}',
                          TextStyle(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: scheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) {
                        final isLast = idx == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 2.5,
                          color: isLast ? scheme.primary : scheme.primary.withOpacity(0.4),
                          strokeWidth: isLast ? 2.5 : 0,
                          strokeColor: scheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.2),
                          scheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}