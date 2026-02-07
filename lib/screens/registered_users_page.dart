import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_storage_service.dart';
import '../services/firestore_user_service.dart';

/// Page untuk melihat semua registered users
class RegisteredUsersPage extends ConsumerStatefulWidget {
  const RegisteredUsersPage({super.key});

  @override
  ConsumerState<RegisteredUsersPage> createState() =>
      _RegisteredUsersPageState();
}

class _RegisteredUsersPageState extends ConsumerState<RegisteredUsersPage> {
  final _firestoreService = FirestoreUserService();
  List<UserData> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Load from Firestore
      final users = await _firestoreService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading users: $e');
      setState(() {
        _users = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(UserData user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus "${user.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firestore
        await _firestoreService.deleteUser(user.userId);
        
        // Reload users
        await _loadUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.displayName} dihapus')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Users'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? _buildEmptyState()
              : _buildUserList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada user terdaftar',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Total: ${_users.length} user${_users.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),

        // User list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return _buildUserCard(user, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserData user, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          child: Text(
            '$number',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Registered: ${_formatDateTime(user.createdAt)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'User ID',
                  user.userId,
                  Icons.fingerprint,
                  onTap: () => _copyToClipboard(user.userId, 'User ID'),
                ),
                const Divider(height: 24),
                
                // Multiple fingerprints
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.devices, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Devices (${user.fingerprints.length})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...user.fingerprints.asMap().entries.map((entry) {
                              final index = entry.key;
                              final fp = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: InkWell(
                                  onTap: () => _copyToClipboard(fp, 'Fingerprint ${index + 1}'),
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
                                          'Device ${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${fp.substring(0, 16)}...',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                
                _buildDetailRow(
                  'Created At',
                  _formatDateTimeFull(user.createdAt),
                  Icons.calendar_today,
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  'Last Seen',
                  _formatDateTimeFull(user.lastSeen),
                  Icons.access_time,
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(
                        user.primaryFingerprint,
                        'Primary Fingerprint',
                      ),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Primary FP'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _deleteUser(user),
                      icon: const Icon(Icons.delete),
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

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDateTimeFull(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
