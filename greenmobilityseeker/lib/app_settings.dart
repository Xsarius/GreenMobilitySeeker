import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  String carToken;
  String chToken;

  AppSettings({required this.carToken, required this.chToken});

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      carToken: json['carToken'] ?? '',
      chToken: json['chToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carToken': carToken,
      'chToken': chToken,
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
    return AppSettings(carToken: '', chToken: '');
  }

  static Future<void> saveAppSettings(AppSettings settings) async {
    await _prefs.setString('app_settings', jsonEncode(settings.toJson()));
  }
}
