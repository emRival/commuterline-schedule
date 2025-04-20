import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krl_schedule_with_gemini_ai/models/api_commuter_schedule.dart';

class GetCommuter {
  final String baseUrl = "https://www.api.comuline.com/v1/";

  Future<CommuterSchedule> getSchedule({required String originStation}) async {
    final response = await http.get(
      Uri.parse(baseUrl + "schedule/$originStation"),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      CommuterSchedule schedule = CommuterSchedule.fromJson(jsonMap);

      schedule.data =
          schedule.data
              ?.where((item) => item.stationOriginId == originStation)
              .toList();

      return schedule;
    } else {
      throw Exception('Failed to load commuter schedule');
    }
  }

  // Helper function to extract time in minutes
  int getTimeInMinutes(DateTime dateTime) {
    return dateTime.hour * 60 + dateTime.minute;
  }

  // Helper function to format DateTime to just show hours and minutes
  static String formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  List<Data> filterByNearestTime(List<Data> dataList, DateTime now, int limit) {
    List<Data> upcoming = [];

    for (var item in dataList) {
      try {
        DateTime departTime = DateTime.parse(item.departsAt!).toLocal();

        // Bandingkan hanya jam & menit
        if (departTime.hour > now.hour ||
            (departTime.hour == now.hour && departTime.minute > now.minute)) {
          upcoming.add(item);
        }
      } catch (e) {
        print("Error parsing time: ${item.departsAt}");
      }
    }

    // Urutkan berdasarkan jam terdekat
    upcoming.sort((a, b) {
      DateTime aTime = DateTime.parse(a.departsAt!).toLocal();
      DateTime bTime = DateTime.parse(b.departsAt!).toLocal();
      return aTime.compareTo(bTime);
    });

    // // Debug
    // print("Filtered Departure Times:");
    // for (var item in upcoming) {
    //   DateTime time = DateTime.parse(item.departsAt!).toLocal();
    //   print(
    //     "Departure: ${item.stationOriginId} → ${item.stationDestinationId} at ${formatTime(time)}",
    //   );
    // }

    return upcoming.take(limit).toList();
  }

  // Get nearest departure time based on current time (ignoring date)
  Future<List<Data>> getNearestDepartureTime({
    required String originStation,
  }) async {
    DateTime now = DateTime.now(); // Get current time from the device

    // Fetch the commuter schedule data for the origin station
    var schedule = await getSchedule(originStation: originStation);

    if (schedule.data == null || schedule.data!.isEmpty) {
      print("No available schedules for $originStation.");
      return []; // Return an empty list if no data
    }

    // Filter and get the nearest departure times (ignoring date)
    List<Data> nearestDepartures = filterByNearestTime(schedule.data!, now, 10);

    if (nearestDepartures.isEmpty) {
      print("No upcoming departures for $originStation.");
      return []; // Return an empty list if no upcoming departures
    }

    return nearestDepartures; // Return the filtered list of nearest departures
  }
}
