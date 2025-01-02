import 'dart:convert';

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

@Injectable(as: GoogleMaps)
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
