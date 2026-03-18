import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../services/exchange_service.dart';

class CurrencyProvider extends ChangeNotifier {
  final ExchangeService _service = ExchangeService();

  List<Currency> _currencies = [];
  Set<String> _favorites = {};
  String _baseCurrency = 'KZT';
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  Map<String, double> _weekHistory = {};
  String _chartFrom = 'USD';

  List<Currency> get currencies => _currencies;
  List<Currency> get favorites =>
      _currencies.where((c) => _favorites.contains(c.code)).toList();
  String get baseCurrency => _baseCurrency;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, double> get weekHistory => _weekHistory;
  String get chartFrom => _chartFrom;

  CurrencyProvider() {
    _loadFavorites();
    fetchRates();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites')?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> fetchRates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rates = await _service.getRates(_baseCurrency);
      _currencies = rates.entries
          .where((e) => Currency.names.containsKey(e.key))
          .map((e) => Currency(
        code: e.key,
        name: Currency.names[e.key] ?? e.key,
        rate: e.value,
        isFavorite: _favorites.contains(e.key),
      ))
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      _lastUpdated = DateTime.now();
      await _loadHistory(_chartFrom, _baseCurrency);
    } catch (e) {
      _error = 'Нет подключения к интернету.\nПроверьте соединение и повторите.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadHistory(String from, String to) async {
    if (from == to) return;
    try {
      _weekHistory = await _service.getWeekHistory(from, to);
      _chartFrom = from;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadHistoryForPair(String from, String to) async {
    if (from == to) return;
    try {
      _weekHistory = await _service.getWeekHistory(from, to);
      _chartFrom = from;
      notifyListeners();
    } catch (_) {}
  }

  void setBaseCurrency(String code) {
    _baseCurrency = code;
    fetchRates();
  }

  void toggleFavorite(String code) {
    if (_favorites.contains(code)) {
      _favorites.remove(code);
    } else {
      _favorites.add(code);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String code) => _favorites.contains(code);
}