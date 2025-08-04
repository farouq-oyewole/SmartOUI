// ignore_for_file: file_names, deprecated_member_use

import 'package:bank_app/providers/transaction_provider.dart';
import 'package:bank_app/providers/theme_provider.dart';
import 'package:bank_app/components/transaction_history.dart';
import 'package:bank_app/utils/responsive_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  final List<String> _filterOptions = [
    'All', 'credit', 'debit', 'transfer', 'payment',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDesktop),
            if (!isDesktop) _buildMobileFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionsTab('recent'),
                  _buildTransactionsTab('month'),
                  _buildTransactionsTab('all'),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Recent'),
              Tab(text: 'This Month'),
              Tab(text: 'All Time'),
              Tab(text: 'Analytics'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildFilterButton()),
          const SizedBox(width: 8),
          Expanded(child: _buildDateRangeButton()),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(String period) {
    return Consumer(
      builder: (context, ref, _) {
        final transactionsAsync = ref.watch(transactionsProvider);

        return transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transactions) {
            final filteredByType = _selectedFilter.toLowerCase() == 'all'
                ? transactions
                : transactions.where((txn) =>
                    txn.type.toLowerCase() == _selectedFilter.toLowerCase() ||
                    txn.category.toLowerCase() == _selectedFilter.toLowerCase()).toList();

            final filteredByDate = _selectedDateRange == null
                ? filteredByType
                : filteredByType.where((txn) =>
                    txn.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                    txn.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))).toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(transactionsProvider),
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  TransactionHistory(
                    transactions: filteredByDate,
                    showHeader: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer(
      builder: (context, ref, _) {
        final transactionsAsync = ref.watch(transactionsProvider);

        return transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transactions) {
            final creditData = transactions.where((txn) => txn.isCredit).toList();
            final debitData = transactions.where((txn) => txn.isDebit).toList();

            double totalCredit = creditData.fold(0.0, (sum, txn) => sum + txn.amount);
            double totalDebit = debitData.fold(0.0, (sum, txn) => sum + txn.amount);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildBarChart(totalCredit, totalDebit),
                  const SizedBox(height: 32),
                  _buildLineChart(transactions),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBarChart(double credit, double debit) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Total Income vs Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: credit, color: Colors.green, width: 20),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: debit, color: Colors.red, width: 20),
                    ]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Income');
                            case 1:
                              return const Text('Expense');
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Transactions> transactions) {
    final sortedTxns = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedTxns.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedTxns[i].amount));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Transaction Flow', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                      dotData: FlDotData(show: true),
                    )
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedTxns.length) {
                            final date = sortedTxns[index].date;
                            return Text('${date.day}/${date.month}');
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.filter_list),
      label: Text(_selectedFilter),
      onPressed: _showFilterDialog,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(_selectedDateRange != null ? 'Custom' : 'All Time'),
      onPressed: _showDateRangePicker,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
}
