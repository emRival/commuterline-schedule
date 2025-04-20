import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/api_station_name.dart';

Future<ApiStationName> loadStationsFromAssets() async {
  final String jsonString = await rootBundle.loadString(
    'assets/data/stations.json',
  );
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  final apiStation = ApiStationName.fromJson(jsonMap);

  // Urutkan berdasarkan nama stasiun
  apiStation.data?.sort((a, b) => a.name!.compareTo(b.name!));

  return apiStation;
}
