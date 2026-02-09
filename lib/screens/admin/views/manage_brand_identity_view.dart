import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/brand_idea_model.dart';
import '../../../models/brand_season_model.dart';
import '../../../providers/brand_identity_provider.dart';
import '../../../services/brand_identity_service.dart';

class ManageBrandIdentityView extends ConsumerStatefulWidget {
  const ManageBrandIdentityView({super.key});

  @override
  ConsumerState<ManageBrandIdentityView> createState() =>
      _ManageBrandIdentityViewState();
}

class _ManageBrandIdentityViewState
    extends ConsumerState<ManageBrandIdentityView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSetDeadlineDialog(BrandSeason currentSeason) async {
    DateTime selectedDate = currentSeason.inputDeadline ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Input Deadline'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('d MMMM yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final service = ref.read(brandIdentityServiceProvider);
                  await service.setInputDeadline(selectedDate);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Deadline set successfully'),
                        backgroundColor: Colors.green,
                      ),
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
              },
              child: const Text('Set Deadline'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeInputPhase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Input Phase'),
        content: const Text(
          'Are you sure you want to close the input phase? Users will no longer be able to submit or edit their ideas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close Phase'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(brandIdentityServiceProvider);
        await service.closeInputPhase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Input phase closed successfully'),
              backgroundColor: Colors.green,
            ),
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

  Future<void> _createNewSeason() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    TimeOfDay selectedTime = const TimeOfDay(hour: 23, minute: 59);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Brand Season'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will create a new brand identity season where users can submit their naming ideas.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Input Deadline'),
                subtitle: Text(DateFormat('d MMMM yyyy, HH:mm').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Create Season'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(brandIdentityServiceProvider);
        await service.createNewSeason(selectedDate);
        if (mounted) {
          ref.invalidate(currentSeasonProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Brand season created successfully!'),
              backgroundColor: Colors.green,
            ),
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

  Future<void> _deleteIdea(BrandIdea idea) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Idea'),
        content: Text(
          'Are you sure you want to delete "${idea.title}" by ${idea.submittedByName}?',
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

    if (confirm == true) {
      try {
        final service = ref.read(brandIdentityServiceProvider);
        await service.deleteIdea(idea.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Idea deleted successfully'),
              backgroundColor: Colors.green,
            ),
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

  void _showIdeaDetail(BrandIdea idea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(idea.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Philosophy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(idea.philosophy),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Submitted by: ${idea.submittedByName}'),
              Text('Date: ${DateFormat('d MMM yyyy').format(idea.createdAt)}'),
              if (idea.updatedAt != null)
                Text(
                    'Last edited: ${DateFormat('d MMM yyyy').format(idea.updatedAt!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteIdea(idea);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final ideasAsync = ref.watch(allIdeasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Brand Identity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentSeasonProvider);
              ref.invalidate(allIdeasProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Season Control Panel
          seasonAsync.when(
            data: (season) => _buildSeasonControl(season),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Active Brand Season',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new season to start accepting brand name ideas from the community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _createNewSeason,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Create New Season'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Ideas List
          Expanded(
            child: ideasAsync.when(
              data: (ideas) {
                final filteredIdeas = ideas.where((idea) {
                  if (_searchQuery.isEmpty) return true;
                  return idea.title.toLowerCase().contains(_searchQuery) ||
                      idea.submittedByName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredIdeas.isEmpty) {
                  return const Center(
                    child: Text('No ideas submitted yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIdeas.length,
                  itemBuilder: (context, index) {
                    final idea = filteredIdeas[index];
                    return _buildIdeaCard(idea);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonControl(BrandSeason season) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: season.isInputOpen ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: season.isInputOpen ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                season.isInputOpen ? Icons.check_circle : Icons.lock,
                color: season.isInputOpen ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Season Status: ${season.isInputOpen ? "OPEN" : "CLOSED"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (season.inputDeadline != null) ...[
            const SizedBox(height: 8),
            Text(
              'Deadline: ${DateFormat('d MMMM yyyy, HH:mm').format(season.inputDeadline!)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (season.isInputOpen) ...[
                ElevatedButton.icon(
                  onPressed: () => _showSetDeadlineDialog(season),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Set Deadline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _closeInputPhase,
                  icon: const Icon(Icons.lock),
                  label: const Text('Close Phase'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _showSetDeadlineDialog(season),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Reopen Phase'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaCard(BrandIdea idea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            idea.title.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          idea.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              idea.philosophy.length > 100
                  ? '${idea.philosophy.substring(0, 100)}...'
                  : idea.philosophy,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${idea.submittedByName} • ${DateFormat('d MMM yyyy').format(idea.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _showIdeaDetail(idea),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteIdea(idea),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
