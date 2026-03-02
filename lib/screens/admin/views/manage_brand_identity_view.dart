import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/brand_idea_model.dart';
import '../../../models/brand_season_model.dart';
import '../../../models/brand_vote_model.dart';
import '../../../providers/brand_identity_provider.dart';
import '../../../providers/brand_vote_provider.dart';
import '../../../services/brand_identity_service.dart';
import '../../../services/brand_vote_service.dart';

class ManageBrandIdentityView extends ConsumerStatefulWidget {
  const ManageBrandIdentityView({super.key});

  @override
  ConsumerState<ManageBrandIdentityView> createState() =>
      _ManageBrandIdentityViewState();
}

class _ManageBrandIdentityViewState
    extends ConsumerState<ManageBrandIdentityView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showSetDeadlineDialog(BrandSeason currentSeason) async {
    final now = DateTime.now();
    // Jika deadline sudah lewat, gunakan 7 hari ke depan sebagai default
    DateTime selectedDate = (currentSeason.inputDeadline != null &&
            currentSeason.inputDeadline!.isAfter(now))
        ? currentSeason.inputDeadline!
        : now.add(const Duration(days: 7));
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

  Future<void> _deleteVote(BrandVote vote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Vote'),
        content: Text(
          'Remove vote from "${vote.voterName}"?\nThey will be able to vote again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(brandVoteServiceProvider);
        await service.deleteVote(vote.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vote from ${vote.voterName} removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final allVotesAsync = ref.watch(allVotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Brand Identity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentSeasonProvider);
              ref.invalidate(allIdeasProvider);
              ref.invalidate(allVotesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Submissions'),
            Tab(icon: Icon(Icons.how_to_vote), text: 'Voting Results'),
          ],
        ),
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
                  const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'No Active Brand Season',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ---- TAB 1: Submissions ----
                Column(
                  children: [
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                    Expanded(
                      child: ideasAsync.when(
                        data: (ideas) {
                          final filtered = ideas.where((idea) {
                            if (_searchQuery.isEmpty) return true;
                            return idea.title.toLowerCase().contains(_searchQuery) ||
                                idea.submittedByName.toLowerCase().contains(_searchQuery);
                          }).toList();
                          if (filtered.isEmpty) {
                            return const Center(child: Text('No ideas submitted yet'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildIdeaCard(filtered[index]),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ],
                ),

                // ---- TAB 2: Voting Results ----
                allVotesAsync.when(
                  data: (votes) => _buildVotingResultsTab(votes),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
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

  Widget _buildVotingResultsTab(List<BrandVote> votes) {
    final results = computeVoteResults(votes);
    final total = votes.length;

    if (votes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No votes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Votes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // Per-kandidat card
        ...results.asMap().entries.map((entry) {
          final idx = entry.key;
          final result = entry.value;
          final colors = [
            const Color(0xFF7C3AED),
            const Color(0xFF06B6D4),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
            const Color(0xFFEC4899),
            const Color(0xFFEF4444),
          ];
          final color = colors[idx % colors.length];

          // voter list: pisah per votes yang memilih ini
          final votersForThis = votes
              .where((v) => v.votedForIdeaId == result.ideaId)
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(
                  '#${idx + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              title: Text(
                result.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: result.percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.percentage.toStringAsFixed(1)}% — ${result.count} vote${result.count != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Voters:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ...votersForThis.map(
                  (v) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.voterName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(v.votedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          tooltip: 'Remove vote (user can re-vote)',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteVote(v),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
          );
        }),
      ],
    );
  }
}
