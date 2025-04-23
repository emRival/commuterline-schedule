import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:krl_schedule_with_gemini_ai/models/api_detail_jadwal_krl.dart';
import 'package:krl_schedule_with_gemini_ai/models/api_jadwal_krl.dart';

class KRLService {
  // --- Token API (Sebaiknya disimpan lebih aman, misal via environment variables) ---
  final String _token =
      'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiMDYzNWIyOGMzYzg3YTY3ZTRjYWE4YTI0MjYxZGYwYzIxNjYzODA4NWM2NWU4ZjhiYzQ4OGNlM2JiZThmYWNmODU4YzY0YmI0MjgyM2EwOTUiLCJpYXQiOjE3MjI2MTc1MTQsIm5iZiI6MTcyMjYxNzUxNCwiZXhwIjoxNzU0MTUzNTE0LCJzdWIiOiI1Iiwic2NvcGVzIjpbXX0.Jz_sedcMtaZJ4dj0eWVc4_pr_wUQ3s1-UgpopFGhEmJt_iGzj6BdnOEEhcDDdIz-gydQL5ek0S_36v5h6P_X3OQyII3JmHp1SEDJMwrcy4FCY63-jGnhPBb4sprqUFruDRFSEIs1cNQ-3rv3qRDzJtGYc_bAkl2MfgZj85bvt2DDwBWPraZuCCkwz2fJvox-6qz6P7iK9YdQq8AjJfuNdl7t_1hMHixmtDG0KooVnfBV7PoChxvcWvs8FOmtYRdqD7RSEIoOXym2kcwqK-rmbWf9VuPQCN5gjLPimL4t2TbifBg5RWNIAAuHLcYzea48i3okbhkqGGlYTk3iVMU6Hf_Jruns1WJr3A961bd4rny62lNXyGPgNLRJJKedCs5lmtUTr4gZRec4Pz_MqDzlEYC3QzRAOZv0Ergp8-W1Vrv5gYyYNr-YQNdZ01mc7JH72N2dpU9G00K5kYxlcXDNVh8520-R-MrxYbmiFGVlNF2BzEH8qq6Ko9m0jT0NiKEOjetwegrbNdNq_oN4KmHvw2sHkGWY06rUeciYJMhBF1JZuRjj3JTwBUBVXcYZMFtwUAoikVByzKuaZZeTo1AtCiSjejSHNdpLxyKk_SFUzog5MOkUN1ktAhFnBFoz6SlWAJBJIS-lHYsdFLSug2YNiaNllkOUsDbYkiDtmPc9XWc';

  Future<List<DataJadwalKrl>> fetchJadwal(String stationCode) async {
    if (stationCode.isEmpty) return [];

    final url = Uri.parse(
      'https://api-partner.krl.co.id/krl-webs/v1/schedule?stationid=$stationCode&timefrom=00:00&timeto=23:59',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': _token, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final now = TimeOfDay.now();
        final nowMinutes = now.hour * 60 + now.minute;

        final schedules = JadwalKrl.fromJson(jsonData);
        final upcomingSchedules =
            schedules.data!.where((schedule) {
              final scheduleTime = schedule.timeEst!;
              final scheduleHour = int.parse(scheduleTime.split(':')[0]);
              final scheduleMinute = int.parse(scheduleTime.split(':')[1]);
              final scheduleMinutes = scheduleHour * 60 + scheduleMinute;

              return scheduleMinutes >= nowMinutes;
            }).toList();
        return upcomingSchedules;
      } else {
        throw Exception('Gagal ambil jadwal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  Future<List<DataDetailJadwalKrl>> fetchDetailJadwal(String trainId) async {
    if (trainId.isEmpty) return [];

    final url = Uri.parse(
      'https://api-partner.krl.co.id/krl-webs/v1/schedule-train?trainid=$trainId',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': _token, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final schedules = DetailJadwalKrl.fromJson(jsonData);

        return schedules.data!;
      } else {
        throw Exception('Gagal ambil detail jadwal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }
}
