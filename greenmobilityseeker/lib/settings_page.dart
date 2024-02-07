import 'package:flutter/material.dart';
import 'app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _carTokenController;
  late TextEditingController _chTokenController;

  @override
  void initState() {
    super.initState();
    _carTokenController = TextEditingController();
    _chTokenController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Car Token'),
            TextField(
              controller: _carTokenController,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            const Text('CH Token'),
            TextField(
              controller: _chTokenController,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                AppSettings settings = AppSettings(
                  carToken: _carTokenController.text,
                  chToken: _chTokenController.text,
                );
                await AppSettingsProvider.saveAppSettings(settings);

                // Clear text fields after saving settings
                _carTokenController.clear();
                _chTokenController.clear();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _carTokenController.dispose();
    _chTokenController.dispose();
    super.dispose();
  }
}
