class Receipt {
  final String id;           // RCP168937394…
  final String userId;       // Firebase UID
  final String name;         // payer’s name
  final String matric;
  final String department;
  final String level;
  final String feeType;
  final String bankName;
  final String accountNumber;
  final double amount;       // ₦ total, already incl. 1.5 % fee
  final DateTime date;

  Receipt({
    required this.id,
    required this.userId,
    required this.name,
    required this.matric,
    required this.department,
    required this.level,
    required this.feeType,
    required this.bankName,
    required this.accountNumber,
    required this.amount,
    required this.date,
  });

  /// Convert to a plain map for Realtime DB
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'matric': matric,
        'department': department,
        'level': level,
        'feeType': feeType,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  /// Handy factory if you ever need to read receipts back
  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        matric: json['matric'] as String,
        department: json['department'] as String,
        level: json['level'] as String,
        feeType: json['feeType'] as String,
        bankName: json['bankName'] as String,
        accountNumber: json['accountNumber'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}