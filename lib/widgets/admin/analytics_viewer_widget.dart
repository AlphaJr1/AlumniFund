import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';

/// Widget untuk menampilkan analytics collection dari Cloud Functions
class AnalyticsViewerWidget extends StatefulWidget {
  const AnalyticsViewerWidget({super.key});

  @override
  State<AnalyticsViewerWidget> createState() => _AnalyticsViewerWidgetState();
}

class _AnalyticsViewerWidgetState extends State<AnalyticsViewerWidget> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsSummary? _summary;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _analyticsService.getAnalyticsSummary();
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Target Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSummary,
                    tooltip: 'Retry',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Analytics Belum Tersedia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Analytics akan tersedia setelah ada target wisuda yang ditutup. Cloud Functions akan otomatis membuat analytics data.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_summary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No analytics data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Target Analytics (Last 6 Months)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSummary,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Summary metrics
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSummaryCard(
                  'Total Targets',
                  _summary!.totalTargets.toString(),
                  Icons.flag,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Fully Funded',
                  _summary!.fullyFundedCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Partially Funded',
                  _summary!.partiallyFundedCount.toString(),
                  Icons.pie_chart,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Avg Success Rate',
                  '${_summary!.averagePercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Avg Duration',
                  '${_summary!.averageDuration.toStringAsFixed(0)} days',
                  Icons.timer,
                  Colors.teal,
                ),
                _buildSummaryCard(
                  'Total Graduates',
                  _summary!.totalGraduates.toString(),
                  Icons.school,
                  Colors.indigo,
                ),
                _buildSummaryCard(
                  'Total Collected',
                  _formatCurrency(_summary!.totalCollected),
                  Icons.attach_money,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recent analytics list
            const Text(
              'Recent Targets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<TargetAnalytics>>(
              stream: _analyticsService.getTargetAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No recent analytics');
                }

                final analytics = snapshot.data!.take(5).toList();

                return Column(
                  children:
                      analytics.map((a) => _buildAnalyticsItem(a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(TargetAnalytics analytics) {
    final statusColor = analytics.fundingStatus == 'fully_funded'
        ? Colors.green
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${analytics.month} ${analytics.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${analytics.percentage}% funded • ${analytics.graduatesCount} graduates',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(analytics.collectedAmount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (analytics.durationDays != null)
                Text(
                  '${analytics.durationDays} days',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
