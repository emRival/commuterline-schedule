import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:krl_schedule_with_gemini_ai/krl_schedule_page.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: kIsWeb && !(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android),
      isToolbarVisible: kIsWeb && !(defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android),
      defaultDevice: Devices.ios.iPhone13ProMax,
      builder: (context) => MaterialApp(
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(useMaterial3: true),
        home:  KRLSchedulePage(), // disarankan pakai const jika memungkinkan
      ),
    ),
  );
}
