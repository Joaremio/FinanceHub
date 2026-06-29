class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String categoryId;
  final DateTime date;
  final String? note;
  final String? locationName;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    this.locationName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get hasLocation =>
      locationLatitude != null && locationLongitude != null;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'] ?? 'expense',
      categoryId: json['categoryId'].toString(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      note: json['note'],
      locationName: json['locationName'],
      locationAddress: json['locationAddress'],
      locationLatitude: double.tryParse(
        json['locationLatitude']?.toString() ?? '',
      ),
      locationLongitude: double.tryParse(
        json['locationLongitude']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'locationName': locationName,
      'locationAddress': locationAddress,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? categoryId,
    DateTime? date,
    String? note,
    String? locationName,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
    );
  }
}
