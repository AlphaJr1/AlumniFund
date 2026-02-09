import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_season_model.dart';
import '../models/brand_idea_model.dart';
import '../services/brand_identity_service.dart';
import 'brand_idea_submit_modal.dart';

class BrandIdentityCard extends StatelessWidget {
  final String? userId;
  
  // Static service instance to prevent stream recreation
  static final _service = BrandIdentityService();

  const BrandIdentityCard({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCardShell(context);
  }

  // Card shell yang persistent (border + background)
  Widget _buildCardShell(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    return Center(
      child: Container(
        width: screenWidth * 0.9,
        height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Animated gradient border (persistent)
            Positioned.fill(
              child: _AnimatedGradientBorder(
                child: Container(),
              ),
            ),
            // Content area (inset by 8px) - StreamBuilder di sini
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white,
                  child: RepaintBoundary(
                    child: _buildContent(context, screenWidth, screenHeight, isMobile),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Content yang di-stream (hanya isi, bukan border/bg)
  Widget _buildContent(BuildContext context, double screenWidth, double screenHeight, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('brand_seasons')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildSimpleLoadingCard();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        try {
          final seasonDoc = snapshot.data!.docs.first;
          final season = BrandSeason.fromFirestore(seasonDoc);
          return _buildSubmitCardContent(context, season, userId, screenWidth, screenHeight, isMobile);
        } catch (e, stackTrace) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  // Renamed dari _buildSubmitCard
  Widget _buildSubmitCardContent(
      BuildContext context, BrandSeason season, String? userId, 
      double screenWidth, double screenHeight, bool isMobile) {
    
    // Jika tidak ada userId, tampilkan input card
    if (userId == null) {
      return _buildInputCardContent(context, season, screenWidth, screenHeight, isMobile);
    }

    // Use static service instance - no recreation
    return RepaintBoundary(
      child: StreamBuilder<BrandIdea?>(
        stream: _service.watchUserIdea(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _buildSimpleLoadingCard();
          }

          final userIdea = snapshot.data;
          
          if (userIdea != null) {
            return _buildThankYouCardContent(
              context, 
              season, 
              userIdea, 
              screenWidth, 
              screenHeight, 
              isMobile
            );
          } else {
            return _buildInputCardContent(context, season, screenWidth, screenHeight, isMobile);
          }
        },
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context, BrandSeason season) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    // Show card immediately while user is loading
    return Center(
      child: Container(
        width: screenWidth * 0.9,
        height: isMobile ? screenHeight * 0.65 : screenHeight * 0.75,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        margin: const EdgeInsets.symmetric(vertical: 40),
        child: Stack(
          children: [
            // Animated gradient border (full size)
            Positioned.fill(
              child: _AnimatedGradientBorder(
                child: Container(),
              ),
            ),
            // White content (inset by 8px)
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: () {
                  // Show login prompt
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text(
                        'Please login with your Google account to submit your brand name idea and participate in the community naming event!',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Maybe Later'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Navigate to login or trigger Google Sign In
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
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          SizedBox(height: isMobile ? 8 : 12),
                          
                          Text(
                            'Community Naming Event',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 26,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            '"UNAME" is just a placeholder.\nHelp us find the perfect name\nfor our community!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          
                          SizedBox(height: isMobile ? 24 : 28),
                          
                          if (season.inputDeadline != null) ...[
                            Text(
                              'We\'re waiting for your contribution!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0891B2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(height: isMobile ? 16 : 20),
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCFFAFE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        color: Color(0xFF0891B2),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatCountdown(season.inputDeadline!),
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0891B2),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          SizedBox(height: isMobile ? 24 : 28),
                          
                          SizedBox(height: isMobile ? 8 : 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Error loading brand season',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildSubmitCard(
      BuildContext context, BrandSeason season, String? userId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 1024;

    // Jika tidak ada userId (tidak teridentifikasi), tetap tampilkan input card
    if (userId == null) {
      return _buildInputCardContent(context, season, screenWidth, screenHeight, isMobile);
    }

    // Use static service instance - no recreation
    return RepaintBoundary(
      child: StreamBuilder<BrandIdea?>(
        stream: _service.watchUserIdea(userId),
        builder: (context, snapshot) {
          // Show loading only on initial wait, not on active updates
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _buildSimpleLoadingCard();
          }

          final userIdea = snapshot.data;
          
          if (userIdea != null) {
            return _buildThankYouCardContent(
              context, 
              season, 
              userIdea, 
              screenWidth, 
              screenHeight, 
              isMobile
            );
          } else {
            return _buildInputCardContent(context, season, screenWidth, screenHeight, isMobile);
          }
        },
      ),
    );
  }

  Widget _buildInputCardContent(
      BuildContext context,
      BrandSeason season, 
      double screenWidth,
      double screenHeight,
      bool isMobile) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BrandIdeaSubmitModal(userId: userId),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isMobile ? 8 : 12),
              
              // Title
              Text(
                'Help Us Choose Our Name!',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                '"UNAME" is just a placeholder.\nWe\'re waiting for your contribution!\nHelp us find the perfect name for our community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 28),
              
              if (season.inputDeadline != null) ...[
                SizedBox(height: isMobile ? 16 : 20),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final primaryColor = Theme.of(context).primaryColor;
                    final lightColor = primaryColor.withOpacity(0.1);
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCountdown(season.inputDeadline!),
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              
              SizedBox(height: isMobile ? 24 : 28),
              SizedBox(height: isMobile ? 20 : 24),
              
              // Hint text
              _PulsingHintText(
                text: 'Tap this card to contribute your idea',
                isMobile: isMobile,
              ),
              
              SizedBox(height: isMobile ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return '$days days ${hours}h ${minutes}m';
  }

  Widget _buildThankYouCardContent(
      BuildContext context,
      BrandSeason season,
      BrandIdea userIdea,
      double screenWidth,
      double screenHeight,
      bool isMobile) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => BrandIdeaSubmitModal(userId: userId),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                        // Thank you icon
                        Icon(
                          Icons.check_circle,
                          size: isMobile ? 64 : 80,
                          color: Colors.green.shade500,
                        ),
                        SizedBox(height: isMobile ? 16 : 20),
                        
                        // Thank you message with name
                        Text(
                          'Thank You, ${userIdea.submittedByName}!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          'Your contribution has been received',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        
                        SizedBox(height: isMobile ? 24 : 32),
                        
                        // Divider
                        Container(
                          width: double.infinity,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade400,
                                Colors.grey.shade200,
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isMobile ? 20 : 24),
                        
                        // Submitted Brand Name
                        Text(
                          'Your Proposed Name:',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          userIdea.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 26 : 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                        
                        SizedBox(height: isMobile ? 20 : 24),
                        
                        // Philosophy
                        Text(
                          'Your Philosophy:',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            userIdea.philosophy,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              color: const Color(0xFF374151),
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isMobile ? 24 : 28),
                        
                        // Info text
                        Text(
                          'You can update your submission anytime before the deadline',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: const Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        if (season.inputDeadline != null) ...[
                          const SizedBox(height: 12),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 1)),
                            builder: (context, snapshot) {
                              final primaryColor = Theme.of(context).primaryColor;
                              final lightColor = primaryColor.withOpacity(0.1);
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: lightColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatCountdown(season.inputDeadline!),
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        
                        SizedBox(height: isMobile ? 16 : 20),
                        
                        // Tap to edit hint
                        _PulsingHintText(
                          text: 'Tap this card to update your submission',
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                ),
              );
  }
}

// Animated Gradient Border Widget
class _AnimatedGradientBorder extends StatefulWidget {
  final Widget child;

  const _AnimatedGradientBorder({
    required this.child,
  });

  @override
  State<_AnimatedGradientBorder> createState() =>
      _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<_AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: SweepGradient(
              colors: const [
                Color(0xFF06B6D4), // Cyan
                Color(0xFF8B5CF6), // Purple
                Color(0xFFEC4899), // Pink
                Color(0xFFF59E0B), // Amber
                Color(0xFF10B981), // Green
                Color(0xFF06B6D4), // Cyan (loop)
              ],
              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Pulsing Hint Text Widget
class _PulsingHintText extends StatefulWidget {
  final String text;
  final bool isMobile;

  const _PulsingHintText({
    required this.text,
    required this.isMobile,
  });

  @override
  State<_PulsingHintText> createState() => _PulsingHintTextState();
}

class _PulsingHintTextState extends State<_PulsingHintText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Visible longer (0.5 to 0.9), fade shorter
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.9),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 0.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.isMobile ? 13 : 14,
          color: const Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
