import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../widgets/admin/metric_card.dart';
import '../../../widgets/admin/transaction_table.dart';
import '../../../widgets/admin/income_input_modal.dart';
import '../../../widgets/admin/edit_transaction_modal.dart';
import '../../../widgets/admin/system_health_widget.dart';
import '../../../widgets/admin/analytics_viewer_widget.dart';
import '../../../providers/general_fund_provider.dart';
import '../../../providers/graduation_target_provider.dart';
import '../../../providers/admin/pending_submissions_provider.dart';
import '../../../providers/admin/dashboard_metrics_provider.dart';
import '../../../providers/admin/admin_actions_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../utils/admin_config.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/admin/feedback_stat_card.dart';

class DashboardOverview extends ConsumerStatefulWidget {
  const DashboardOverview({super.key});

  @override
  ConsumerState<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends ConsumerState<DashboardOverview> {
  bool _isHealthAnalyticsCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Metrics Cards
          _buildMetricsGrid(context),
          const SizedBox(height: 32),

          // Section 2: Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context),
          const SizedBox(height: 32),

          // Section 3: System Health & Analytics (Collapsible)
          _buildCollapsibleSection(
            title: 'System Health & Analytics',
            isCollapsed: _isHealthAnalyticsCollapsed,
            onToggle: () {
              setState(() {
                _isHealthAnalyticsCollapsed = !_isHealthAnalyticsCollapsed;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                  child: SystemHealthWidget(),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  flex: 1,
                  child: AnalyticsViewerWidget(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section 4: Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isCollapsed,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                  color: const Color(0xFF6B7280),
                ),
                const Spacer(),
                Text(
                  isCollapsed ? 'Show' : 'Hide',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedCrossFade(
          firstChild: child,
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive columns and card heights
    int crossAxisCount = 4;
    double cardHeight = 220; // Increased desktop default

    if (screenWidth < 1024) {
      // Tablet
      crossAxisCount = 2;
      cardHeight = 240;
    }
    if (screenWidth < 600) {
      // Mobile
      crossAxisCount = 1;
      cardHeight = 250; // Generous height for mobile
    }
    if (screenWidth < 400) {
      // Very small mobile (320px)
      crossAxisCount = 1;
      cardHeight = 240;
    }

    final cards = [
      _buildGeneralFundCard(ref),
      _buildActiveTargetCard(ref),
      _buildDeadlineCard(ref),
      _buildPendingCard(context, ref),
      FeedbackStatCard(
        onTap: () => context.go('/admin/feedbacks'),
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: cardHeight, // Use fixed height instead of aspect ratio
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildGeneralFundCard(WidgetRef ref) {
    final fundAsync = ref.watch(generalFundProvider);
    final monthlyChange = ref.watch(monthlyFundChangeProvider);
    final activeTarget = ref.watch(activeTargetProvider); // Fetch active target

    return fundAsync.when(
      data: (fund) {
        final reservedAmount = activeTarget?.allocatedFromFund ?? 0.0;
        final balanceStr = CurrencyFormatter.formatCurrency(fund.balance);
        final changeStr = monthlyChange >= 0
            ? '+${CurrencyFormatter.formatCurrency(monthlyChange)}'
            : CurrencyFormatter.formatCurrency(monthlyChange);

        String subtitleText;
        if (reservedAmount > 0) {
          subtitleText =
              'Reserved: ${CurrencyFormatter.formatCurrency(reservedAmount)}';
        } else {
          subtitleText = '$changeStr this month';
        }

        return MetricCard(
          icon: '💰',
          label: 'General Fund Balance',
          value: balanceStr,
          valueColor: const Color(0xFF14b8a6),
          subtitle: subtitleText,
        );
      },
      loading: () => const MetricCard(
        icon: '💰',
        label: 'General Fund Balance',
        value: 'Loading...',
        valueColor: Color(0xFF14b8a6),
      ),
      error: (_, __) => const MetricCard(
        icon: '💰',
        label: 'General Fund Balance',
        value: 'Error',
        valueColor: Color(0xFFEF4444),
      ),
    );
  }

  Widget _buildActiveTargetCard(WidgetRef ref) {
    final target = ref.watch(activeTargetProvider);

    if (target == null) {
      return const MetricCard(
        icon: '🎯',
        label: 'Active Target Status',
        value: 'No active target',
        valueColor: Color(0xFF6B7280),
      );
    }

    // Capitalize first letter of month
    final monthCapitalized =
        target.month[0].toUpperCase() + target.month.substring(1);
    final displayText = '$monthCapitalized ${target.year}';

    // Use displayAmount (actual + allocated) for progress
    final progress = target.targetAmount > 0
        ? (target.displayAmount / target.targetAmount * 100).toStringAsFixed(0)
        : '0';

    // Show allocation breakdown in subtitle
    String subtitle;
    if (target.allocatedFromFund > 0) {
      subtitle =
          '$progress% • From Fund: ${CurrencyFormatter.formatCurrency(target.allocatedFromFund)}';
    } else {
      final graduateNames = target.graduates.map((g) => g.name).join(', ');
      subtitle = '$progress% • $graduateNames';
    }

    return MetricCard(
      icon: '🎯',
      label: 'Active Target Status',
      value: displayText,
      valueColor: const Color(0xFF3B82F6),
      subtitle: subtitle,
    );
  }

  Widget _buildDeadlineCard(WidgetRef ref) {
    final target = ref.watch(activeTargetProvider);
    final days = ref.watch(daysUntilDeadlineProvider);
    final color = ref.watch(deadlineColorProvider);

    if (target == null || days == null) {
      return const MetricCard(
        icon: '⏰',
        label: 'Nearest Deadline',
        value: '-',
        valueColor: Color(0xFF6B7280),
      );
    }

    final valueStr = _formatDeadlineText(target.deadline);

    final deadlineStr =
        DateFormat('dd MMM yyyy', 'id_ID').format(target.deadline);

    return MetricCard(
      icon: '⏰',
      label: 'Nearest Deadline',
      value: valueStr,
      valueColor: color,
      subtitle: deadlineStr,
    );
  }

  Widget _buildPendingCard(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingSubmissionsCountProvider);

    final valueStr = count == 0
        ? 'All validated'
        : count == 1
            ? '1 pending'
            : '$count pending';

    return MetricCard(
      icon: '❤️',
      label: 'Pending Validations',
      value: valueStr,
      valueColor: count > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      subtitle: count > 0 ? 'Click to validate' : null,
      onTap:
          count > 0 ? () => context.go(AdminConfig.validateIncomeRoute) : null,
    );
  }

  String _formatDeadlineText(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final totalHours = difference.inHours;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    // Jika kurang dari 48 jam (2 hari), tampilkan dalam jam
    if (totalHours < 48) {
      if (totalHours > 0) {
        return '$totalHours jam lagi';
      } else if (minutes > 0) {
        return '$minutes menit lagi';
      } else {
        return 'Kurang dari 1 menit';
      }
    }

    // Jika lebih dari 48 jam, tampilkan dalam hari
    final days = difference.inDays;
    return days == 1 ? '1 day left' : '$days days left';
  }

  Widget _buildQuickActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Action button builder
    Widget buildActionButton({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      bool expanded = false,
    }) {
    final button = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return expanded ? Expanded(child: button) : button;
    }

    final buttons = [
      buildActionButton(
        icon: Icons.add_circle_outline,
        label: 'Input Income',
        color: const Color(0xFF10B981), // Green
        expanded: !isMobile,
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const IncomeInputModal(),
          );
          if (result == true) {
            // Refresh dashboard data after successful input
            ref.invalidate(generalFundProvider);
            ref.invalidate(recentMixedTransactionsProvider);
            ref.invalidate(graduationTargetsProvider);
          }
        },
      ),
      buildActionButton(
        icon: Icons.remove_circle_outline,
        label: 'Input Expense',
        color: const Color(0xFFEF4444), // Red
        expanded: !isMobile,
        onTap: () => context.go(AdminConfig.inputExpenseRoute),
      ),
      buildActionButton(
        icon: Icons.flag_outlined,
        label: 'Create New Target',
        color: const Color(0xFF3B82F6), // Blue
        expanded: !isMobile,
        onTap: () => context.go(AdminConfig.manageTargetsRoute),
      ),
    ];

    // Responsive layout: horizontal row (desktop/tablet), vertical stack (mobile)
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((btn) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: btn,
                ))
            .toList(),
      );
    } else {
      return Row(
        children: [
          buttons[0],
          const SizedBox(width: 16),
          buttons[1],
          const SizedBox(width: 16),
          buttons[2],
        ],
      );
    }
  }

  Widget _buildRecentActivity() {
    final transactionsAsync = ref.watch(recentMixedTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        return TransactionTable(
          transactions: transactions,
          onEdit: (transaction) async {
            final result = await showDialog<bool>(
              context: ref.context,
              builder: (context) =>
                  EditTransactionModal(transaction: transaction),
            );

            if (result == true) {
              // Show success message
              if (ref.context.mounted) {
                ScaffoldMessenger.of(ref.context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Transaction updated successfully'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              // Refresh data
              ref.invalidate(generalFundProvider);
              ref.invalidate(recentMixedTransactionsProvider);
              ref.invalidate(graduationTargetsProvider);
            }
          },
          onDelete: (transaction) async {
            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: ref.context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Text('Delete Transaction'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you sure you want to delete this transaction?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type: ${transaction.isIncome ? "Income" : "Expense"}',
                            style: TextStyle(
                              color: transaction.isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ${CurrencyFormatter.formatCurrency(transaction.amount)}',
                            style: TextStyle(
                              color: transaction.isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (transaction.targetMonth != null)
                            Text('Target: ${transaction.targetMonth}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This will:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444)),
                          ),
                          Text('• Remove transaction record',
                              style: TextStyle(fontSize: 14)),
                          Text('• Revert balance changes',
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: 8),
                          Text(
                            '⚠️ This action CANNOT be undone!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Yes, Delete'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                // Delete transaction with balance reconciliation
                await ref.read(adminActionsProvider).deleteTransaction(
                      transactionId: transaction.id,
                      type: transaction.isIncome ? 'income' : 'expense',
                      amount: transaction.amount,
                      targetId: transaction.targetId,
                    );

                // Show success message
                if (ref.context.mounted) {
                  ScaffoldMessenger.of(ref.context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Transaction deleted successfully'),
                      backgroundColor: Color(0xFF10B981),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                // Refresh data
                ref.invalidate(generalFundProvider);
                ref.invalidate(recentMixedTransactionsProvider);
                ref.invalidate(graduationTargetsProvider);
              } catch (e) {
                // Show error message
                if (ref.context.mounted) {
                  ScaffoldMessenger.of(ref.context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Failed to delete: ${e.toString()}'),
                      backgroundColor: const Color(0xFFEF4444),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          },
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
