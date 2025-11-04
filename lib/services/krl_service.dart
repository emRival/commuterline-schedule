import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:krl_schedule_with_gemini_ai/models/api_detail_jadwal_krl.dart';
import 'package:krl_schedule_with_gemini_ai/models/api_jadwal_krl.dart';

class KRLService {
  // --- Token API (Sebaiknya disimpan lebih aman, misal via environment variables) ---
  final String _token =
      'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiYmE0Yzc4MzE4ODNjYTI0N2YzMTBkMTJhYzc3ZjE5ZTdjMTVkNjgxOTk2ODM0MDc0MGM3MzliYmRjNGQ3YTI5MzczYzMyNWM2NDFiZjgxYzciLCJpYXQiOjE3NTQ0NTkxMjYsIm5iZiI6MTc1NDQ1OTEyNiwiZXhwIjoxNzg1OTk1MTI2LCJzdWIiOiI1Iiwic2NvcGVzIjpbXX0.zPA0IDAN3NycMKa6DaOdRmkcFz1oUTX1dkxEp3MLBlhibTQI0L0WB9mY-pUlQW5vQj8ktOdo-rRvrjxiXaHFqLQM6ebONbqTg8V0AjBXwrkBjLZDCE4dop9iZyDXcG2b9XTLCgPgpOBbduW_Dy0-bIkJOOIgIzl9mEEUVQf3T6G_zA796SGJ6rtLqfBK-sMnhOV4eZSqQIXIrxPyCJ8SA893p-29PFxfQfcbXW_6cYBFhDzyiilhJ6xQd6znN2eWOL4MPAxYeS2ZGnaZ7ijUN91MAyPnV0dQU7loVtS1jt2HlM5oMSsE2Zoz6FP31GvG6f7o_MWogEp0ZMOus50bVly3II8Rjjc4IGgswbw0h-RS0Ipo3f2QmXp4GfhRNUoTyqq-7oiCIDPUJcdg39lSIy9Fz7-ECNfbjEiH60V3GyftuiFGrayMoE7XeWaC9wQZo3fLHhI1aPgbXXsP-rqWLFf2km4zdG5Y5CYpUNb_Z11VOU6aaFCdRtoC6e7VcxHxLwCBT22wluNpbfFtEQSYDQE1JlegijvFmnRHTM88n-zp7sWhuCWVX6oE0ULdy51SR4iOqpYOA4B1ZymmYrQz1kBxSA_52lnTBlU9gfWkUiFX8GLSh7wQ8a4dVMYoJj6t1VCJt9-d30jn4S3tXsim_3wpp71RE9SSazV35j8o7do';

  Future<List<DataJadwalKrl>> fetchJadwal(String stationCode) async {
    if (stationCode.isEmpty) return [];

    final url = Uri.parse(
      'https://api-partner.krl.co.id/krl-webs/v1/schedules?stationid=$stationCode&timefrom=00:00&timeto=23:59',
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
      'https://api-partner.krl.co.id/krl-webs/v1/schedules-train?trainid=$trainId',
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
