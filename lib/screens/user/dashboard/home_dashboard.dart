import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class HomeDashboard extends StatelessWidget {
  final String userName;

  const HomeDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Professional color palette
    const backgroundColor = Color(0xFFF5F7FA);
    const primaryColor = Color(0xFF3F3D9A);
    const secondaryColor = Color(0xFF6C63FF);
    const textColor = Color(0xFF2D3142);
    const subtleGrey = Color(0xFFEBEEF2);
    const darkGrey = Color(0xFF8F96A3);

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),
                  
                  // Professional header with company logo and user avatar
                  _buildEnterpriseHeader(userName, textColor, primaryColor),
                  const SizedBox(height: 24),
                  
                  // Flight status indicator - Enterprise focus
                  _buildFlightStatusCard(context),
                  const SizedBox(height: 24),
                  
                  // Trip management section - Business oriented
                  _buildSectionHeader("Trip Management"),
                  const SizedBox(height: 12),
                  _buildTripManagementGrid(context),
                  const SizedBox(height: 24),
                  
                  // Next trip summary - Key enterprise feature
                  _buildSectionHeader("Next Business Trip"),
                  const SizedBox(height: 12),
                  _buildBusinessTripCard(context),
                  const SizedBox(height: 24),
                  
                  // Recent travel activity - Clean, enterprise style
                  _buildSectionHeader("Recent Activity"),
                  const SizedBox(height: 12),
                  _buildEnterpriseActivityCard(
                    route: "KUL > BKK",
                    date: "Apr 25, 2025",
                    status: "Completed",
                    flightNumber: "MH 784",
                    isCompliant: true,
                  ),
                  _buildEnterpriseActivityCard(
                    route: "LHR > DXB",
                    date: "Apr 10, 2025",
                    status: "Completed",
                    flightNumber: "BA 106",
                    isCompliant: true,
                  ),
                  _buildEnterpriseActivityCard(
                    route: "JFK > LAX",
                    date: "Mar 29, 2025",
                    status: "Completed",
                    flightNumber: "AA 223",
                    isCompliant: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Travel policy compliance - Enterprise feature
                  _buildTravelPolicyCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Professional bottom navigation bar
            _buildBottomNavigation(context, primaryColor),
          ],
        ),
      ),
    );
  }

  // Enterprise-style header with company logo and user info
  Widget _buildEnterpriseHeader(String userName, Color textColor, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Company logo and brand
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flight,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "TicketTrek",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F3D9A),
              ),
            ),
          ],
        ),
        
        // User profile and notifications
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, size: 22),
                onPressed: () {},
                color: textColor,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor,
                    child: Text(
                      userName.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Flight status card with real-time information
  Widget _buildFlightStatusCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF3F3D9A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flight_takeoff,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Next Flight",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "On time",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "SIN",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Singapore",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Text(
                          "10:30 AM",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 1,
                                color: Colors.grey.shade300,
                              ),
                              const Icon(
                                Icons.flight,
                                size: 24,
                                color: Color(0xFF3F3D9A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "SQ 231 · 5h 20m",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "HKG",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Hong Kong",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Text(
                          "3:50 PM",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F3D9A),
                          side: const BorderSide(color: Color(0xFF3F3D9A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Check In"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F3D9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "View Boarding Pass",
                          style: TextStyle(color: Colors.white),
                        ),
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

  // Professional section header
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3F3D9A),
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "See All",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Trip management grid for enterprise functions
  Widget _buildTripManagementGrid(BuildContext context) {
    // Check screen width to adjust layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;
    
    // For narrow screens, use a 2x2 grid instead of a row
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: (screenWidth - 52) / 2, // Adjust for padding and spacing
            child: _buildEnterpriseFeatureCard(
              icon: Icons.search,
              title: "Book Flight",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.searchFlight);
              },
            ),
          ),
          SizedBox(
            width: (screenWidth - 52) / 2,
            child: _buildEnterpriseFeatureCard(
              icon: Icons.book_online,
              title: "My Bookings",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.myBookings);
              },
            ),
          ),
          SizedBox(
            width: (screenWidth - 52) / 2,
            child: _buildEnterpriseFeatureCard(
              icon: Icons.receipt_long,
              title: "Expenses",
              onTap: () {},
            ),
          ),
          SizedBox(
            width: (screenWidth - 52) / 2,
            child: _buildEnterpriseFeatureCard(
              icon: Icons.support_agent,
              title: "Support",
              onTap: () {},
            ),
          ),
        ],
      );
    }
    
    // Default layout for wider screens
    return Row(
      children: [
        Expanded(
          child: _buildEnterpriseFeatureCard(
            icon: Icons.search,
            title: "Book Flight",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.searchFlight);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnterpriseFeatureCard(
            icon: Icons.book_online,
            title: "My Bookings",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.myBookings);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnterpriseFeatureCard(
            icon: Icons.receipt_long,
            title: "Expenses",
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnterpriseFeatureCard(
            icon: Icons.support_agent,
            title: "Support",
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // Enterprise feature card
  Widget _buildEnterpriseFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF3F3D9A),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Business trip card - Professional design
  Widget _buildBusinessTripCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF3F3D9A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Annual Business Summit",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tokyo, Japan · May 20-25, 2025",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F9EF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Policy Compliant",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "5 days left",
                        style: TextStyle(
                          color: Color(0xFF3F3D9A),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTripDetailRow(
                  label: "Outbound",
                  value: "SQ 982 · May 20, 10:30 AM",
                  icon: Icons.flight_takeoff,
                ),
                const SizedBox(height: 12),
                _buildTripDetailRow(
                  label: "Return",
                  value: "SQ 983 · May 25, 8:45 PM",
                  icon: Icons.flight_land,
                ),
                const SizedBox(height: 12),
                _buildTripDetailRow(
                  label: "Hotel",
                  value: "Grand Hyatt Tokyo",
                  icon: Icons.hotel,
                ),
                const SizedBox(height: 12),
                _buildTripDetailRow(
                  label: "Transportation",
                  value: "Airport Shuttle Arranged",
                  icon: Icons.directions_car,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3F3D9A),
                          side: const BorderSide(color: Color(0xFF3F3D9A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Modify Trip"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F3D9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(color: Colors.white),
                        ),
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

  // Trip detail row
  Widget _buildTripDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF8F96A3),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8F96A3),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Enterprise activity card
  Widget _buildEnterpriseActivityCard({
    required String route,
    required String date,
    required String status,
    required String flightNumber,
    required bool isCompliant,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECECFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flight,
                color: Color(0xFF3F3D9A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        route,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        flightNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8F96A3),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EEFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF2F80ED),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isCompliant ? "Policy Compliant" : "Policy Exception",
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompliant ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Travel policy card - Enterprise specific
  Widget _buildTravelPolicyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.policy,
                    color: Color(0xFF3F3D9A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Travel Policy Compliance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      "Q2 2025 Summary",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8F96A3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComplianceMetric(
                    label: "Flight Compliance",
                    value: "92%",
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildComplianceMetric(
                    label: "Hotel Compliance",
                    value: "87%",
                    color: const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildComplianceMetric(
                    label: "Lead Time",
                    value: "15.2d",
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3F3D9A),
                side: const BorderSide(color: Color(0xFF3F3D9A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("View Full Policy Report"),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compliance metric for travel policy
  Widget _buildComplianceMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8F96A3),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Professional bottom navigation
  Widget _buildBottomNavigation(BuildContext context, Color primaryColor) {
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
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.flight,
                label: "Trips",
                isSelected: false,
                onTap: () {},
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.receipt_long,
                label: "Expenses",
                isSelected: false,
                onTap: () {},
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.notifications,
                label: "Alerts",
                isSelected: false,
                onTap: () {},
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: "Profile",
                isSelected: false,
                onTap: () {},
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation item for bottom bar
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFF8F96A3),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primaryColor : const Color(0xFF8F96A3),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}