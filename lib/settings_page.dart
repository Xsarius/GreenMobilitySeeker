import 'package:flutter/material.dart';
import 'app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _carTokenController;
  late TextEditingController _chTokenController;
  late TextEditingController _batteryLevelController;

  @override
  void initState() {
    super.initState();
    _carTokenController = TextEditingController();
    _chTokenController = TextEditingController();
    _batteryLevelController = TextEditingController(text: '60'); // Set default value
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
                await saveTokens();
              },
              child: const Text('Save Tokens'),
            ),
            const SizedBox(height: 20),
            const Text('Battery Level'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batteryLevelController,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await saveBatteryLevel();
                  },
                  child: const Text('Save Battery Level'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveTokens() async {
    await AppSettingsProvider.saveCarToken(_carTokenController.text);
    await AppSettingsProvider.saveChToken(_chTokenController.text);
    _carTokenController.clear();
    _chTokenController.clear();
  }

  Future<void> saveBatteryLevel() async {
    await AppSettingsProvider.saveBatteryLevel(int.tryParse(_batteryLevelController.text) ?? 60);
    _batteryLevelController.clear();
  }

  @override
  void dispose() {
    _carTokenController.dispose();
    _chTokenController.dispose();
    _batteryLevelController.dispose();
    super.dispose();
  }
}
