import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class GoogleMaps {
  CustomLogger logger = CustomLogger();
  Future<LatLng?> getCoordinatesFromAddress(String address);
  dynamic getLocationResults(String input, String? sessionToken);
}

@Injectable(as: GoogleMaps, env: [Env.test, Env.mock])
class GoogleMapsMock extends GoogleMaps {
  @override
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    logger.i("Fetching coordinates of $address");
    num hashcode = sha256.convert(address.codeUnits).hashCode / 100000000;
    logger.i("hashcode address: $hashcode");

    // Return random location in europe
    return LatLng(48.8566 + hashcode, 2.3522 + hashcode);
  }

  @override
  dynamic getLocationResults(String input, String? sessionToken) async {
    return [
      {
        'text': {
          'text': 'Paris, France',
        },
        'description': 'Paris, France',
        'place_id': 'ChIJD7fiBh9u5kcRYJSMaMOCCwQ',
        'structured_formatting': {
          'main_text': 'Paris',
          'secondary_text': 'France',
        },
      },
      {
        'text': {
          'text': 'London, UK',
        },
        'description': 'London, UK',
        'place_id': 'ChIJdd4hrwug2EcRmSrV3Vo6llI',
        'structured_formatting': {
          'main_text': 'London',
          'secondary_text': 'UK',
        },
      },
      {
        'text': {
          'text': 'Berlin, Germany',
        },
        'description': 'Berlin, Germany',
        'place_id': 'ChIJAVkDPzdOqEcRcDteW0YgIQQ',
        'structured_formatting': {
          'main_text': 'Berlin',
          'secondary_text': 'Germany',
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
  dynamic getLocationResults(String input, String? sessionToken) async {
    if (input.isEmpty) return [];
    String type = '(regions)';
    String baseURL = 'https://places.googleapis.com/v1/places:autocomplete';
    var response = await http.post(Uri.parse(baseURL), body: {
      'input': input,
      'includeQueryPredictions': 'false',
      'sessionToken': sessionToken,
    }, headers: {
      'X-Goog-Api-Key': getIt<Config>().googleMapsApiKey
    });
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      return body['suggestions'].map((i) => i['placePrediction']).toList();
    } else {
      logger.e('Failed to load predictions', error: response.body);
      throw Exception('Failed to load predictions');
    }
  }
}
