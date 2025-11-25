// ignore_for_file: deprecated_member_use

import 'package:bank_app/Providers/local_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RecentEventsSection extends ConsumerWidget {
  final VoidCallback onSeeAll;
  final int limit;

  const RecentEventsSection({
    super.key,
    required this.onSeeAll,
    this.limit = 1, // ✅ Show ONLY 1 event
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(recentEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(0, 2),
              color: Colors.black.withOpacity(0.08),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Text(
                    "Recent Events",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ Events or Empty State
          if (events.isEmpty)
            Center(
              child: Text(
                "No events yet, click See All to check for events.",
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: events.take(limit).map((event) {
                return _buildEventItem(
                  title: event.title,
                  date: event.date, // Ensure your model provides this
                  icon: Icons.event_available,
                  isDark: isDark,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String date,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // ✅ Leading Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.green.withOpacity(0.15)
                  : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),

          // ✅ Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          // ✅ Date
          Text(
            date,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
