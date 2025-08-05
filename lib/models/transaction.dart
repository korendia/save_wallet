class Transaction_ {
  final String type; // '수입' 또는 '지출'
  final String category;
  final int amount;
  final DateTime date;

  Transaction_({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
  });
}
