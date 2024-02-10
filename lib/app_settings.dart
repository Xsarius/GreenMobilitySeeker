import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  String carToken;
  String chToken;
  int batteryLevel;

  AppSettings({required this.carToken, required this.chToken, required this.batteryLevel});

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      carToken: json['carToken'] ?? '',
      chToken: json['chToken'] ?? '',
      batteryLevel: json['batteryLevel'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carToken': carToken,
      'chToken': chToken,
      'batteryLevel': batteryLevel,
    };
  }
}

class AppSettingsProvider {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static AppSettings getAppSettings() {
    String? settingsJson = _prefs.getString('app_settings');
    if (settingsJson != null) {
      Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
      return AppSettings.fromJson(settingsMap);
    }
    return AppSettings(carToken: '', chToken: '', batteryLevel: 60);
  }

  static Future<void> saveCarToken(String carToken) async {
    AppSettings settings = getAppSettings();
    settings.carToken = carToken;
    await _prefs.setString('app_settings', jsonEncode(settings.toJson()));
  }

  static Future<void> saveChToken(String chToken) async {
    AppSettings settings = getAppSettings();
    settings.chToken = chToken;
    await _prefs.setString('app_settings', jsonEncode(settings.toJson()));
  }

  static Future<void> saveBatteryLevel(int batteryLevel) async {
    AppSettings settings = getAppSettings();
    settings.batteryLevel = batteryLevel;
    await _prefs.setString('app_settings', jsonEncode(settings.toJson()));
  }
}
