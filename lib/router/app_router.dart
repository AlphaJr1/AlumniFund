import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/warmup_screen.dart';
import '../screens/public_dashboard_screen.dart';
import '../screens/authenticated_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_layout.dart';
import '../screens/admin/views/dashboard_overview.dart';
import '../screens/admin/views/validate_income_view.dart';
import '../screens/admin/views/input_expense_view.dart';
import '../screens/admin/views/manage_targets_view.dart';
import '../screens/admin/views/manage_users_view.dart';
import '../screens/admin/views/manage_brand_identity_view.dart';
import '../screens/admin/views/settings_view.dart';
import '../screens/admin/views/feedback_list_screen.dart';
import '../screens/admin/views/graduation_schedule_view.dart';
import '../screens/user_identification_test_page.dart';
import '../screens/registered_users_page.dart';
import '../utils/admin_config.dart';

/// GoRouter configuration - Public + Admin (Phase 1 + Phase 2A)
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/warmup',
    routes: [
      // Warmup screen - preload data
      GoRoute(
        path: '/warmup',
        name: 'warmup',
        builder: (context, state) => const WarmupScreen(),
      ),

      // Public dashboard (ROOT PATH) - With user identification
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const AuthenticatedDashboardScreen(),
      ),

      // User Identification Test Page (untuk development)
      GoRoute(
        path: '/test-user-id',
        name: 'test-user-id',
        builder: (context, state) => const UserIdentificationTestPage(),
      ),

      // Registered Users Page (untuk development)
      GoRoute(
        path: '/registered-users',
        name: 'registered-users',
        builder: (context, state) => const RegisteredUsersPage(),
      ),

      // Admin login route (public)
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
        redirect: (context, state) {
          // If already logged in as admin, redirect to dashboard
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && AdminConfig.isAdmin(user.email)) {
            return AdminConfig.dashboardRoute;
          }
          return null; // Allow access to login page
        },
      ),

      // Admin routes (protected) - Using ShellRoute for persistent layout
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(child: child);
        },
        routes: [
          // Dashboard Overview
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardOverview(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Validate Income
          GoRoute(
            path: '/admin/validate-income',
            name: 'admin-validate-income',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ValidateIncomeView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Input Expense
          GoRoute(
            path: '/admin/input-expense',
            name: 'admin-input-expense',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InputExpenseView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Manage Targets
          GoRoute(
            path: '/admin/manage-targets',
            name: 'admin-manage-targets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageTargetsView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Settings
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Manage Users
          GoRoute(
            path: '/admin/manage-users',
            name: 'admin-manage-users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageUsersView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Brand Identity
          GoRoute(
            path: '/admin/brand-identity',
            name: 'admin-brand-identity',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ManageBrandIdentityView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Feedback list
          GoRoute(
            path: '/admin/feedbacks',
            name: 'admin-feedbacks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeedbackListScreen(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),

          // Graduation Schedule
          GoRoute(
            path: '/admin/graduation-schedule',
            name: 'admin-graduation-schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GraduationScheduleView(),
            ),
            redirect: (context, state) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || !AdminConfig.isAdmin(user.email)) {
                return AdminConfig.loginRoute;
              }
              return null;
            },
          ),
        ],
      ),

      // Redirect /admin to /admin/dashboard
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null || !AdminConfig.isAdmin(user.email)) {
            return AdminConfig.loginRoute;
          }
          return AdminConfig.dashboardRoute;
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
