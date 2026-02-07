import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_identification_provider.dart';
import '../widgets/user_name_input_modal.dart';

/// Testing page untuk user identification system
class UserIdentificationTestPage extends ConsumerStatefulWidget {
  const UserIdentificationTestPage({super.key});

  @override
  ConsumerState<UserIdentificationTestPage> createState() =>
      _UserIdentificationTestPageState();
}

class _UserIdentificationTestPageState
    extends ConsumerState<UserIdentificationTestPage> {
  int _mockUsersCount = 0;

  @override
  void initState() {
    super.initState();
    print('🔍 [TestPage] initState called');
    // Provider will auto-initialize
  }

  Future<void> _updateMockUsersCount() async {
    final count =
        await ref.read(userIdentificationProvider.notifier).getMockUsersCount();
    setState(() => _mockUsersCount = count);
  }

  Future<void> _showNameInputModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UserNameInputModal(),
    );
    await _updateMockUsersCount();
  }

  Future<void> _clearLocalData() async {
    await ref.read(userIdentificationProvider.notifier).clearUser();
    await _updateMockUsersCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared')),
      );
    }
  }

  Future<void> _clearAllMockUsers() async {
    await ref.read(userIdentificationProvider.notifier).clearAllMockUsers();
    await _updateMockUsersCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All mock users cleared')),
      );
    }
  }

  Future<void> _reinitialize() async {
    await ref.read(userIdentificationProvider.notifier).reinitialize();
    await _updateMockUsersCount();
  }

  Future<void> _resetAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will delete:\n'
          '• All users from Firestore\n'
          '• All local storage data\n'
          '• All mock database\n\n'
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Resetting all data...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      final notifier = ref.read(userIdentificationProvider.notifier);
      
      print('🔥 [Reset] Clearing Firestore...');
      await notifier.clearAllFirestoreUsers();
      
      print('🔥 [Reset] Clearing Mock...');
      await notifier.clearAllMockUsers();
      
      print('🔥 [Reset] Clearing Local Storage...');
      await notifier.clearUser();
      
      print('🔥 [Reset] Force reinitialize...');
      await notifier.reinitialize();
      
      await _updateMockUsersCount();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All data reset successfully - Please refresh other browsers'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ [Reset] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userIdentificationProvider);

    print('🔍 [TestPage] Build called - needsNameInput: ${state.needsNameInput}, isLoading: ${state.isLoading}, isIdentified: ${state.isIdentified}');

    // Auto-show modal jika perlu input nama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 [TestPage] PostFrameCallback - needsNameInput: ${state.needsNameInput}, isLoading: ${state.isLoading}');
      if (state.needsNameInput && !state.isLoading) {
        print('🚨 [TestPage] SHOWING MODAL');
        _showNameInputModal();
      } else {
        print('⏭️ [TestPage] Modal NOT shown');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Identification Test'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(state),
            const SizedBox(height: 24),

            // User Info Card
            if (state.isIdentified) ...[
              _buildUserInfoCard(state),
              const SizedBox(height: 24),
            ],

            // Testing Controls
            _buildTestingControls(),
            const SizedBox(height: 24),

            // Mock Database Info
            _buildMockDatabaseInfo(),
            const SizedBox(height: 16),

            // Quick link to registered users page
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/registered-users'),
                icon: const Icon(Icons.list),
                label: const Text('View All Registered Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(UserIdentificationState state) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (state.isLoading) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Loading...';
    } else if (state.isIdentified) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Identified';
    } else if (state.needsNameInput) {
      statusColor = Colors.blue;
      statusIcon = Icons.person_add;
      statusText = 'Needs Name Input';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'Not Initialized';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(UserIdentificationState state) {
    final user = state.userData!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Display Name', user.displayName),
            _buildInfoRow('User ID', user.userId),
            _buildInfoRow('Devices', '${user.fingerprints.length} device(s)'),
            _buildInfoRow(
              'Primary Fingerprint',
              '${user.primaryFingerprint.substring(0, 16)}...',
            ),
            _buildInfoRow(
              'Created At',
              _formatDateTime(user.createdAt),
            ),
            _buildInfoRow(
              'Last Seen',
              _formatDateTime(user.lastSeen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Testing Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildControlButton(
              'Show Name Input Modal',
              Icons.edit,
              Colors.blue,
              _showNameInputModal,
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              'Clear Local Data',
              Icons.delete_outline,
              Colors.orange,
              _clearLocalData,
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              'Re-initialize',
              Icons.refresh,
              Colors.green,
              _reinitialize,
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              'Clear All Mock Users',
              Icons.delete_forever,
              Colors.red,
              _clearAllMockUsers,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildControlButton(
              '🔥 RESET ALL DATA (Firestore + Local)',
              Icons.warning_rounded,
              Colors.red.shade900,
              _resetAllData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockDatabaseInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Mock Database',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Total Mock Users', '$_mockUsersCount'),
            const SizedBox(height: 12),
            Text(
              'Note: Mock users simulate Firestore database. In production, this will be real Firebase data.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
