class FinancialAnalytics {
  final String userId;
  final DateTime period;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final double averageDaily;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlyTrends;
  final List<TransactionInsight> insights;
  final BudgetAnalysis budgetAnalysis;

  FinancialAnalytics({
    required this.userId,
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.averageDaily,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    required this.insights,
    required this.budgetAnalysis,
  });

  factory FinancialAnalytics.fromJson(Map<String, dynamic> json) {
    return FinancialAnalytics(
      userId: json['userId'],
      period: DateTime.parse(json['period']),
      totalIncome: json['totalIncome'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      netIncome: json['netIncome'].toDouble(),
      averageDaily: json['averageDaily'].toDouble(),
      categoryBreakdown: Map<String, double>.from(json['categoryBreakdown']),
      monthlyTrends: Map<String, double>.from(json['monthlyTrends']),
      insights: (json['insights'] as List)
          .map((i) => TransactionInsight.fromJson(i))
          .toList(),
      budgetAnalysis: BudgetAnalysis.fromJson(json['budgetAnalysis']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'period': period.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netIncome': netIncome,
      'averageDaily': averageDaily,
      'categoryBreakdown': categoryBreakdown,
      'monthlyTrends': monthlyTrends,
      'insights': insights.map((i) => i.toJson()).toList(),
      'budgetAnalysis': budgetAnalysis.toJson(),
    };
  }

  // Convenience getters
  double get savingsRate => totalIncome > 0 ? (netIncome / totalIncome) * 100 : 0;
  String get topSpendingCategory => categoryBreakdown.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  bool get isOverBudget => budgetAnalysis.totalSpent > budgetAnalysis.totalBudget;
}

class TransactionInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final double impact;
  final String category;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  TransactionInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.category,
    required this.createdAt,
    this.data = const {},
  });

  factory TransactionInsight.fromJson(Map<String, dynamic> json) {
    return TransactionInsight(
      id: json['id'],
      type: InsightType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      description: json['description'],
      impact: json['impact'].toDouble(),
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'impact': impact,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }
}

class BudgetAnalysis {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final Map<String, BudgetCategory> categories;
  final List<BudgetAlert> alerts;

  BudgetAnalysis({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.categories,
    required this.alerts,
  });

  factory BudgetAnalysis.fromJson(Map<String, dynamic> json) {
    return BudgetAnalysis(
      totalBudget: json['totalBudget'].toDouble(),
      totalSpent: json['totalSpent'].toDouble(),
      remaining: json['remaining'].toDouble(),
      categories: (json['categories'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, BudgetCategory.fromJson(value)),
      ),
      alerts: (json['alerts'] as List)
          .map((a) => BudgetAlert.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': remaining,
      'categories': categories.map((key, value) => MapEntry(key, value.toJson())),
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }

  double get spentPercentage => totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
  bool get isOverBudget => totalSpent > totalBudget;
}

class BudgetCategory {
  final String name;
  final double budgeted;
  final double spent;
  final double remaining;
  final List<String> transactions;

  BudgetCategory({
    required this.name,
    required this.budgeted,
    required this.spent,
    required this.remaining,
    required this.transactions,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      name: json['name'],
      budgeted: json['budgeted'].toDouble(),
      spent: json['spent'].toDouble(),
      remaining: json['remaining'].toDouble(),
      transactions: List<String>.from(json['transactions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'budgeted': budgeted,
      'spent': spent,
      'remaining': remaining,
      'transactions': transactions,
    };
  }

  double get spentPercentage => budgeted > 0 ? (spent / budgeted) * 100 : 0;
  bool get isOverBudget => spent > budgeted;
}

class BudgetAlert {
  final String id;
  final AlertType type;
  final String category;
  final String message;
  final double threshold;
  final double current;
  final DateTime createdAt;

  BudgetAlert({
    required this.id,
    required this.type,
    required this.category,
    required this.message,
    required this.threshold,
    required this.current,
    required this.createdAt,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    return BudgetAlert(
      id: json['id'],
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      category: json['category'],
      message: json['message'],
      threshold: json['threshold'].toDouble(),
      current: json['current'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'category': category,
      'message': message,
      'threshold': threshold,
      'current': current,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum InsightType {
  spending,
  saving,
  income,
  trend,
  anomaly,
}

enum AlertType {
  warning,
  critical,
  info,
}
