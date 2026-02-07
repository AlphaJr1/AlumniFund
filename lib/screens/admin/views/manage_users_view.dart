import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firestore_user_service.dart';
import '../../../services/user_storage_service.dart';

/// Admin view untuk manage registered users
class ManageUsersView extends ConsumerStatefulWidget {
  const ManageUsersView({super.key});

  @override
  ConsumerState<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends ConsumerState<ManageUsersView> {
  final _firestoreService = FirestoreUserService();
  List<UserData> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _firestoreService.watchUsers().listen(
      (users) {
        if (mounted) {
          setState(() {
            _users = users;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _users = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteUser(UserData user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteUser(user.userId);
        // Stream will auto-update

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.displayName} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteDevice(UserData user, String fingerprint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove this device from ${user.displayName}?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fingerprint.substring(0, 16) + '...',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.removeDeviceFromUser(user.userId, fingerprint);
        // Stream will auto-update

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  List<UserData> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      return user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.userId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 32, color: Colors.blue),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Users',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'View and manage registered users',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Search bar
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ],
          ),
        ),

        // Stats
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _buildStatCard(
                'Total Users',
                _users.length.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Total Devices',
                _users.fold<int>(0, (sum, user) => sum + user.fingerprints.length).toString(),
                Icons.devices,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Avg Devices/User',
                _users.isEmpty
                    ? '0'
                    : (_users.fold<int>(0, (sum, user) => sum + user.fingerprints.length) / _users.length)
                        .toStringAsFixed(1),
                Icons.analytics,
                Colors.orange,
              ),
            ],
          ),
        ),

        // Users list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No users registered yet'
                : 'No users found matching "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(UserData user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
            ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${user.fingerprints.length} device${user.fingerprints.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Registered: ${_formatDate(user.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User ID
                _buildInfoRow(
                  'User ID',
                  user.userId,
                  Icons.fingerprint,
                  onCopy: () => _copyToClipboard(user.userId, 'User ID'),
                ),
                const Divider(height: 24),

                // Devices
                Row(
                  children: [
                    Icon(Icons.devices, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Devices (${user.devices.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...user.devices.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final device = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(left: 24, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Device ${idx + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.fingerprint.substring(0, 16) + '...',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Added: ${_formatDateTime(device.addedAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => _copyToClipboard(device.fingerprint, 'Fingerprint'),
                          tooltip: 'Copy fingerprint',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                          onPressed: () => _deleteDevice(user, device.fingerprint),
                          tooltip: 'Delete device',
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const Divider(height: 24),

                // Timestamps
                _buildInfoRow(
                  'Created At',
                  _formatDateTime(user.createdAt),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Last Seen',
                  _formatDateTime(user.lastSeen),
                  Icons.access_time,
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(user.userId, 'User ID'),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy ID'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: label == 'User ID' ? 'monospace' : null,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
