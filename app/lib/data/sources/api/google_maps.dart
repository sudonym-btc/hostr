import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class GoogleMaps {
  CustomLogger logger = CustomLogger();
  Future<LatLng?> getCoordinatesFromAddress(String address);
  Future<LatLng?> getCoordinatesFromPlaceId(String placeId);
  Future<List<Map<String, dynamic>>> getLocationResults(
    String input,
    String? sessionToken, {
    Set<String>? featureTypes,
    int limit = 5,
  });
}

@Injectable(as: GoogleMaps, env: [Env.test, Env.mock])
class GoogleMapsMock extends GoogleMaps {
  @override
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    // logger.i("Fetching coordinates of $address");
    num hashcode = sha256.convert(address.codeUnits).hashCode / 100000000;
    // logger.i("hashcode address: $hashcode");

    // Return random location in europe
    return LatLng(48.8566 + hashcode, 2.3522 + hashcode);
  }

  @override
  Future<LatLng?> getCoordinatesFromPlaceId(String placeId) async {
    final hashcode = sha256.convert(placeId.codeUnits).hashCode / 100000000;
    return LatLng(48.8566 + hashcode, 2.3522 + hashcode);
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationResults(
    String input,
    String? sessionToken, {
    Set<String>? featureTypes,
    int limit = 5,
  }) async {
    return [
      {
        'placeId': 'ChIJD7fiBh9u5kcRYJSMaMOCCwQ',
        'text': {'text': 'Paris, France'},
        'structuredFormat': {
          'mainText': {'text': 'Paris'},
          'secondaryText': {'text': 'France'},
        },
      },
      {
        'placeId': 'ChIJdd4hrwug2EcRmSrV3Vo6llI',
        'text': {'text': 'London, UK'},
        'structuredFormat': {
          'mainText': {'text': 'London'},
          'secondaryText': {'text': 'UK'},
        },
      },
      {
        'placeId': 'ChIJAVkDPzdOqEcRcDteW0YgIQQ',
        'text': {'text': 'Berlin, Germany'},
        'structuredFormat': {
          'mainText': {'text': 'Berlin'},
          'secondaryText': {'text': 'Germany'},
        },
      },
    ];
  }
}

@Injectable(as: GoogleMaps, env: Env.allButTestAndMock)
class GoogleMapsImpl extends GoogleMaps {
  @override
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    logger.i("Fetching coordinates of $address");

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=${getIt<Config>().googleMapsApiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      logger.i("Fetched coordinates of $address: ${response.body}");

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    }
    return null;
  }

  @override
  Future<LatLng?> getCoordinatesFromPlaceId(String placeId) async {
    if (placeId.isEmpty) return null;

    final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId');
    final response = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': getIt<Config>().googleMapsApiKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logger.e('Failed to resolve place details', error: response.body);
      return null;
    }

    final body = json.decode(response.body);
    if (body is! Map<String, dynamic>) return null;
    final location = body['location'];
    if (location is! Map<String, dynamic>) return null;

    final lat = location['latitude'];
    final lon = location['longitude'];
    if (lat is num && lon is num) {
      return LatLng(lat.toDouble(), lon.toDouble());
    }

    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationResults(
    String input,
    String? sessionToken, {
    Set<String>? featureTypes,
    int limit = 5,
  }) async {
    if (input.isEmpty) return [];

    String baseURL = 'https://places.googleapis.com/v1/places:autocomplete';
    final includedPrimaryTypes = _toGooglePrimaryTypes(featureTypes);

    final body = <String, dynamic>{
      'input': input,
      'includeQueryPredictions': false,
      'sessionToken': sessionToken,
    };
    if (includedPrimaryTypes.isNotEmpty) {
      body['includedPrimaryTypes'] = includedPrimaryTypes.toList();
    }

    var response = await http.post(
      Uri.parse(baseURL),
      body: jsonEncode(body),
      headers: {
        'X-Goog-Api-Key': getIt<Config>().googleMapsApiKey,
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      final suggestions = body['suggestions'];
      if (suggestions is! List) return [];

      final mapped = suggestions
          .whereType<Map<String, dynamic>>()
          .map((s) => s['placePrediction'])
          .whereType<Map<String, dynamic>>()
          .take(limit)
          .toList();

      return mapped;
    } else {
      logger.e('Failed to load predictions', error: response.body);
      throw Exception('Failed to load predictions');
    }
  }

  Set<String> _toGooglePrimaryTypes(Set<String>? featureTypes) {
    if (featureTypes == null || featureTypes.isEmpty) {
      return const <String>{};
    }

    final types = <String>{};
    for (final raw in featureTypes) {
      final type = raw.toLowerCase().trim();
      switch (type) {
        case 'country':
          types.add('country');
          break;
        case 'state':
        case 'region':
        case 'province':
          types.add('administrative_area_level_1');
          break;
        case 'city':
          types.add('locality');
          break;
        case 'town':
        case 'village':
        case 'settlement':
          types.add('locality');
          break;
      }
    }

    return types;
  }
}
