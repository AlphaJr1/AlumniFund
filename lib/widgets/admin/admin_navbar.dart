import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin/admin_auth_provider.dart';
import '../../utils/admin_config.dart';

class AdminNavbar extends ConsumerWidget {
  final VoidCallback? onMenuTap;

  const AdminNavbar({
    super.key,
    this.onMenuTap,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go(AdminConfig.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminEmail = ref.watch(adminEmailProvider);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              // Hamburger menu (mobile only)
              if (MediaQuery.of(context).size.width < 1024)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuTap,
                ),
              const SizedBox(width: 8),
              const Text(
                '🎓',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'ADMIN PANEL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          // Right side
          Row(
            children: [
              // Admin info (hide on very small screens)
              if (MediaQuery.of(context).size.width > 500)
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width > 768
                            ? 200
                            : 120, // Shorter on mobile
                      ),
                      child: Text(
                        adminEmail ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),

              // Divider (hide on very small screens)
              if (MediaQuery.of(context).size.width > 500)
                Container(
                  height: 24,
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

              // Logout button (icon only on very small screens)
              MediaQuery.of(context).size.width > 500
                  ? TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(
                        Icons.logout,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () => _logout(context),
                      icon: const Icon(
                        Icons.logout,
                        size: 20,
                        color: Color(0xFFDC2626),
                      ),
                      tooltip: 'Logout',
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
