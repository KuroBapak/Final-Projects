import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final itemsAsync = ref.watch(userItemsProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          int safe = 0;
          int warning = 0;
          int expired = 0;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (var item in items) {
            final expiryDate = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
            final daysLeft = expiryDate.difference(today).inDays;
            
            if (daysLeft <= 0) {
              expired++;
            } else if (daysLeft < 7) {
              warning++;
            } else {
              safe++;
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Item Status Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: safe.toDouble(),
                            title: '$safe',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: warning.toDouble(),
                            title: '$warning',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: expired.toDouble(),
                            title: '$expired',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildLegend(Colors.green, 'Safe (> 7 days)'),
                  _buildLegend(Colors.orange, 'Warning (< 7 days)'),
                  _buildLegend(Colors.red, 'Expired'),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
