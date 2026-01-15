import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';

/// Widget untuk menampilkan system health status
class SystemHealthWidget extends StatefulWidget {
  const SystemHealthWidget({super.key});

  @override
  State<SystemHealthWidget> createState() => _SystemHealthWidgetState();
}

class _SystemHealthWidgetState extends State<SystemHealthWidget> {
  final AnalyticsService _analyticsService = AnalyticsService();
  SystemHealth? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() => _loading = true);
    try {
      final health = await _analyticsService.getSystemHealth();
      setState(() {
        _health = health;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _health = SystemHealth(
          status: SystemStatus.error,
          analyticsCount24h: 0,
          message: 'Error loading health: $e',
        );
        _loading = false;
      });
    }
  }

  Color _getStatusColor(SystemStatus status) {
    switch (status) {
      case SystemStatus.healthy:
        return Colors.green;
      case SystemStatus.warning:
        return Colors.orange;
      case SystemStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(SystemStatus status) {
    switch (status) {
      case SystemStatus.healthy:
        return Icons.check_circle;
      case SystemStatus.warning:
        return Icons.warning;
      case SystemStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(SystemStatus status) {
    switch (status) {
      case SystemStatus.healthy:
        return 'Healthy';
      case SystemStatus.warning:
        return 'Warning';
      case SystemStatus.error:
        return 'Error';
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

    if (_health == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Unable to load system health'),
        ),
      );
    }

    final statusColor = _getStatusColor(_health!.status);
    final statusIcon = _getStatusIcon(_health!.status);
    final statusText = _getStatusText(_health!.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'System Health',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHealth,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            
            // Status indicator
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _health!.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Analytics (24h)',
                    _health!.analyticsCount24h.toString(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Last Update',
                    _health!.lastAnalyticsUpdate != null
                        ? _formatTime(_health!.lastAnalyticsUpdate!)
                        : 'N/A',
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Cloud Functions info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Functions Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFunctionStatus('checkDeadlines', 'Hourly'),
                  _buildFunctionStatus('updateClosingSoonStatus', 'Daily'),
                  _buildFunctionStatus('cleanupOldSubmissions', 'Weekly'),
                  _buildFunctionStatus('onTargetClosed', 'Event-based'),
                  _buildFunctionStatus('routeIncome', 'Event-based'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
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
              fontSize: 20,
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

  Widget _buildFunctionStatus(String name, String schedule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            schedule,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(time);
  }
}
