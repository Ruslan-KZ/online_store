class Currency {
  final String code;
  final String name;
  final double rate;
  bool isFavorite;

  Currency({
    required this.code,
    required this.name,
    required this.rate,
    this.isFavorite = false,
  });

  static const Map<String, String> names = {
    'KZT': 'Казахстанский тенге',
    'USD': 'Доллар США',
    'EUR': 'Евро',
    'RUB': 'Российский рубль',
    'GBP': 'Британский фунт',
    'CNY': 'Китайский юань',
    'JPY': 'Японская иена',
    'KRW': 'Корейская вона',
    'CHF': 'Швейцарский франк',
    'AED': 'Дирхам ОАЭ',
    'TRY': 'Турецкая лира',
    'CAD': 'Канадский доллар',
    'AUD': 'Австралийский доллар',
  };
}