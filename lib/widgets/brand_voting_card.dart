import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_idea_model.dart';
import '../models/brand_season_model.dart';
import '../models/brand_vote_model.dart';
import '../providers/brand_vote_provider.dart';
import '../providers/brand_identity_provider.dart';
import '../services/brand_vote_service.dart';

// ===========================================================
// VOTING CARD (public-facing)
// ===========================================================

class BrandVotingCard extends StatelessWidget {
  final String? userId;
  final String? userName;

  const BrandVotingCard({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Positioned.fill(
              child: _VoteGradientBorder(child: Container()),
            ),
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white,
                  child: _buildContent(context, isMobile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    // Baca season aktif untuk votingDeadline
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('brand_seasons')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, seasonSnap) {
        BrandSeason? season;
        if (seasonSnap.hasData && seasonSnap.data!.docs.isNotEmpty) {
          try {
            season = BrandSeason.fromFirestore(seasonSnap.data!.docs.first);
          } catch (_) {}
        }

        final now = DateTime.now();
        final votingClosed = season?.votingDeadline != null &&
            now.isAfter(season!.votingDeadline!);

        return Consumer(builder: (context, ref, _) {
          // Voting sudah tutup → tampilkan pemenang
          if (votingClosed) {
            final allVotesAsync = ref.watch(allVotesProvider);
            return allVotesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (votes) =>
                  _buildWinnerCard(context, votes, isMobile),
            );
          }

          // Voting masih terbuka
          final ideasAsync = ref.watch(allIdeasProvider);
          return ideasAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox.shrink(),
            data: (ideas) {
              if (ideas.isEmpty) return const SizedBox.shrink();

              if (userId != null) {
                final userVoteAsync =
                    ref.watch(userVoteProvider(userId!));
                return userVoteAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildVotePromptContent(
                      context, ideas, season, isMobile),
                  data: (userVote) {
                    if (userVote != null) {
                      final allVotesAsync = ref.watch(allVotesProvider);
                      return allVotesAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (allVotes) => _buildResultContent(
                            context, allVotes, userVote, season,
                            isMobile),
                      );
                    } else {
                      return _buildVotePromptContent(
                          context, ideas, season, isMobile);
                    }
                  },
                );
              } else {
                return _buildVotePromptContent(
                    context, ideas, season, isMobile);
              }
            },
          );
        });
      },
    );
  }

  // ---- BELUM VOTE: tampilan tanda tanya + CTA ----
  Widget _buildVotePromptContent(
      BuildContext context, List<BrandIdea> ideas,
      BrandSeason? season, bool isMobile) {
    return GestureDetector(
      onTap: () {
        if (userId == null) {
          _showLoginRequired(context);
          return;
        }
        showDialog(
          context: context,
          builder: (_) => BrandVoteModal(
            userId: userId!,
            userName: userName ?? 'Guest',
            ideas: ideas,
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedQuestionMark(isMobile: isMobile),
              SizedBox(height: isMobile ? 20 : 28),

              Text(
                'Vote for the Best Name!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'The community has submitted their ideas.\nNow it\'s time to pick your favorite!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Countdown deadline
              if (season?.votingDeadline != null)
                _CountdownBadge(
                    deadline: season!.votingDeadline!,
                    isMobile: isMobile),

              SizedBox(height: isMobile ? 20 : 28),

              // CTA Button
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF7C3AED).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.how_to_vote_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      userId == null ? 'Login to Vote' : 'Cast Your Vote',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              _PulsingTapHint(
                text: 'Tap anywhere on this card to vote',
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- SUDAH VOTE: tampilkan pie chart realtime ----
  Widget _buildResultContent(
    BuildContext context,
    List<BrandVote> allVotes,
    BrandVote userVote,
    BrandSeason? season,
    bool isMobile,
  ) {
    final results = computeVoteResults(allVotes);
    final total = allVotes.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade500,
                  size: isMobile ? 22 : 26),
              const SizedBox(width: 8),
              Text(
                'Your vote has been recorded!',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You voted for: ${userVote.votedForTitle}',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: const Color(0xFF64748B),
            ),
          ),

          // Countdown
          if (season?.votingDeadline != null) ...[
            const SizedBox(height: 8),
            _CountdownBadge(
                deadline: season!.votingDeadline!, isMobile: isMobile),
          ],

          SizedBox(height: isMobile ? 12 : 16),

          // Pie chart
          SizedBox(
            width: isMobile ? 180 : 220,
            height: isMobile ? 180 : 220,
            child: results.isEmpty
                ? const CircularProgressIndicator()
                : CustomPaint(
                    painter: _PieChartPainter(results: results),
                  ),
          ),

          SizedBox(height: isMobile ? 16 : 20),

          // Legend + persentase
          Text(
            'Live Results  •  $total vote${total != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          ...results.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            final color = _pieColors[idx % _pieColors.length];
            final isMyVote = r.ideaId == userVote.votedForIdeaId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMyVote
                    ? color.withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: isMyVote
                    ? Border.all(color: color, width: 1.5)
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.title,
                      style: TextStyle(
                        fontWeight: isMyVote
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: isMobile ? 13 : 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    '${r.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 13 : 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${r.count})',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  if (isMyVote) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.how_to_vote_rounded,
                        size: 14, color: color),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login with your Google account to cast your vote!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please use the login button in the app bar'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// VOTE MODAL
// ===========================================================

class BrandVoteModal extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final List<BrandIdea> ideas;

  const BrandVoteModal({
    super.key,
    required this.userId,
    required this.userName,
    required this.ideas,
  });

  @override
  ConsumerState<BrandVoteModal> createState() => _BrandVoteModalState();
}

class _BrandVoteModalState extends ConsumerState<BrandVoteModal> {
  String? _selectedIdeaId;
  String? _selectedTitle;
  bool _isSubmitting = false;

  Future<void> _handleVote() async {
    if (_selectedIdeaId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(brandVoteServiceProvider);
      await service.submitVote(
        userId: widget.userId,
        votedForIdeaId: _selectedIdeaId!,
        votedForTitle: _selectedTitle!,
        voterName: widget.userName,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Your vote has been submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cast Your Vote',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Choose one name — you can\'t change it later',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // List pilihan
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shrinkWrap: true,
                itemCount: widget.ideas.length,
                itemBuilder: (context, index) {
                  final idea = widget.ideas[index];
                  final isSelected = _selectedIdeaId == idea.userId;

                  return _VoteIdeaItem(
                    idea: idea,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedIdeaId = idea.userId;
                        _selectedTitle = idea.title;
                      });
                    },
                  );
                },
              ),
            ),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedIdeaId == null || _isSubmitting)
                              ? null
                              : _handleVote,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Vote',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
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
}

// ===========================================================
// VOTE IDEA ITEM (expandable philosophy)
// ===========================================================

class _VoteIdeaItem extends StatefulWidget {
  final BrandIdea idea;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoteIdeaItem({
    required this.idea,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VoteIdeaItem> createState() => _VoteIdeaItemState();
}

class _VoteIdeaItemState extends State<_VoteIdeaItem> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final color = const Color(0xFF7C3AED);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.white,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.idea.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                // Expand/collapse icon
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            // Philosophy: muncul penuh saat dipilih
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10, left: 36),
                child: Text(
                  widget.idea.philosophy,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState: isSelected
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// WINNER CARD (setelah voting deadline)
// ===========================================================

extension on BrandVotingCard {
  Widget _buildWinnerCard(
      BuildContext context, List<BrandVote> votes, bool isMobile) {
    final results = computeVoteResults(votes);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'Voting has ended.\nNo votes were cast.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: isMobile ? 16 : 18, color: const Color(0xFF64748B)),
        ),
      );
    }

    final winner = results.first;
    final total = votes.length;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 24 : 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            _PulsingTrophyIcon(isMobile: isMobile),
            SizedBox(height: isMobile ? 16 : 20),

            Text(
              '🎉 Voting Has Ended!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The community has spoken.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),

            // Winner name
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 16 : 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'CONGRATULATIONS',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 30 : 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${winner.percentage.toStringAsFixed(1)}% of votes  •  ${winner.count} out of $total',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 16 : 20),

            // Runner-ups
            if (results.length > 1) ...[
              Text(
                'Other Results',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...results.skip(1).take(3).toList().asMap().entries.map((e) {
                final r = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '#${e.key + 2}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.title,
                          style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${r.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// PULSING TROPHY
// ===========================================================

class _PulsingTrophyIcon extends StatefulWidget {
  final bool isMobile;
  const _PulsingTrophyIcon({required this.isMobile});

  @override
  State<_PulsingTrophyIcon> createState() => _PulsingTrophyIconState();
}

class _PulsingTrophyIconState extends State<_PulsingTrophyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.9, end: 1.05)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.scale(
        scale: _anim.value,
        child: Icon(
          Icons.emoji_events_rounded,
          size: widget.isMobile ? 72 : 90,
          color: const Color(0xFFF59E0B),
        ),
      ),
    );
  }
}

// ===========================================================
// COUNTDOWN BADGE
// ===========================================================

class _CountdownBadge extends StatelessWidget {
  final DateTime deadline;
  final bool isMobile;

  const _CountdownBadge(
      {required this.deadline, required this.isMobile});

  String _fmt() {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Voting closed';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m left';
    if (h > 0) return '${h}h ${m}m ${s}s left';
    return '${m}m ${s}s left';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (_, __) {
        final text = _fmt();
        final isUrgent =
            deadline.difference(DateTime.now()).inHours < 1;
        final color =
            isUrgent ? const Color(0xFFEF4444) : const Color(0xFF7C3AED);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================
// PIE CHART PAINTER
// ===========================================================

const List<Color> _pieColors = [
  Color(0xFF7C3AED),
  Color(0xFF06B6D4),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFFEF4444),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
];

class _PieChartPainter extends CustomPainter {
  final List<VoteResult> results;

  _PieChartPainter({required this.results});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < results.length; i++) {
      final sweepAngle = (results[i].percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = _pieColors[i % _pieColors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Gap kecil antar segmen
      final gapPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, sweepAngle, true, gapPaint);

      startAngle += sweepAngle;
    }

    // Lingkaran putih di tengah (donut effect)
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);

    // Total votes di tengah
    final total = results.fold(0, (sum, r) => sum + r.count);
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$total\n',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              height: 1.1,
            ),
          ),
          const TextSpan(
            text: 'votes',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: radius * 1.1);
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.results != results;
}

// ===========================================================
// ANIMATED QUESTION MARK
// ===========================================================

class _AnimatedQuestionMark extends StatefulWidget {
  final bool isMobile;
  const _AnimatedQuestionMark({required this.isMobile});

  @override
  State<_AnimatedQuestionMark> createState() => _AnimatedQuestionMarkState();
}

class _AnimatedQuestionMarkState extends State<_AnimatedQuestionMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isMobile ? 80.0 : 100.0;
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, __) => Transform.scale(
        scale: _scaleAnim.value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// GRADIENT BORDER (distinct from BrandIdentityCard's)
// ===========================================================

class _VoteGradientBorder extends StatefulWidget {
  final Widget child;
  const _VoteGradientBorder({required this.child});

  @override
  State<_VoteGradientBorder> createState() => _VoteGradientBorderState();
}

class _VoteGradientBorderState extends State<_VoteGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: SweepGradient(
            colors: const [
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFF06B6D4),
              Color(0xFF10B981),
              Color(0xFF7C3AED),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            transform: GradientRotation(_ctrl.value * 2 * math.pi),
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ===========================================================
// PULSING TAP HINT
// ===========================================================

class _PulsingTapHint extends StatefulWidget {
  final String text;
  final bool isMobile;
  const _PulsingTapHint({required this.text, required this.isMobile});

  @override
  State<_PulsingTapHint> createState() => _PulsingTapHintState();
}

class _PulsingTapHintState extends State<_PulsingTapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.85)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded,
                size: widget.isMobile ? 14 : 15,
                color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.isMobile ? 12 : 13,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
