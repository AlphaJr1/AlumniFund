import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/admin/pending_submissions_provider.dart';
import '../../utils/admin_config.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go(AdminConfig.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSubmissionsCountProvider);

    return Container(
      width: 240,
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _MenuItem(
                  icon: '📊',
                  label: 'Dashboard',
                  route: AdminConfig.dashboardRoute,
                  isActive: currentRoute == AdminConfig.dashboardRoute,
                ),
                _MenuItem(
                  icon: '💰',
                  label: 'Validate Income',
                  route: AdminConfig.validateIncomeRoute,
                  isActive: currentRoute == AdminConfig.validateIncomeRoute,
                  badge: pendingCount > 0 ? pendingCount : null,
                ),
                _MenuItem(
                  icon: '📤',
                  label: 'Input Expense',
                  route: AdminConfig.inputExpenseRoute,
                  isActive: currentRoute == AdminConfig.inputExpenseRoute,
                ),
                _MenuItem(
                  icon: '🎯',
                  label: 'Manage Targets',
                  route: AdminConfig.manageTargetsRoute,
                  isActive: currentRoute == AdminConfig.manageTargetsRoute,
                ),
                _MenuItem(
                  icon: '⚙️',
                  label: 'Settings',
                  route: AdminConfig.settingsRoute,
                  isActive: currentRoute == AdminConfig.settingsRoute,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Logout button (bottom)
          InkWell(
            onTap: () => _logout(context),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    '🚪',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFCA5A5), // Light red
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final String route;
  final bool isActive;
  final int? badge;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.go(route);
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF14b8a6) // Teal
                : Colors.transparent,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            children: [
              // Icon
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFFD1D5DB), // Light gray
                  ),
                ),
              ),

              // Badge (if any)
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Red
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
