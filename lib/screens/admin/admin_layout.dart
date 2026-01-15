import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/admin/admin_navbar.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          // Top Navbar (fixed)
          AdminNavbar(
            onMenuTap: isMobile
                ? () {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                : null,
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Sidebar (desktop only)
                if (!isMobile)
                  AdminSidebar(currentRoute: currentRoute),

                // Content area (scrollable)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF9FAFB), // Light gray background
                    padding: const EdgeInsets.all(24),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Drawer (mobile only)
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(currentRoute: currentRoute),
            )
          : null,
    );
  }
}
