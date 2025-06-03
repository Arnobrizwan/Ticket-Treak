import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Added for Random()
import 'package:ticket_trek/routes/app_routes.dart'; // adjust as needed

// --- "Violin" color palette ---
const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
const Color textColor = Color(0xFF35281E); // Deep Wood
const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
const Color accentColor = Color(0xFFD4A373); // Warm Highlight
const Color errorColor = Color(0xFFEF4444); // Red for errors

// --- Data model for each passenger ---
class PassengerData {
  final int passengerNumber;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passportNumberController =
      TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String nationality = 'Malaysia'; // Default nationality
  DateTime? dateOfBirth;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  PassengerData(this.passengerNumber);

  bool isValid() {
    // Ensure formKey.currentState is not null before calling validate
    return formKey.currentState?.validate() ?? false;
  }

  /// For passing to payment screen or other non-Firestore uses
  Map<String, dynamic> toMap() {
    return {
      'passengerNumber': passengerNumber,
      'fullName': fullNameController.text.trim(),
      'passportNumber': passportNumberController.text.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(), // Store as ISO string
      'nationality': nationality,
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
    };
  }

  /// For storing to Firestore "bookings" collection
  Map<String, dynamic> toFirestoreMap() {
    int? age;
    if (dateOfBirth != null) {
      final now = DateTime.now();
      age = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        age--;
      }
    }

    return {
      'fullName': fullNameController.text.trim(),
      'passportNumber': passportNumberController.text.trim(),
      'dateOfBirth': dateOfBirth, // Firestore handles DateTime objects directly
      'nationality': nationality,
      'contactEmail': emailController.text.trim(),
      'contactPhone': phoneController.text.trim(),
      'age': age,
      'isPrimaryPassenger': passengerNumber == 1,
      // 'createdAt' will be added at the booking level with FieldValue.serverTimestamp()
    };
  }

  /// Billing details for the payment screen
  Map<String, dynamic> getBillingDetails() {
    return {
      'name': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'nationality': nationality,
      'isPrimaryPassenger': passengerNumber == 1,
    };
  }

  void dispose() {
    fullNameController.dispose();
    passportNumberController.dispose();
    dobController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}

// --- Each passenger's form card ---
class PassengerFormCard extends StatefulWidget {
  final PassengerData passenger;
  final VoidCallback onDateSelect;
  final VoidCallback onNationalitySelect;

  const PassengerFormCard({
    Key? key,
    required this.passenger,
    required this.onDateSelect,
    required this.onNationalitySelect,
  }) : super(key: key);

  @override
  State<PassengerFormCard> createState() => _PassengerFormCardState();
}

class _PassengerFormCardState extends State<PassengerFormCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: widget.passenger.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon + text
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline, // Using outline version
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger ${widget.passenger.passengerNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.passenger.passengerNumber == 1
                              ? 'Primary passenger • Details for billing'
                              : 'Additional passenger',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.passenger.passengerNumber == 1
                                ? accentColor
                                : darkGrey,
                            fontWeight: widget.passenger.passengerNumber == 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildTextField(
                controller: widget.passenger.fullNameController,
                label: 'Full Name (as per passport)',
                icon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                autofocus: widget.passenger.passengerNumber ==
                    1, // Autofocus for first passenger only
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().split(' ').length < 2) {
                    return 'Please enter both first and last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Passport Number
              _buildTextField(
                controller: widget.passenger.passportNumberController,
                label: 'Passport Number',
                icon: Icons.article_outlined, // Changed icon
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter passport number';
                  }
                  final cleanPassport = value.replaceAll(' ', '').toUpperCase();
                  if (cleanPassport.length < 6 || cleanPassport.length > 20) {
                    // Adjusted length
                    return 'Passport number is invalid (6-20 chars)';
                  }
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanPassport)) {
                    return 'Use only A-Z and 0-9';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date of Birth + Nationality
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align validators properly
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildDateField(
                      controller: widget.passenger.dobController,
                      label: 'Date of Birth',
                      onTap: widget.onDateSelect,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select date';
                        }
                        if (widget.passenger.dateOfBirth != null) {
                          final age = DateTime.now().year -
                              widget.passenger.dateOfBirth!.year;
                          // A more precise age calculation for validation
                          DateTime today = DateTime.now();
                          DateTime dob = widget.passenger.dateOfBirth!;
                          int preciseAge = today.year - dob.year;
                          if (today.month < dob.month ||
                              (today.month == dob.month &&
                                  today.day < dob.day)) {
                            preciseAge--;
                          }

                          if (preciseAge < 0 || preciseAge > 120) {
                            return 'Invalid age';
                          }
                          // Example: if there's a minimum age for booking
                          // if (preciseAge < 16 && widget.passenger.passengerNumber == 1) {
                          //   return 'Primary must be 16+';
                          // }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildNationalityField(
                      // This is not a TextFormField, so no direct validator here
                      nationality: widget.passenger.nationality,
                      onTap: widget.onNationalitySelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact Email
              _buildTextField(
                controller: widget.passenger.emailController,
                label: widget.passenger.passengerNumber == 1
                    ? 'Contact Email (for billing & confirmation)'
                    : 'Contact Email (Optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    if (widget.passenger.passengerNumber == 1) {
                      // Required for primary passenger
                      return 'Please enter email';
                    }
                    return null; // Optional for others
                  }
                  if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Contact Phone
              _buildTextField(
                controller: widget.passenger.phoneController,
                label: widget.passenger.passengerNumber == 1
                    ? 'Contact Phone (for updates)'
                    : 'Contact Phone (Optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    if (widget.passenger.passengerNumber == 1) {
                      // Required for primary passenger
                      return 'Please enter phone number';
                    }
                    return null; // Optional for others
                  }
                  final cleanPhone =
                      value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (cleanPhone.length < 8 || cleanPhone.length > 15) {
                    return 'Enter a valid phone (8-15 digits)';
                  }
                  return null;
                },
              ),

              // Info banner for primary passenger
              if (widget.passenger.passengerNumber == 1) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'The primary passenger\'s contact details will be used for booking confirmation and payment billing.',
                          style: TextStyle(
                              fontSize: 13, color: textColor, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization =
        TextCapitalization.none, // Default to none, specify for names
    bool autofocus = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization == TextCapitalization.words &&
              label.toLowerCase().contains("name")
          ? TextCapitalization.words
          : textCapitalization, // Capitalize words for name fields
      textInputAction: textInputAction,
      validator: validator,
      autofocus: autofocus,
      maxLength: maxLength,
      style: const TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darkGrey, size: 20),
        labelStyle:
            const TextStyle(color: darkGrey, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        filled: true,
        fillColor:
            backgroundColor.withOpacity(0.7), // Slightly transparent background
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: "", // Hide max length counter if not desired
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      // Wrap with GestureDetector for better tap area
      controller: controller,
      readOnly: true,
      onTap: onTap, // Call onTap when the field itself is tapped
      validator: validator,
      style: const TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined,
            color: darkGrey, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
            color: darkGrey, size: 24),
        labelStyle:
            const TextStyle(color: darkGrey, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        filled: true,
        fillColor: backgroundColor.withOpacity(0.7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildNationalityField({
    required String nationality,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14), // Consistent padding
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: darkGrey, size: 20),
            const SizedBox(width: 12), // Increased spacing
            Expanded(
              child: Text(
                nationality.isEmpty
                    ? "Select Nationality"
                    : nationality, // Placeholder if empty
                style: TextStyle(
                    fontSize: 16,
                    color: nationality.isEmpty ? darkGrey : textColor,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded,
                color: darkGrey, size: 24),
          ],
        ),
      ),
    );
  }
}

// --- Bottom sheet to pick nationality ---
class NationalityPicker extends StatefulWidget {
  final String selectedNationality;
  final Function(String) onSelected;

  const NationalityPicker({
    Key? key,
    required this.selectedNationality,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<NationalityPicker> createState() => _NationalityPickerState();
}

class _NationalityPickerState extends State<NationalityPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];

  // A more comprehensive list of countries (example, can be expanded or fetched)
  final List<String> _countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo, Democratic Republic of the',
    'Congo, Republic of the',
    'Costa Rica',
    "Cote d'Ivoire",
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea, North',
    'Korea, South',
    'Kosovo',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine State',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredCountries = _countries);
    } else {
      setState(() {
        _filteredCountries =
            _countries.where((c) => c.toLowerCase().contains(query)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Increased height
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle and Title
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Select Nationality',
              style: TextStyle(
                fontSize: 20, // Slightly larger
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                  color: textColor, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: TextStyle(
                    color: darkGrey.withOpacity(0.7),
                    fontWeight: FontWeight.normal),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: darkGrey, size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: subtleGrey.withOpacity(0.8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: subtleGrey.withOpacity(0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // List of Countries
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(
                    child: Text("No countries match your search.",
                        style: TextStyle(color: darkGrey, fontSize: 16)))
                : ListView.builder(
                    itemCount: _filteredCountries.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (ctx, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country == widget.selectedNationality;
                      return ListTile(
                        tileColor:
                            isSelected ? accentColor.withOpacity(0.15) : null,
                        title: Text(
                          country,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? primaryColor : textColor,
                            fontSize: 16,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: primaryColor, size: 22)
                            : null,
                        onTap: () {
                          widget.onSelected(country);
                          Navigator.pop(context);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4), // Adjusted padding
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Main Screen Widget ---
class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  List<PassengerData> _passengers = [];
  int _currentPassengerIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _bookingData; // Data passed from previous screen
  final PageController _pageController = PageController();

  bool _isInitialSetupDone = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserProfile(); // Load profile, autofill will be attempted if passengers are initialized
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialSetupDone) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      int passengerCount = 1; // Default

      if (args != null) {
        _bookingData = args; // Store all passed arguments
        // Expecting 'adults' to determine initial passenger count
        passengerCount = (args['adults'] as int?) ?? 1;
      }

      _initializePassengers(count: passengerCount);

      if (_userProfile != null && _passengers.isNotEmpty) {
        _autofillFirstPassenger();
      }
      _isInitialSetupDone = true;
    }
  }

  void _setupAnimations() {
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);

    _slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero) // Slide from bottom
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0) // Subtle scale
        .animate(CurvedAnimation(
            parent: _scaleController, curve: Curves.easeOutBack));

    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  void _initializePassengers({int count = 1}) {
    final int validCount = count > 0 ? count : 1;
    if (_passengers.length == validCount && _passengers.isNotEmpty)
      return; // Avoid re-init if count is same

    _passengers =
        List.generate(validCount, (index) => PassengerData(index + 1));
    _currentPassengerIndex = 0; // Always start with the first passenger form

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          setState(() {
            _userProfile = doc.data();
          });
          if (_passengers.isNotEmpty) {
            // Autofill only if passengers list is ready
            _autofillFirstPassenger();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) _showErrorMessage('Could not load your profile.');
    }
  }

  void _autofillFirstPassenger() {
    if (_userProfile != null && _passengers.isNotEmpty) {
      final firstPassenger = _passengers[0];
      firstPassenger.fullNameController.text =
          (_userProfile!['fullName'] ?? '').toString();
      firstPassenger.emailController.text =
          (_userProfile!['email'] ?? '').toString();
      firstPassenger.phoneController.text =
          (_userProfile!['phone'] ?? '').toString();

      final nationalityFromProfile = _userProfile!['nationality'];
      if (nationalityFromProfile != null &&
          nationalityFromProfile.toString().isNotEmpty) {
        firstPassenger.nationality = nationalityFromProfile.toString();
      }
      // Note: Date of Birth autofill would require parsing if stored as a string in profile.
      // Assuming it's not part of the standard user profile for now or is handled if available.

      if (mounted) {
        setState(() {}); // Update UI with autofilled data
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    for (var p in _passengers) {
      p.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentPassenger() {
    if (_currentPassengerIndex < 0 ||
        _currentPassengerIndex >= _passengers.length) return false;
    return _passengers[_currentPassengerIndex].isValid();
  }

  bool _validateAllPassengers() {
    if (_passengers.isEmpty) return false;
    for (var passenger in _passengers) {
      if (!passenger.isValid()) return false;
    }
    return true;
  }

  void _nextPassenger() {
    FocusScope.of(context).unfocus();

    if (_currentPassengerIndex < _passengers.length - 1) {
      if (_validateCurrentPassenger()) {
        if (mounted) {
          setState(() {
            _currentPassengerIndex++;
          });
        }
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400), // Smoother transition
          curve: Curves.easeInOutCubic,
        );
      } else {
        _showValidationError(formSpecific: true);
      }
    } else {
      // Last passenger: validate and save all
      if (_validateAllPassengers()) {
        // Validate all before attempting to save
        _saveAllPassengers();
      } else {
        _showValidationError(
            formSpecific: false); // General error if any form is invalid
      }
    }
  }

  void _previousPassenger() {
    FocusScope.of(context).unfocus();
    if (_currentPassengerIndex > 0) {
      if (mounted) {
        setState(() {
          _currentPassengerIndex--;
        });
      }
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showValidationError({bool formSpecific = true}) {
    if (!mounted) return;
    String message = formSpecific
        ? 'Please correct errors in the current form.'
        : 'Please ensure all passenger details are filled correctly.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(
            16, 8, 16, 70), // Adjust margin to avoid bottom nav
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, int passengerIndex) async {
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          passengerIndex < 0 ||
          passengerIndex >= _passengers.length) return;

      final passenger = _passengers[passengerIndex];
      final now = DateTime.now();
      final lastValidDate = DateTime(now.year, now.month, now.day); // Today
      final firstValidDate = DateTime(1900);
      final initialDate = passenger.dateOfBirth ??
          DateTime(
              now.year - 25, now.month, now.day); // Default to 25 years ago

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate.isAfter(lastValidDate) ||
                initialDate.isBefore(firstValidDate)
            ? lastValidDate
            : initialDate,
        firstDate: firstValidDate,
        lastDate: lastValidDate,
        helpText: 'SELECT DATE OF BIRTH',
        errorFormatText: 'Enter a valid date',
        errorInvalidText: 'Date out of range',
        fieldHintText: 'DD/MM/YYYY',
        fieldLabelText: 'Birth Date',
        builder: (ctx, child) {
          return Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white, // Text on primary color button
                surface: backgroundColor,
                onSurface: textColor, // Main text color in dialog
                secondary: accentColor,
                onSecondary: Colors.white,
              ),
              dialogBackgroundColor: backgroundColor,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    foregroundColor:
                        primaryColor, // OK/Cancel button text color
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          passenger.dateOfBirth = picked;
          passenger.dobController.text =
              DateFormat('dd/MM/yyyy').format(picked);
        });
        // Trigger validation for the date field if it's part of a Form
        passenger.formKey.currentState?.validate();
      }
    });
  }

  void _showNationalityPicker(int passengerIndex) {
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          passengerIndex < 0 ||
          passengerIndex >= _passengers.length) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => NationalityPicker(
          selectedNationality: _passengers[passengerIndex].nationality,
          onSelected: (nationality) {
            if (mounted) {
              setState(() {
                _passengers[passengerIndex].nationality = nationality;
              });
              // No direct form validation needed for nationality picker itself,
              // but if it affects other fields, you might trigger validation.
            }
          },
        ),
      );
    });
  }

  Future<void> _saveAllPassengers() async {
    FocusScope.of(context).unfocus();
    if (!_validateAllPassengers()) {
      _showValidationError(formSpecific: false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('User not authenticated. Please sign in.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final primaryPassengerData =
          _passengers.isNotEmpty ? _passengers[0] : null;

      final bookingPayload = <String, dynamic>{
        'userId': user.uid,
        'bookingId': _generateBookingId(),
        'passengers': _passengers.map((p) => p.toFirestoreMap()).toList(),
        'flightDetails': _bookingData ?? <String, dynamic>{},
        'status': 'pending_payment',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'primaryPassengerBilling': primaryPassengerData?.getBillingDetails(),
        'passengerCount': _passengers.length,
        // Include other relevant data from _bookingData if needed at top level
        'totalPrice':
            _bookingData?['price'] ?? 0.0, // Example: if price is passed
        'currency': _bookingData?['currency'] ?? 'MYR', // Example
      };

      final docRef =
          await _firestore.collection('bookings').add(bookingPayload);
      _showSuccessMessage();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      final paymentArgs = {
        ...(_bookingData ??
            <String, dynamic>{}), // Pass all original flight details
        'bookingId': docRef.id,
        'bookingRef': bookingPayload['bookingId'], // The generated one
        // Pass simplified passenger list or just count if full details not needed on payment screen
        'passengersSummary': _passengers
            .map((p) => {'name': p.fullNameController.text, 'type': 'Adult'})
            .toList(),
        'totalAmount': bookingPayload[
            'totalPrice'], // Ensure this is correctly calculated/passed
        'currency': bookingPayload['currency'],
      };

      Navigator.pushNamed(context, AppRoutes.payment, arguments: paymentArgs);
    } catch (e, s) {
      debugPrint('Error saving passenger details: $e\nStacktrace: $s');
      _showErrorMessage('Failed to save details. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  final _random = Random();
  String _generateBookingId() {
    final epochPart = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(7); // Last 6 digits
    final String randomChars = String.fromCharCodes(List.generate(
        3, (_) => _random.nextInt(26) + 65)); // 3 random uppercase letters
    return 'TT$epochPart$randomChars';
  }

  void _showSuccessMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Slightly larger
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Details Saved! Proceeding to payment...',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600], // More explicit success color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 70),
        duration: const Duration(milliseconds: 2000), // Longer duration
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 70),
        duration: const Duration(seconds: 4), // Longer for errors
      ),
    );
  }

  void _addPassenger() {
    FocusScope.of(context).unfocus();
    // Example: Limit number of passengers
    if (_passengers.length >= 5) {
      _showErrorMessage("Maximum of 5 passengers allowed.");
      return;
    }
    if (mounted) {
      setState(() {
        _passengers.add(PassengerData(_passengers.length + 1));
        _currentPassengerIndex = _passengers.length - 1; // Go to new passenger
        _pageController.animateToPage(
          _currentPassengerIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(), // Header is not animated in this version for simplicity
              _buildProgressIndicator(),
              Expanded(
                child: FadeTransition(
                  // Fade content area
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    // Slide content area
                    position: _slideAnimation,
                    child: _buildPassengerForm(),
                  ),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isLastPassengerPage = _passengers.isNotEmpty &&
        _currentPassengerIndex == _passengers.length - 1;
    final bool canAddMorePassengers =
        _passengers.length < 5; // Max 5 passengers

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: darkGrey, size: 22),
            onPressed: () => Navigator.pop(context),
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Passenger Details',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                if (_passengers.isNotEmpty)
                  Text(
                    'Step ${_currentPassengerIndex + 1} of ${_passengers.length}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: darkGrey,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (isLastPassengerPage && canAddMorePassengers)
            TextButton.icon(
              onPressed: _addPassenger,
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: primaryColor, size: 20),
              label: const Text('Add',
                  style: TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: primaryColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_passengers.isEmpty) return const SizedBox.shrink();
    double progressValue = (_currentPassengerIndex + 1) / _passengers.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), // Adjusted padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger ${_currentPassengerIndex + 1}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor),
              ),
              Text(
                '${(progressValue * 100).round()}% Complete',
                style: const TextStyle(
                    fontSize: 13, color: darkGrey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: subtleGrey.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 7, // Slightly thinner
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForm() {
    if (_passengers.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        if (mounted) {
          setState(() {
            _currentPassengerIndex = index;
          });
          _scaleController
              .reset(); // Reset and forward animation for current page
          _scaleController.forward();
        }
      },
      itemCount: _passengers.length,
      itemBuilder: (context, index) {
        if (index < 0 || index >= _passengers.length)
          return const SizedBox.shrink();
        return ScaleTransition(
          // Apply scale animation per page
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            key: ValueKey(
                'passenger_scroll_$index'), // Ensure scroll position is maintained
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: PassengerFormCard(
              key: ValueKey('passenger_form_$index'), // Key for FormCard state
              passenger: _passengers[index],
              onDateSelect: () => _selectDate(context, index),
              onNationalitySelect: () => _showNationalityPicker(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    if (_passengers.isEmpty) return const SizedBox.shrink();
    final bool isLastPassenger =
        _currentPassengerIndex == _passengers.length - 1;

    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          if (_currentPassengerIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _previousPassenger,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const Spacer(), // Pushes next button to the right if no "Previous"

          if (_currentPassengerIndex > 0) const SizedBox(width: 12),

          Expanded(
            flex: _currentPassengerIndex > 0
                ? 2
                : 3, // Give more space if it's the only button
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextPassenger,
              icon: _isLoading
                  ? Container()
                  : Icon(
                      isLastPassenger
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 18),
              label: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5),
                    )
                  : Text(isLastPassenger ? 'Confirm & Pay' : 'Next Passenger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                shadowColor: primaryColor.withOpacity(0.3),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
