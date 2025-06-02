// lib/services/amadeus_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 1) Replace these with your Amadeus “API Key” & “API Secret” from developers.amadeus.com
const String _amadeusClientId     = 'HdrxjwkMggMOlUf5qk4J3zTkmzWxNaAD';
const String _amadeusClientSecret = '16BZleHCAGFL8cSF';

class AmadeusService {
  static const String _oauthEndpoint       = 'https://test.api.amadeus.com/v1/security/oauth2/token';
  static const String _flightOffersEndpoint = 'https://test.api.amadeus.com/v2/shopping/flight-offers';

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// 2) Fetch (and cache) an OAuth2 token
  Future<void> _authenticate() async {
    // If we already have a valid token, just return
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final response = await http.post(
      Uri.parse(_oauthEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type':    'client_credentials',
        'client_id':     _amadeusClientId,
        'client_secret': _amadeusClientSecret,
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      _accessToken = jsonBody['access_token'] as String?;
      final expiresIn  = jsonBody['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 30));
    } else {
      throw Exception(
        'Failed to get Amadeus OAuth token (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// 3) Call the Flight Offers Search endpoint
  /// departureDate must be “YYYY-MM-DD”
  Future<List<dynamic>> searchFlights({
    required String originCode,         // e.g. “KUL”
    required String destinationCode,    // e.g. “SIN”
    required String departureDate,      // e.g. “2023-07-15”
    bool direct = false,
    int adults = 1,
    String travelClass = 'ECONOMY',
  }) async {
    await _authenticate();
    if (_accessToken == null) {
      throw Exception('No valid Amadeus access token.');
    }

    final uri = Uri.parse(_flightOffersEndpoint).replace(queryParameters: {
      'originLocationCode':      originCode,
      'destinationLocationCode': destinationCode,
      'departureDate':           departureDate,
      'adults':                  adults.toString(),
      'travelClass':             travelClass, // “ECONOMY” / “BUSINESS” / etc.
      'nonStop':                 direct ? 'true' : 'false',
      // you can add more parameters if desired (currencyCode, max, etc.)
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type':  'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return (jsonBody['data'] as List<dynamic>);
    } else {
      throw Exception(
        'Flight search failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}