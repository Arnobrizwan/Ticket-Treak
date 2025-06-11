// lib/screens/user/dashboard/home_dashboard.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class HomeDashboard extends StatefulWidget {
  final String userName;
  const HomeDashboard({super.key, required this.userName});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> with TickerProviderStateMixin {
  // Violin color palette matching OnboardingScreen
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange    = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown

  late AnimationController _animationController;
  late Animation<double>   _fadeAnimation;
  late Animation<double>   _slideAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  Map<String, dynamic>? _userData;
  bool                 _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _userData   = doc.data();
            _isLoading  = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize    = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 400;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: DottedPatternPainter(
                color: primaryColor.withOpacity(0.02),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 24 : 16,
                          ),
                          children: [
                            const SizedBox(height: 16),

                            // Animated header
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Transform.translate(
                                    offset: Offset(0, -_slideAnimation.value),
                                    child: _buildStudentHeader(context),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Welcome banner with student focus
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildStudentWelcomeBanner(context),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Quick actions for students
                            _buildSectionHeader("Quick Actions", Icons.flash_on),
                            const SizedBox(height: 12),
                            _buildStudentQuickActions(context),
                            const SizedBox(height: 24),

                            // Active bookings from Firebase
                            _buildSectionHeader("My Trips", Icons.luggage),
                            const SizedBox(height: 12),
                            _buildActiveBookings(),
                            const SizedBox(height: 24),

                            // ─────────────────────────
                            // Saved Flights Section
                            _buildSectionHeader("Saved Flights", Icons.bookmark),
                            const SizedBox(height: 12),
                            _buildSavedFlightsSection(),
                            const SizedBox(height: 24),
                            // ─────────────────────────

                            // Popular student destinations
                            _buildSectionHeader("Trending Destinations", Icons.trending_up),
                            const SizedBox(height: 12),
                            _buildTrendingDestinations(),
                            const SizedBox(height: 24),

                            // Student deals
                            _buildSectionHeader("Student Deals", Icons.local_offer),
                            const SizedBox(height: 12),
                            _buildStudentDeals(),
                            const SizedBox(height: 24),

                            // Recent activity from Firebase
                            _buildSectionHeader("Recent Activity", Icons.history),
                            const SizedBox(height: 12),
                            _buildRecentActivity(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Bottom navigation
                      _buildBottomNavigation(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Loading / Empty / Error States
  // ───────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              color: darkGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: subtleGrey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Header, Welcome Banner, and Section Builders
  // ───────────────────────────────────────────────────────────
  Widget _buildStudentHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo and greeting
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.flight, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${widget.userName.split(' ')[0]}! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'Ready for your next adventure?',
                  style: TextStyle(fontSize: 13, color: darkGrey),
                ),
              ],
            ),
          ],
        ),

        // Notification and profile avatar
        Row(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: subtleGrey),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none, size: 22),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.notifications);
                        },
                        color: textColor,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: _userData?['profileImage'] != null
                        ? CachedNetworkImage(
                            imageUrl: _userData!['profileImage']!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                          )
                        : _buildAvatarPlaceholder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        widget.userName.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStudentWelcomeBanner(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1525130413817-d45c1d127c42?w=800&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              placeholder: (context, url) => Container(
                color: subtleGrey,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(color: subtleGrey),
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🎓 Student Exclusive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Save up to 30% on flights!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your student ID unlocks exclusive deals',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "See All",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.search, 'title': 'Search\nFlights', 'route': AppRoutes.flightSearch},
      {'icon': Icons.discount, 'title': 'Student\nDeals', 'route': AppRoutes.deals},
      {'icon': Icons.group, 'title': 'Group\nBooking', 'route': AppRoutes.groupBooking},
      {'icon': Icons.support_agent, 'title': 'Support\nChat', 'route': AppRoutes.support},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, action['route'] as String);
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(right: index < actions.length - 1 ? 12 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['title'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', whereIn: ['confirmed', 'upcoming'])
          .orderBy('departureDate', descending: false)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateCard(
            'No upcoming trips',
            'Start planning your next adventure!',
            Icons.flight_takeoff,
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(booking);
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final departureDate = (booking['departureDate'] as Timestamp).toDate();
    final isToday = DateFormat('yyyy-MM-dd').format(departureDate) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: accentOrange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentOrange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Center(
                child: Text(
                  '✈️ Flying Today!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['origin'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          booking['originCity'] ?? '',
                          style: TextStyle(fontSize: 12, color: darkGrey),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.flight_takeoff, color: primaryColor, size: 24),
                        Text(
                          booking['flightNumber'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          booking['destination'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          booking['destinationCity'] ?? '',
                          style: TextStyle(fontSize: 12, color: darkGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(departureDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          booking['departureTime'] ?? '',
                          style: TextStyle(fontSize: 12, color: darkGrey),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RM ${booking['price'] ?? '0'}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isToday) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Check-in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Boarding Pass',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingDestinations() {
    final destinations = [
      {
        'city': 'Bangkok',
        'country': 'Thailand',
        'price': 'From RM199',
        'image': 'https://images.unsplash.com/photo-1563492065599-3520f775eeed?w=400&q=80',
        'discount': '25% OFF',
      },
      {
        'city': 'Bali',
        'country': 'Indonesia',
        'price': 'From RM289',
        'image': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&q=80',
        'discount': '30% OFF',
      },
      {
        'city': 'Singapore',
        'country': 'Singapore',
        'price': 'From RM159',
        'image': 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400&q=80',
        'discount': '20% OFF',
      },
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final dest = destinations[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: index < destinations.length - 1 ? 12 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: dest['image'] as String,
                    fit: BoxFit.cover,
                    width: 160,
                    height: 200,
                    placeholder: (context, url) => Container(
                      color: subtleGrey,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(color: subtleGrey),
                  ),
                ),

                // Gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Discount badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dest['discount'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest['city'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dest['country'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dest['price'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentDeals() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('deals')
          .where('type', isEqualTo: 'student')
          .where('active', isEqualTo: true)
          .orderBy('discount', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Show static deals as fallback
          return Column(
            children: [
              _buildDealCard(
                airline: 'AirAsia',
                route: 'KL → Bangkok',
                originalPrice: 'RM399',
                discountedPrice: 'RM279',
                discount: '30%',
                validUntil: DateTime.now().add(const Duration(days: 7)),
              ),
              _buildDealCard(
                airline: 'Malaysia Airlines',
                route: 'KL → Singapore',
                originalPrice: 'RM299',
                discountedPrice: 'RM209',
                discount: '30%',
                validUntil: DateTime.now().add(const Duration(days: 5)),
              ),
            ],
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final deal = doc.data() as Map<String, dynamic>;
            return _buildDealCard(
              airline: deal['airline'] ?? 'Unknown',
              route: deal['route'] ?? '',
              originalPrice: 'RM${deal['originalPrice'] ?? '0'}',
              discountedPrice: 'RM${deal['discountedPrice'] ?? '0'}',
              discount: '${deal['discount'] ?? '0'}%',
              validUntil: (deal['validUntil'] as Timestamp).toDate(),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDealCard({
    required String  airline,
    required String  route,
    required String  originalPrice,
    required String  discountedPrice,
    required String  discount,
    required DateTime validUntil,
  }) {
    final daysLeft = validUntil.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentOrange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                discount,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  airline,
                  style: TextStyle(
                    color: darkGrey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  route,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      originalPrice,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      discountedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (daysLeft <= 3) ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    fontSize: 11,
                    color: (daysLeft <= 3) ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedDate', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateCard(
            'No recent trips',
            'Your completed trips will appear here',
            Icons.history,
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return _buildActivityCard(
              route: '${booking['origin'] ?? 'N/A'} → ${booking['destination'] ?? 'N/A'}',
              date: DateFormat('MMM dd, yyyy').format(
                (booking['completedDate'] as Timestamp).toDate(),
              ),
              airline: booking['airline'] ?? 'Unknown',
              price: 'RM${booking['price'] ?? '0'}',
              savedAmount: booking['savedAmount'] != null
                  ? 'Saved RM${booking['savedAmount']}'
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String route,
    required String date,
    required String airline,
    required String price,
    String? savedAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: subtleGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flight, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      airline,
                      style: TextStyle(fontSize: 12, color: darkGrey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $date',
                      style: TextStyle(fontSize: 12, color: darkGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (savedAmount != null)
                Text(
                  savedAmount,
                  style: TextStyle(
                    fontSize: 12,
                    color: accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: "Home",
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.explore,
                label: "Explore",
                isSelected: false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.explore);
                },
              ),
              _buildNavItem(
                icon: Icons.airplane_ticket,
                label: "My Trips",
                isSelected: false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.myBookings);
                },
              ),
              _buildNavItem(
                icon: Icons.local_offer,
                label: "Deals",
                isSelected: false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.deals);
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: "Profile",
                isSelected: false,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String   label,
    required bool     isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryColor : darkGrey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? primaryColor : darkGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Saved Flights Section (MUST be inside _HomeDashboardState)
  // ───────────────────────────────────────────────────────────
  Widget _buildSavedFlightsSection() {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return _buildEmptyStateCard(
        'Not logged in',
        'Please sign in to see your saved flights',
        Icons.bookmark_border,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('savedFlights')
          .where('userId', isEqualTo: currentUid)
          .orderBy('savedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateCard(
            'No saved flights',
            'Tap on any flight to save it and it will appear here',
            Icons.bookmark_border,
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final savedData = doc.data() as Map<String, dynamic>;
            final offer     = savedData['rawOfferJson'] as Map<String, dynamic>? ?? {};

            // Pull out a few fields safely
            String originCode          = savedData['originCode']       ?? 'N/A';
            String destinationCode     = savedData['destinationCode']  ?? 'N/A';
            String departureDateStr    = savedData['departureDateStr'] ?? '';
            String flightNumber        = 'N/A';
            String airlineCode         = 'N/A';
            String price               = 'N/A';
            String currency            = 'MYR';

            try {
              final priceInfo   = (offer['price'] as Map<String, dynamic>?);
              if (priceInfo != null) {
                price    = priceInfo['total']?.toString()    ?? price;
                currency = priceInfo['currency']?.toString() ?? currency;
              }
              final itineraries = (offer['itineraries'] as List<dynamic>?);
              if (itineraries != null && itineraries.isNotEmpty) {
                final firstItin = itineraries[0] as Map<String, dynamic>;
                final segments  = (firstItin['segments'] as List<dynamic>?);
                if (segments != null && segments.isNotEmpty) {
                  final firstSeg = (segments[0] as Map<String, dynamic>);
                  flightNumber   =
                      "${firstSeg['carrierCode'] ?? 'XX'} ${firstSeg['number'] ?? ''}";
                  airlineCode    = (firstSeg['carrierCode'] ?? 'XX').toString();
                }
              }
            } catch (_) {
              // ignore; fall back to defaults
            }

            // Format departure date
            String departureDateFormatted = departureDateStr.isNotEmpty
                ? DateFormat('MMM dd, yyyy')
                    .format(DateTime.parse(departureDateStr))
                : 'N/A';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Airline logo placeholder / colored box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAirlineColor(airlineCode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        airlineCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Flight info (origin → destination, number, date)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$originCode → $destinationCode",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          flightNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          departureDateFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price + “Details” button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$currency $price",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.flightDetail,
                            arguments: {
                              'offer': offer,
                              'originCode': originCode,
                              'destinationCode': destinationCode,
                              'departureDate': departureDateStr,
                              'adults': savedData['adults'] ?? 1,
                              'travelClass': savedData['travelClass'] ?? '',
                              'direct': savedData['direct'] ?? false,
                              'isStudentFare': savedData['isStudentFare'] ?? false,
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          "Details",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Helper method to pick a background color based on carrier code.
  Color _getAirlineColor(String carrier) {
    final colors = {
      'MH': const Color(0xFF5C2E00), // Malaysia Airlines – Brown
      'AK': const Color(0xFFDC2626), // AirAsia – Red
      'SQ': const Color(0xFF8B5000), // Singapore Airlines – Amber Brown
      'TG': const Color(0xFF7C2D92), // Thai Airways – Purple
      'GA': const Color(0xFFB28F5E), // Garuda – Muted Brown
      'EK': const Color(0xFFB91C1C), // Emirates – Dark Red
    };
    return colors[carrier] ?? primaryColor;
  }
}

// ───────────────────────────────────────────────────────────
// Custom painter for dotted pattern
// ───────────────────────────────────────────────────────────
class DottedPatternPainter extends CustomPainter {
  final Color color;
  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        if ((x + y) % 60 == 0) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}