import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:background_fetch/background_fetch.dart';
import 'settings_page.dart';
import 'app_settings.dart';
import 'unfoldable_tile.dart';
import 'utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permission
  await Permission.location.request();

  await AppSettingsProvider.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Mobility Seeker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF17191C), // Background color
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              color: Color.fromARGB(255, 222, 229, 232)), // Main text color
          bodyMedium: TextStyle(
              color:
                  Color.fromARGB(255, 222, 229, 232)), // Secondary text color
          headlineLarge: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255)), // AppBar text color
          // Add more text styles if needed
        ),
      ),
      home: const MyHomePage(title: 'Green Mobility Seeker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _carCount = 0;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _chargers = [];

  bool _isLoading = false;
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startBackgroundFetch();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String message) async {

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'New Cars Channel',
      'Channel for notifying about new cars',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'New Cars Found!',
      message,
      platformChannelSpecifics,
    );
  }

  void _setCarList(int carCount, List<Map<String, dynamic>> vehicles) {
    setState(() {
      _carCount = carCount;
      _vehicles = vehicles;
    });
  }

  void _setChargersList(List<Map<String, dynamic>> chargers) {
    setState(() {
      _chargers = chargers;
    });
  }

  Future<void> _refreshCarList() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<Map<String, dynamic>> carList = await getCarList();
      await _refreshChargersList();

      carList = await getDistToChargers(carList, _chargers);
      carList = estNetGain(carList);

      int carCount = carList.length;
      if (carCount > _vehicles.length) {
        final int newCarsCount = carCount; // - _vehicles.length;
        _showNotification('Found $newCarsCount new car(s) nearby!');
      }
      _setCarList(carCount, carList);
    } catch (error) {
      // print("Error refreshing car list: $error");
      // Handle the error as needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshChargersList() async {
    List<Map<String, dynamic>> chargers = await getChargersList();
    List<Map<String, dynamic>> zones = await getZonesList();

    chargers = filterChargersInsideZones(chargers, zones);

    _setChargersList(chargers);
  }

  void _startBackgroundFetch() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 5, // Interval in minutes
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
      ),
      (String taskId) async {
        await _refreshCarList();  
        BackgroundFetch.finish(taskId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'There are $_carCount GreenMobilities nearby that can be charged.',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vehicles.length,
                      itemBuilder: (BuildContext context, int index) {
                        int batteryLevel = _vehicles[index]['battery'];

                        Color tileColor;

                        if (batteryLevel < 20) {
                          tileColor = Colors.green[800]!;
                        } else if (batteryLevel < 40) {
                          tileColor = Colors.green[600]!;
                        } else if (batteryLevel <= 60) {
                          tileColor = Colors.green[400]!;
                        } else {
                          tileColor = Colors.green[100]!;
                        }

                        return UnfoldingTile(
                          tileData: _vehicles[index],
                          tileColor: tileColor,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isLoading // Check loading state
          ? FloatingActionButton(
              onPressed: () {}, // Disable button when loading
              child: const CircularProgressIndicator(), // Show loading indicator
            )
          : FloatingActionButton(
              onPressed: _refreshCarList,
              tooltip: 'Refresh car count',
              child: const Icon(Icons.refresh),
            ),
    );
  }
}
