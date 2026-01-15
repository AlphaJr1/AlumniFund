// Admin Configuration Constants
class AdminConfig {
  // Admin email whitelist
  static const String adminEmail = 'adrianalfajri@gmail.com';
  
  // Session configuration
  static const int sessionTimeoutDays = 7;
  
  // Admin routes
  static const String loginRoute = '/admin/login';
  static const String dashboardRoute = '/admin/dashboard';
  static const String validateIncomeRoute = '/admin/validate-income';
  static const String inputExpenseRoute = '/admin/input-expense';
  static const String manageTargetsRoute = '/admin/manage-targets';
  static const String settingsRoute = '/admin/settings';
  
  // Helper method to check if user is admin
  static bool isAdmin(String? email) {
    return email != null && email == adminEmail;
  }
}
