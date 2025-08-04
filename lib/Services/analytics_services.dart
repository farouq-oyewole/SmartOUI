import 'package:bank_app/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import 'firestore_service.dart';

class AnalyticsService {
  final FirestoreService _firestoreService;

  AnalyticsService(this._firestoreService);

  Future<FinancialAnalytics> generateAnalytics({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    // Ensure this method is implemented in FirestoreService
    final transactions = await _firestoreService.getTransactionsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    final Map<String, double> categoryBreakdown = {};
    final Map<String, double> monthlyTrends = {};

    for (final transaction in transactions) {
      if (transaction.type == 'credit') {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }

      // Category breakdown
      final category = transaction.category;
      categoryBreakdown[category] = (categoryBreakdown[category] ?? 0.0) + transaction.amount;

      // Monthly trends
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0.0) + transaction.amount;
    }

    final netIncome = totalIncome - totalExpenses;
    final daysDifference = endDate.difference(startDate).inDays;
    final averageDaily = daysDifference > 0 ? totalExpenses / daysDifference : 0.0;

    final insights = _generateInsights(transactions, categoryBreakdown);
    final budgetAnalysis = _generateBudgetAnalysis(categoryBreakdown, totalExpenses);

    return FinancialAnalytics(
      userId: userId,
      period: startDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
      averageDaily: averageDaily,
      categoryBreakdown: categoryBreakdown,
      monthlyTrends: monthlyTrends,
      insights: insights,
      budgetAnalysis: budgetAnalysis,
    );
  } catch (e) {
    throw Exception('Failed to generate analytics: $e');
  }
}


  // Generate spending insights
  List<TransactionInsight> _generateInsights(
    List<Transactions> transactions,
    Map<String, double> categoryBreakdown,
  ) {
    final insights = <TransactionInsight>[];

    // Top spending category insight
    if (categoryBreakdown.isNotEmpty) {
      final topCategory = categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      insights.add(TransactionInsight(
        id: 'top_spending_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.spending,
        title: 'Top Spending Category',
        description: 'You spent most on ${topCategory.key} this period',
        impact: topCategory.value,
        category: topCategory.key,
        createdAt: DateTime.now(),
      ));
    }

    // Frequent transactions insight
    final transactionCounts = <String, int>{};
    for (final transaction in transactions) {
      transactionCounts[transaction.name] = (transactionCounts[transaction.name] ?? 0) + 1;
    }

    final frequentTransaction = transactionCounts.entries
        .where((entry) => entry.value > 1)
        .fold<MapEntry<String, int>?>(null, (prev, curr) => 
            prev == null || curr.value > prev.value ? curr : prev);

    if (frequentTransaction != null) {
      insights.add(TransactionInsight(
        id: 'frequent_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.trend,
        title: 'Frequent Transaction',
        description: 'You made ${frequentTransaction.value} transactions to ${frequentTransaction.key}',
        impact: frequentTransaction.value.toDouble(),
        category: 'frequency',
        createdAt: DateTime.now(),
      ));
    }

    // Large transaction insight
    final largeTransactions = transactions
        .where((t) => t.amount > 500) // Configurable threshold
        .toList();

    if (largeTransactions.isNotEmpty) {
      final totalLarge = largeTransactions.fold<double>(0, (sum, t) => sum + t.amount);
      insights.add(TransactionInsight(
        id: 'large_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.anomaly,
        title: 'Large Transactions',
        description: 'You made ${largeTransactions.length} large transactions totaling \$${totalLarge.toStringAsFixed(2)}',
        impact: totalLarge,
        category: 'large_transactions',
        createdAt: DateTime.now(),
      ));
    }

    return insights;
  }

  // Generate budget analysis
  BudgetAnalysis _generateBudgetAnalysis(
    Map<String, double> categoryBreakdown,
    double totalSpent,
  ) {
    // Default budget limits (in a real app, these would come from user settings)
    final defaultBudgets = {
      'food': 500.0,
      'transport': 200.0,
      'shopping': 300.0,
      'entertainment': 150.0,
      'bills': 400.0,
      'other': 200.0,
    };

    final categories = <String, BudgetCategory>{};
    final alerts = <BudgetAlert>[];
    double totalBudget = 0;

    for (final entry in defaultBudgets.entries) {
      final category = entry.key;
      final budgeted = entry.value;
      final spent = categoryBreakdown[category] ?? 0;
      final remaining = budgeted - spent;

      totalBudget += budgeted;

      categories[category] = BudgetCategory(
        name: category,
        budgeted: budgeted,
        spent: spent,
        remaining: remaining,
        transactions: [], // Would be populated with actual transaction IDs
      );

      // Generate alerts for over-budget categories
      if (spent > budgeted) {
        alerts.add(BudgetAlert(
          id: 'alert_${category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.critical,
          category: category,
          message: 'You\'ve exceeded your $category budget by \$${(spent - budgeted).toStringAsFixed(2)}',
          threshold: budgeted,
          current: spent,
          createdAt: DateTime.now(),
        ));
      } else if (spent > budgeted * 0.8) {
        alerts.add(BudgetAlert(
          id: 'warning_${category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AlertType.warning,
          category: category,
          message: 'You\'ve used ${((spent / budgeted) * 100).toStringAsFixed(0)}% of your $category budget',
          threshold: budgeted * 0.8,
          current: spent,
          createdAt: DateTime.now(),
        ));
      }
    }

    return BudgetAnalysis(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      remaining: totalBudget - totalSpent,
      categories: categories,
      alerts: alerts,
    );
  }

  // Get spending trends
  Future<Map<String, List<double>>> getSpendingTrends({
    required String userId,
    required int months,
  }) async {
    try {
      final trends = <String, List<double>>{};
      final now = DateTime.now();

      for (int i = 0; i < months; i++) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        
        final summary = await _firestoreService.getTransactionSummary(
          userId,
          monthStart,
          monthEnd,
        );

        trends['income'] = (trends['income'] ?? [])..add(summary['income'] ?? 0);
        trends['expenses'] = (trends['expenses'] ?? [])..add(summary['expense'] ?? 0);
      }

      return trends;
    } catch (e) {
      throw Exception('Failed to get spending trends: $e');
    }
  }

  // Compare periods
  Future<Map<String, dynamic>> comparePeriods({
    required String userId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) async {
    try {
      final currentSummary = await _firestoreService.getTransactionSummary(
        userId,
        currentStart,
        currentEnd,
      );

      final previousSummary = await _firestoreService.getTransactionSummary(
        userId,
        previousStart,
        previousEnd,
      );

      final incomeChange = (currentSummary['income'] ?? 0) - (previousSummary['income'] ?? 0);
      final expenseChange = (currentSummary['expense'] ?? 0) - (previousSummary['expense'] ?? 0);

      return {
        'current': currentSummary,
        'previous': previousSummary,
        'income_change': incomeChange,
        'expense_change': expenseChange,
        'income_change_percent': previousSummary['income'] != 0 
            ? (incomeChange / previousSummary['income']!) * 100 
            : 0,
        'expense_change_percent': previousSummary['expense'] != 0 
            ? (expenseChange / previousSummary['expense']!) * 100 
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to compare periods: $e');
    }
  }

  // Export data
  Future<Map<String, dynamic>> exportData({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
  required String format, // 'json', 'csv'
}) async {
  try {
    // Make sure this method exists and works
   final List<Transactions> transactions = await _firestoreService.getTransactionsByDateRange(
  userId: userId,
  startDate: DateTime(2000),
  endDate: DateTime.now(),
);



    // Ensure generateAnalytics returns a model with .toJson()
    final analytics = await generateAnalytics(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    if (format.toLowerCase() == 'json') {
      return {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'analytics': analytics.toJson(),
        'exported_at': DateTime.now().toIso8601String(),
      };
    } else if (format.toLowerCase() == 'csv') {
      final csvData = _convertToCSV(transactions); // This should return String
      return {
        'csv_data': csvData,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception('Unsupported export format: $format');
    }
  } catch (e) {
    throw Exception('Failed to export data: $e');
  }
}

  String _convertToCSV(List<Transactions> transactions) {
  final headers = ['Date', 'Name', 'Amount', 'Type', 'Category', 'Description', 'Status'];

  final rows = transactions.map((t) => [
    t.date.toIso8601String(),
    t.name,
    t.amount.toString(),
    t.type,         // Already a string
    t.category,
    t.description,
    t.status,       // Already a string
  ]);

  final csvContent = [headers, ...rows]
      .map((row) => row.map((cell) => '"$cell"').join(','))
      .join('\n');

  return csvContent;
}


final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AnalyticsService(firestoreService);
});
}