enum AddonCategory {
  baggage,
  meals,
  services,
  entertainment,
  insurance,
}

enum AddonType {
  // Baggage
  extraLuggage20kg,
  extraLuggage32kg,
  sportsEquipment,
  
  // Meals
  vegetarianMeal,
  halalMeal,
  kosherMeal,
  diabeticMeal,
  childMeal,
  premiumMeal,
  
  // Services
  priorityBoarding,
  loungeAccess,
  fastTrackSecurity,
  meetAndGreet,
  
  // Entertainment
  wifi,
  entertainment,
  
  // Insurance
  travelInsurance,
  cancellationCover,
}

extension AddonTypeExtension on AddonType {
  String get displayName {
    switch (this) {
      case AddonType.extraLuggage20kg:
        return 'Extra Luggage (20kg)';
      case AddonType.extraLuggage32kg:
        return 'Extra Luggage (32kg)';
      case AddonType.sportsEquipment:
        return 'Sports Equipment';
      case AddonType.vegetarianMeal:
        return 'Vegetarian Meal';
      case AddonType.halalMeal:
        return 'Halal Meal';
      case AddonType.kosherMeal:
        return 'Kosher Meal';
      case AddonType.diabeticMeal:
        return 'Diabetic Meal';
      case AddonType.childMeal:
        return 'Child Meal';
      case AddonType.premiumMeal:
        return 'Premium Meal';
      case AddonType.priorityBoarding:
        return 'Priority Boarding';
      case AddonType.loungeAccess:
        return 'Airport Lounge Access';
      case AddonType.fastTrackSecurity:
        return 'Fast Track Security';
      case AddonType.meetAndGreet:
        return 'Meet & Greet Service';
      case AddonType.wifi:
        return 'In-Flight WiFi';
      case AddonType.entertainment:
        return 'Premium Entertainment';
      case AddonType.travelInsurance:
        return 'Travel Insurance';
      case AddonType.cancellationCover:
        return 'Cancellation Cover';
    }
  }

  String get description {
    switch (this) {
      case AddonType.extraLuggage20kg:
        return 'Additional 20kg checked baggage allowance';
      case AddonType.extraLuggage32kg:
        return 'Additional 32kg checked baggage allowance';
      case AddonType.sportsEquipment:
        return 'Special handling for sports equipment';
      case AddonType.vegetarianMeal:
        return 'Delicious vegetarian meal prepared fresh';
      case AddonType.halalMeal:
        return 'Certified halal meal options';
      case AddonType.kosherMeal:
        return 'Kosher meal prepared according to dietary laws';
      case AddonType.diabeticMeal:
        return 'Low sugar meal suitable for diabetics';
      case AddonType.childMeal:
        return 'Kid-friendly meal with healthy options';
      case AddonType.premiumMeal:
        return 'Chef-curated premium dining experience';
      case AddonType.priorityBoarding:
        return 'Board first and settle in comfortably';
      case AddonType.loungeAccess:
        return 'Relax in premium airport lounges';
      case AddonType.fastTrackSecurity:
        return 'Skip the queues at security checkpoints';
      case AddonType.meetAndGreet:
        return 'Personal assistance through the airport';
      case AddonType.wifi:
        return 'Stay connected throughout your flight';
      case AddonType.entertainment:
        return 'Premium movies, music, and games';
      case AddonType.travelInsurance:
        return 'Comprehensive coverage for your journey';
      case AddonType.cancellationCover:
        return 'Protection against trip cancellations';
    }
  }

  AddonCategory get category {
    switch (this) {
      case AddonType.extraLuggage20kg:
      case AddonType.extraLuggage32kg:
      case AddonType.sportsEquipment:
        return AddonCategory.baggage;
      case AddonType.vegetarianMeal:
      case AddonType.halalMeal:
      case AddonType.kosherMeal:
      case AddonType.diabeticMeal:
      case AddonType.childMeal:
      case AddonType.premiumMeal:
        return AddonCategory.meals;
      case AddonType.priorityBoarding:
      case AddonType.loungeAccess:
      case AddonType.fastTrackSecurity:
      case AddonType.meetAndGreet:
        return AddonCategory.services;
      case AddonType.wifi:
      case AddonType.entertainment:
        return AddonCategory.entertainment;
      case AddonType.travelInsurance:
      case AddonType.cancellationCover:
        return AddonCategory.insurance;
    }
  }

  String get imageUrl {
    switch (this) {
      case AddonType.extraLuggage20kg:
      case AddonType.extraLuggage32kg:
        return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=300&fit=crop';
      case AddonType.sportsEquipment:
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop';
      case AddonType.vegetarianMeal:
        return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop';
      case AddonType.halalMeal:
        return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop';
      case AddonType.kosherMeal:
        return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';
      case AddonType.diabeticMeal:
        return 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop';
      case AddonType.childMeal:
        return 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400&h=300&fit=crop';
      case AddonType.premiumMeal:
        return 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop';
      case AddonType.priorityBoarding:
        return 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=400&h=300&fit=crop';
      case AddonType.loungeAccess:
        return 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop';
      case AddonType.fastTrackSecurity:
        return 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=300&fit=crop';
      case AddonType.meetAndGreet:
        return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop';
      case AddonType.wifi:
        return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop';
      case AddonType.entertainment:
        return 'https://images.unsplash.com/photo-1489599019551-eeb80c2456b0?w=400&h=300&fit=crop';
      case AddonType.travelInsurance:
        return 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=400&h=300&fit=crop';
      case AddonType.cancellationCover:
        return 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400&h=300&fit=crop';
    }
  }
}

class FlightAddon {
  final String id;
  final AddonType type;
  final double price;
  final String currency;
  final bool isPopular;
  final bool isRecommended;
  final List<String> features;
  final Map<String, dynamic> metadata;

  const FlightAddon({
    required this.id,
    required this.type,
    required this.price,
    this.currency = 'MYR',
    this.isPopular = false,
    this.isRecommended = false,
    this.features = const [],
    this.metadata = const {},
  });

  factory FlightAddon.fromJson(Map<String, dynamic> json) {
    return FlightAddon(
      id: json['id'] as String,
      type: AddonType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AddonType.extraLuggage20kg,
      ),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MYR',
      isPopular: json['isPopular'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
      features: List<String>.from(json['features'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'price': price,
      'currency': currency,
      'isPopular': isPopular,
      'isRecommended': isRecommended,
      'features': features,
      'metadata': metadata,
    };
  }

  FlightAddon copyWith({
    String? id,
    AddonType? type,
    double? price,
    String? currency,
    bool? isPopular,
    bool? isRecommended,
    List<String>? features,
    Map<String, dynamic>? metadata,
  }) {
    return FlightAddon(
      id: id ?? this.id,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isPopular: isPopular ?? this.isPopular,
      isRecommended: isRecommended ?? this.isRecommended,
      features: features ?? this.features,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightAddon && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AddonSelection {
  final Map<String, FlightAddon> selectedAddons;
  final double totalPrice;
  final String currency;

  const AddonSelection({
    this.selectedAddons = const {},
    this.totalPrice = 0.0,
    this.currency = 'MYR',
  });

  AddonSelection addAddon(FlightAddon addon) {
    final newSelection = Map<String, FlightAddon>.from(selectedAddons);
    newSelection[addon.id] = addon;
    
    final newTotal = newSelection.values.fold<double>(
      0.0,
      (sum, addon) => sum + addon.price,
    );

    return AddonSelection(
      selectedAddons: newSelection,
      totalPrice: newTotal,
      currency: currency,
    );
  }

  AddonSelection removeAddon(String addonId) {
    final newSelection = Map<String, FlightAddon>.from(selectedAddons);
    newSelection.remove(addonId);
    
    final newTotal = newSelection.values.fold<double>(
      0.0,
      (sum, addon) => sum + addon.price,
    );

    return AddonSelection(
      selectedAddons: newSelection,
      totalPrice: newTotal,
      currency: currency,
    );
  }

  bool hasAddon(String addonId) => selectedAddons.containsKey(addonId);

  List<FlightAddon> get addons => selectedAddons.values.toList();

  int get count => selectedAddons.length;

  bool get isEmpty => selectedAddons.isEmpty;

  bool get isNotEmpty => selectedAddons.isNotEmpty;
}