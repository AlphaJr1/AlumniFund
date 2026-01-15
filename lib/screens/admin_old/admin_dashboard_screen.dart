import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Admin dashboard screen
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final incomeList = ref.watch(incomeListProvider);
    final expenseList = ref.watch(expenseListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Saldo',
                    value: Formatters.formatCurrency(totalBalance),
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Pemasukan',
                    value: Formatters.formatCurrency(totalIncome),
                    icon: Icons.arrow_downward,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Pengeluaran',
                    value: Formatters.formatCurrency(totalExpense),
                    icon: Icons.arrow_upward,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Transaksi',
                    value: '${incomeList.length + expenseList.length}',
                    icon: Icons.receipt_long,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingXL),
            
            // Action buttons
            Text(
              'Aksi Cepat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            _buildActionButton(
              context,
              title: 'Tambah Pengeluaran',
              subtitle: 'Input pengeluaran baru dengan bukti',
              icon: Icons.remove_circle_outline,
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.pushNamed(context, '/admin/add-expense');
              },
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            _buildActionButton(
              context,
              title: 'Tambah Pemasukan',
              subtitle: 'Catat pemasukan dari alumni',
              icon: Icons.add_circle_outline,
              color: AppTheme.successColor,
              onTap: () {
                Navigator.pushNamed(context, '/admin/add-income');
              },
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            _buildActionButton(
              context,
              title: 'Pengaturan',
              subtitle: 'Kelola info rekening & target dana',
              icon: Icons.settings,
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.pushNamed(context, '/admin/settings');
              },
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            _buildActionButton(
              context,
              title: 'Lihat Dashboard Publik',
              subtitle: 'Tampilan yang dilihat alumni',
              icon: Icons.visibility,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build stat card
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build action button
  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
