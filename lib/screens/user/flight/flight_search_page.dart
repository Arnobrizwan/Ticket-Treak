import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  // Professional color palette (same as HomeDashboard)
  final backgroundColor = const Color(0xFFF5F7FA);
  final primaryColor = const Color(0xFF3F3D9A);
  final secondaryColor = const Color(0xFF6C63FF);
  final textColor = const Color(0xFF2D3142);
  final subtleGrey = const Color(0xFFEBEEF2);
  final darkGrey = const Color(0xFF8F96A3);

  // Form data
  final _formKey = GlobalKey<FormState>();
  String? _departureCity;
  String? _arrivalCity;
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _adultPassengers = 1;
  int _childPassengers = 0;
  String _selectedClass = 'Economy';
  bool _isRoundTrip = true;

  final List<String> _popularAirports = [
    'Singapore (SIN)',
    'Kuala Lumpur (KUL)',
    'Hong Kong (HKG)',
    'Bangkok (BKK)',
    'Tokyo (NRT)',
    'Sydney (SYD)',
    'London (LHR)',
    'New York (JFK)',
    'Dubai (DXB)',
    'Los Angeles (LAX)',
  ];

  final List<String> _travelClasses = [
    'Economy',
    'Premium Economy',
    'Business',
    'First Class',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Header section
              _buildSectionHeader("Flight Search"),
              const SizedBox(height: 24),
              
              // Trip type selector
              _buildTripTypeSelector(),
              const SizedBox(height: 24),
              
              // Location pickers
              _buildLocationPickers(),
              const SizedBox(height: 24),
              
              // Date pickers
              _buildDateSelectors(),
              const SizedBox(height: 24),
              
              // Passenger and class selector
              _buildPassengerClassSelector(),
              const SizedBox(height: 32),
              
              // Search button
              _buildSearchButton(),
              const SizedBox(height: 32),
              
              // Recent searches
              _buildSectionHeader("Recent Searches"),
              const SizedBox(height: 16),
              _buildRecentSearchItem(
                departure: "Singapore (SIN)",
                arrival: "Hong Kong (HKG)",
                date: "Jun 15, 2025",
                passengers: "1 Adult, Business",
              ),
              _buildRecentSearchItem(
                departure: "Kuala Lumpur (KUL)",
                arrival: "Bangkok (BKK)",
                date: "May 28, 2025",
                passengers: "2 Adults, Economy",
              ),
              _buildRecentSearchItem(
                departure: "London (LHR)",
                arrival: "Dubai (DXB)",
                date: "May 10, 2025",
                passengers: "1 Adult, 1 Child, Premium Economy",
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.flight_takeoff,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Find Flights",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list, color: textColor),
          onPressed: () {
            // Open filters
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        if (title == "Recent Searches")
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Clear All",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTripTypeSelector() {
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
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildTripTypeButton(
                "Round Trip",
                _isRoundTrip,
                () => setState(() => _isRoundTrip = true),
              ),
            ),
            Expanded(
              child: _buildTripTypeButton(
                "One Way",
                !_isRoundTrip,
                () => setState(() => _isRoundTrip = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : darkGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPickers() {
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
          children: [
            _buildLocationField(
              label: "From",
              hint: "Departure City or Airport",
              icon: Icons.flight_takeoff,
              value: _departureCity,
              onTap: () => _showAirportSelector(true),
            ),
            const SizedBox(height: 8),
            Divider(color: subtleGrey),
            const SizedBox(height: 8),
            _buildLocationField(
              label: "To",
              hint: "Arrival City or Airport",
              icon: Icons.flight_land,
              value: _arrivalCity,
              onTap: () => _showAirportSelector(false),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _swapLocations,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECECFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.swap_vert,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    color: value != null ? textColor : darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectors() {
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
          children: [
            _buildDateField(
              label: "Departure Date",
              hint: "Select date",
              icon: Icons.calendar_today,
              value: _departureDate,
              onTap: () => _selectDate(true),
            ),
            if (_isRoundTrip) ...[
              const SizedBox(height: 8),
              Divider(color: subtleGrey),
              const SizedBox(height: 8),
              _buildDateField(
                label: "Return Date",
                hint: "Select date",
                icon: Icons.calendar_today,
                value: _returnDate,
                onTap: () => _selectDate(false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    String displayText = hint;
    if (value != null) {
      displayText = DateFormat('MMM d, yyyy').format(value);
    }

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    color: value != null ? textColor : darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerClassSelector() {
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
        child: InkWell(
          onTap: _showPassengerClassSelector,
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Passengers & Class",
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPassengerInfo(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _searchFlights,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 20, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "Search Flights",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem({
    required String departure,
    required String arrival,
    required String date,
    required String passengers,
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
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
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
                child: Icon(
                  Icons.history,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          departure,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: darkGrey,
                          ),
                        ),
                        Text(
                          arrival,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$date · $passengers",
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.replay,
                  color: primaryColor,
                  size: 20,
                ),
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Helper methods ======
  
  void _showAirportSelector(bool isDeparture) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDeparture ? "Select Departure" : "Select Destination",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search airports",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: subtleGrey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Popular Airports",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _popularAirports.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_popularAirports[index]),
                      leading: Icon(
                        isDeparture ? Icons.flight_takeoff : Icons.flight_land,
                        color: primaryColor,
                      ),
                      onTap: () {
                        setState(() {
                          if (isDeparture) {
                            _departureCity = _popularAirports[index];
                          } else {
                            _arrivalCity = _popularAirports[index];
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _swapLocations() {
    setState(() {
      final temp = _departureCity;
      _departureCity = _arrivalCity;
      _arrivalCity = temp;
    });
  }

  Future<void> _selectDate(bool isDeparture) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isDeparture
        ? _departureDate ?? now
        : _returnDate ?? (_departureDate != null ? _departureDate!.add(const Duration(days: 7)) : now.add(const Duration(days: 7)));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          // If return date is before the new departure date, update it
          if (_isRoundTrip && _returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 7));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _showPassengerClassSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Passengers & Class",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Adults
                  _buildPassengerCounter(
                    label: "Adults (12+ years)",
                    value: _adultPassengers,
                    onMinus: () {
                      if (_adultPassengers > 1) {
                        setModalState(() => _adultPassengers--);
                      }
                    },
                    onPlus: () {
                      if (_adultPassengers < 9) {
                        setModalState(() => _adultPassengers++);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Children
                  _buildPassengerCounter(
                    label: "Children (2-11 years)",
                    value: _childPassengers,
                    onMinus: () {
                      if (_childPassengers > 0) {
                        setModalState(() => _childPassengers--);
                      }
                    },
                    onPlus: () {
                      if (_childPassengers < 9) {
                        setModalState(() => _childPassengers++);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Travel class
                  Text(
                    "Travel Class",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _travelClasses.length,
                    (index) => RadioListTile<String>(
                      title: Text(_travelClasses[index]),
                      value: _travelClasses[index],
                      groupValue: _selectedClass,
                      onChanged: (value) {
                        setModalState(() {
                          _selectedClass = value!;
                        });
                      },
                      activeColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Updates are already applied to state
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Apply",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassengerCounter({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: onMinus,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: subtleGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove,
                  size: 18,
                  color: value > (label.contains("Adults") ? 1 : 0) ? textColor : darkGrey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            InkWell(
              onTap: onPlus,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: value < 9 ? primaryColor : darkGrey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPassengerInfo() {
    final StringBuffer buffer = StringBuffer();
    
    // Adults
    buffer.write('$_adultPassengers ${_adultPassengers == 1 ? 'Adult' : 'Adults'}');
    
    // Children
    if (_childPassengers > 0) {
      buffer.write(', $_childPassengers ${_childPassengers == 1 ? 'Child' : 'Children'}');
    }
    
    // Class
    buffer.write(' · $_selectedClass');
    
    return buffer.toString();
  }

  void _searchFlights() {
    // Validate form
    if (_departureCity == null || _arrivalCity == null || _departureDate == null || (_isRoundTrip && _returnDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    
    // Here you would navigate to flight results page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Searching for flights...'),
        backgroundColor: primaryColor,
      ),
    );
    
    // Example of showing a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Searching for flights...",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
    
    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      // Navigate to results page (you'd implement this)
    });
  }
}