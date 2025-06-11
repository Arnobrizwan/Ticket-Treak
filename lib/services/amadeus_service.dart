// lib/services/amadeus_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Replace these with your real Amadeus test/live credentials.
const String _amadeusClientId     = 'HdrxjwkMggMOlUf5qk4J3zTkmzWxNaAD';
const String _amadeusClientSecret = '16BZleHCAGFL8cSF';

class AmadeusService {
  static const String _oauthEndpoint           =
      'https://test.api.amadeus.com/v1/security/oauth2/token';
  static const String _flightOffersEndpoint    =
      'https://test.api.amadeus.com/v2/shopping/flight-offers';
  static const String _hotelOffersEndpoint     =
      'https://test.api.amadeus.com/v3/shopping/hotel-offers';
  static const String _hotelReferenceEndpoint  =
      'https://test.api.amadeus.com/v3/reference-data/locations/hotels';
  static const String _airportTransferEndpoint =
      'https://test.api.amadeus.com/v1/shopping/airport-transfers';

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Step 1: Obtain (and cache) a short‐lived bearer token from Amadeus.
  Future<void> _authenticate() async {
    // If we already have a valid token, do nothing.
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_oauthEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type':    'client_credentials',
              'client_id':     _amadeusClientId,
              'client_secret': _amadeusClientSecret,
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        _accessToken = body['access_token'] as String?;
        final expiresIn = body['expires_in'] as int? ?? 1800;
        // Subtract a small buffer (60 seconds) so we don’t accidentally go right to expiry.
        _tokenExpiry =
            DateTime.now().add(Duration(seconds: expiresIn - 60));

        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ✅ Auth succeeded; expires in $expiresIn seconds.');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ❌ Auth failed (${response.statusCode}): ${response.body}');
        }
        throw Exception('Authentication failed (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AmadeusService] ❌ Auth error: $e');
      }
      rethrow;
    }
  }

  /// 2) Search Flights (v2). Returns `{ "data": [ … ], "dictionaries": { "carriers": { … }}}`.
  Future<Map<String, dynamic>> searchFlights({
    required String originCode,      // e.g. "KUL"
    required String destinationCode, // e.g. "PEN"
    required String departureDate,   // format "YYYY-MM-DD"
    bool direct = false,
    int adults = 1,
    String travelClass = 'ECONOMY',
    String currencyCode = 'MYR',
    int maxResults = 10,
  }) async {
    await _authenticate();
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    final queryParams = {
      'originLocationCode':      originCode.toUpperCase(),
      'destinationLocationCode': destinationCode.toUpperCase(),
      'departureDate':           departureDate,
      'adults':                  adults.toString(),
      'travelClass':             travelClass.toUpperCase(),
      'nonStop':                 direct ? 'true' : 'false',
      'currencyCode':            currencyCode.toUpperCase(),
      'max':                     maxResults.toString(),
    };

    final uri =
        Uri.parse(_flightOffersEndpoint).replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[AmadeusService] 🛫 Searching flights → $uri');
    }

    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type':  'application/json',
          },
        )
        .timeout(const Duration(seconds: 45));

    if (kDebugMode) {
      debugPrint(
          '[AmadeusService] Flight search HTTP ${response.statusCode}: ${response.body}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
      final Map<String, dynamic> dictionaries =
          body['dictionaries'] as Map<String, dynamic>? ?? {};

      if (kDebugMode) {
        debugPrint('[AmadeusService] ✅ Found ${data.length} flight offers');
      }

      // Return both the raw offers array and the “carriers” dictionary.
      return {
        'data': data,
        'dictionaries': dictionaries,
      };
    }

    if (response.statusCode == 400) {
      final Map<String, dynamic> errorJson = json.decode(response.body);
      final String detail =
          (errorJson['errors']?[0]?['detail']) ?? 'Invalid flight search params';
      if (kDebugMode) {
        debugPrint('[AmadeusService] Flight search (400): $detail');
      }
      throw Exception('Flight search (400): $detail');
    }

    if (response.statusCode == 401) {
      // Token might have expired; retry once.
      _accessToken = null;
      return await searchFlights(
        originCode: originCode,
        destinationCode: destinationCode,
        departureDate: departureDate,
        direct: direct,
        adults: adults,
        travelClass: travelClass,
        currencyCode: currencyCode,
        maxResults: maxResults,
      );
    }

    throw Exception('Flight search failed (HTTP ${response.statusCode})');
  }

  /// 3a) Step 1 of hotel search: look up hotel IDs by cityCode
  Future<List<String>> _lookupHotelIdsByCity({
    required String cityCode,
    String? brandCode,      // optional filter
    int maxHotels = 10,     // limit how many IDs we fetch
  }) async {
    await _authenticate();
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    // Build query parameters
    final queryParams = {
      'cityCode': cityCode.toUpperCase(),
      'page[limit]': maxHotels.toString(),
      if (brandCode != null) 'brandCodes': brandCode.toUpperCase(),
    };

    final uri = Uri.parse(_hotelReferenceEndpoint)
        .replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[AmadeusService] 🔍 Looking up hotel IDs → $uri');
    }

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type':  'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] Hotel‐lookup HTTP ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
        // Extract "hotelId" from each entry
        final List<String> hotelIds = data
            .map((entry) => (entry as Map<String, dynamic>)['hotelId'] as String)
            .toList();
        return hotelIds;
      }

      // If 400 or 404, treat as “no IDs found” → return empty list
      if (response.statusCode == 400 || response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ⚠️ Hotel‐lookup HTTP ${response.statusCode} → returning empty ID list.');
        }
        return <String>[];
      }

      // Any other status → empty
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Hotel‐lookup HTTP ${response.statusCode} – unexpected, returning empty list.');
      }
      return <String>[];
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Hotel‐lookup error: $e → returning empty list.');
      }
      return <String>[];
    }
  }

  /// 3b) Step 2 of hotel search: fetch hotel‐offers given a list of hotel IDs
  Future<List<dynamic>> _fetchHotelOffersByIds({
    required List<String> hotelIds,
    required String checkInDate,
    required String checkOutDate,
    int adults = 1,
    String currencyCode = 'MYR',
    int maxResults = 4,
  }) async {
    await _authenticate();
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    if (hotelIds.isEmpty) {
      return <dynamic>[]; // nothing to query
    }

    // Build comma‐separated hotelIds parameter
    final hotelIdsParam = hotelIds.join(',');

    final queryParams = {
      'hotelIds':    hotelIdsParam,
      'checkInDate':  checkInDate,
      'checkOutDate': checkOutDate,
      'adults':       adults.toString(),
      'currency':     currencyCode.toUpperCase(),
      'roomQuantity': '1',          // required for v3
      'limit':        maxResults.toString(),
    };

    final uri = Uri.parse(_hotelOffersEndpoint)
        .replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[AmadeusService] 🏨 Fetching hotel‐offers → $uri');
    }

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type':  'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] Hotel‐offers HTTP ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>? ?? [];

        if (kDebugMode) {
          debugPrint('[AmadeusService] ✅ Found ${data.length} hotel offers');
        }
        return data;
      }

      // 400 or 404 → fallback to mock
      if (response.statusCode == 400 || response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ⚠️ Hotel‐offers HTTP ${response.statusCode} – using mock data.');
        }
        return _getMockHotelData(hotelIds.first.substring(0, 3), currencyCode);
      }

      // 401 → token expired → retry once
      if (response.statusCode == 401) {
        _accessToken = null;
        return await _fetchHotelOffersByIds(
          hotelIds: hotelIds,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          adults: adults,
          currencyCode: currencyCode,
          maxResults: maxResults,
        );
      }

      // Any other error → fallback
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Hotel‐offers HTTP ${response.statusCode} – using mock.');
      }
      return _getMockHotelData(hotelIds.first.substring(0, 3), currencyCode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Hotel‐offers exception: $e – returning mock hotel data.');
      }
      return _getMockHotelData(hotelIds.first.substring(0, 3), currencyCode);
    }
  }

  /// 3) Public entrypoint: searchHotels
  ///    First look up hotel IDs by city, then fetch offers for those IDs.
  ///    Falls back to mock data if anything goes wrong.
  Future<List<dynamic>> searchHotels({
    required String cityCode,
    required String checkInDate,
    required String checkOutDate,
    int adults = 1,
    String currencyCode = 'MYR',
    int maxResults = 4,
  }) async {
    try {
      // Step 1: get hotel IDs in that city
      final hotelIds = await _lookupHotelIdsByCity(
        cityCode: cityCode,
        maxHotels: maxResults,
      );

      // If no IDs found, use mock
      if (hotelIds.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] No hotel IDs found for $cityCode → returning mock data.');
        }
        return _getMockHotelData(cityCode, currencyCode);
      }

      // Step 2: fetch actual offers for those hotel IDs
      final offers = await _fetchHotelOffersByIds(
        hotelIds: hotelIds,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        adults: adults,
        currencyCode: currencyCode,
        maxResults: maxResults,
      );

      // If the actual API returned zero offers, fallback to mock
      if (offers.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] Hotel‐offers returned empty → returning mock data.');
        }
        return _getMockHotelData(cityCode, currencyCode);
      }

      return offers;
    } catch (e) {
      // Any exception in either step → use mock
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] 🤕 searchHotels exception: $e → returning mock data.');
      }
      return _getMockHotelData(cityCode, currencyCode);
    }
  }

  /// 4) Search Airport Transfers (v1). We drop unsupported params,
  ///    only keep: airportCode, pickupDateTime, currency, transferType.
  ///    Fall back to mock on error.
  Future<List<dynamic>> searchAirportTransfers({
    required String airportCode,
    required String pickupDateTime, // e.g. "2025-06-23T11:15" or "2025-06-23T11:15:00"
    String currencyCode = 'MYR',
  }) async {
    await _authenticate();
    if (_accessToken == null) {
      throw Exception('No access token available');
    }

    // Ensure full ISO timestamp (with seconds) if user passed "YYYY-MM-DDTHH:mm"
    String isoTimestamp = pickupDateTime;
    if (!pickupDateTime.contains(':00')) {
      isoTimestamp = '$pickupDateTime:00'; // e.g. "2025-06-23T11:15:00"
    }

    final queryParams = {
      'airportCode':    airportCode.toUpperCase(),
      'pickupDateTime': isoTimestamp,
      'currency':       currencyCode.toUpperCase(),
      'transferType':   'PRIVATE,SHARED',
    };

    final uri = Uri.parse(_airportTransferEndpoint)
        .replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[AmadeusService] 🚗 Searching transfers → $uri');
    }

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type':  'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] Transfer search HTTP ${response.statusCode}: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>? ?? [];

        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ✅ Found ${data.length} transfer options');
        }

        if (data.isEmpty) {
          if (kDebugMode) {
            debugPrint(
                '[AmadeusService] Transfer search returned empty → using mock data.');
          }
          return _getMockTransferData(airportCode, currencyCode);
        }
        return data;
      }

      // 400 → fallback to mock data
      if (response.statusCode == 400) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ⚠️ Transfer search (400) – using mock data: ${response.body}');
        }
        return _getMockTransferData(airportCode, currencyCode);
      }

      // 401 → token expired → retry once
      if (response.statusCode == 401) {
        _accessToken = null;
        return await searchAirportTransfers(
          airportCode: airportCode,
          pickupDateTime: pickupDateTime,
          currencyCode: currencyCode,
        );
      }

      // 404 → sandbox likely not supported for that route
      if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint(
              '[AmadeusService] ⚠️ Transfer search (404) – using mock data (unsupported route).');
        }
        return _getMockTransferData(airportCode, currencyCode);
      }

      // Any other error → fallback
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Transfer search HTTP ${response.statusCode} – using mock.');
      }
      return _getMockTransferData(airportCode, currencyCode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[AmadeusService] ⚠️ Transfer search error: $e – returning mock data.');
      }
      return _getMockTransferData(airportCode, currencyCode);
    }
  }

  /// 5) Mock Hotel Data (unchanged from your original, for fallback)
  List<dynamic> _getMockHotelData(String cityCode, String currency) {
    final hotelNames = {
      'KUL': ['Petronas Twin Towers Hotel', 'KLCC Grand Hotel', 'Bukit Bintang Suite'],
      'SIN': ['Marina Bay Hotel', 'Orchard Central Hotel', 'Sentosa Resort'],
      'BKK': ['Siam Square Hotel', 'Sukhumvit Grand', 'Chatuchak Plaza'],
      'CGK': ['Jakarta Crown Plaza', 'Thamrin Executive', 'Menteng Palace'],
      'PEN': ['Penang Riverside Hotel', 'Gurney Plaza Inn', 'Straits Quay Boutique'],
    };

    final hotels =
        hotelNames[cityCode] ?? ['City Center Hotel', 'Airport Plaza', 'Downtown Inn'];
    final basePrice = (currency == 'MYR') ? 200.0 : ((currency == 'USD') ? 50.0 : 45.0);

    return hotels.map((name) {
      final hHash = name.hashCode % 100;
      return {
        'type': 'hotel-offers',
        'hotel': {
          'hotelId': '${cityCode}_${name.replaceAll(' ', '_').toLowerCase()}',
          'name': name,
          'cityCode': cityCode,
          'rating': (3 + (hHash % 3)).toString(),
        },
        'offers': [
          {
            'id': 'offer_${hHash}',
            'price': {
              'currency': currency,
              'total': (basePrice + (hHash * 1.0)).toStringAsFixed(0),
              'base': (basePrice + (hHash * 1.0) - 20).toStringAsFixed(0),
            },
            'room': {
              'type': 'STANDARD',
              'typeEstimated': {
                'category': 'STANDARD_ROOM',
                'beds': 1,
                'bedType': 'DOUBLE'
              }
            },
            'ratePlans': [
              {
                'ratePlanCode': 'RAC',
                'description': 'Room Only'
              }
            ]
          }
        ]
      };
    }).toList();
  }

  /// 6) Mock Transfer Data (unchanged from your original, for fallback)
  List<dynamic> _getMockTransferData(String airportCode, String currency) {
    final providers = [
      'AirportLink Express',
      'City Transfer Pro',
      'Premium Shuttle',
      'Economy Ride'
    ];
    final basePrice = (currency == 'MYR') ? 35.0 : ((currency == 'USD') ? 8.0 : 7.0);

    return providers.map((provider) {
      final pHash = provider.hashCode % 50;
      return {
        'type': 'transfer-offer',
        'id': '${airportCode}_${provider.replaceAll(' ', '_').toLowerCase()}',
        'provider': {
          'name': provider,
          'code': provider.substring(0, 3).toUpperCase(),
        },
        'transferType':
            provider.contains('Economy') ? 'SHARED' : 'PRIVATE',
        'vehicle': {
          'category': provider.contains('Premium') ? 'BU' : 'EC',
          'description':
              provider.contains('Premium') ? 'Premium Vehicle' : 'Standard Vehicle',
        },
        'price': {
          'currency': currency,
          'total': (basePrice + (pHash * 1.0)).toStringAsFixed(0),
        },
        'duration': 'PT${25 + (pHash % 20)}M',
        'distance': {
          'value': 15 + (pHash % 10),
          'unit': 'KM'
        }
      };
    }).toList();
  }
}