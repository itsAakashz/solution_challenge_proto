import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  String _location = "Fetching location...";
  String _errorMessage = "";
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  final String _apiKey = "8227b7d02e4c52f0c09e098f77512884";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      // Check if location services are enabled with timeout
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(Duration(seconds: 10), onTimeout: () {
          throw TimeoutException("Location service check timed out");
        });
      } on TimeoutException catch (e) {
        setState(() {
          _errorMessage = "Location service check timed out";
          _isLoading = false;
        });
        return;
      }

      if (!serviceEnabled) {
        setState(() {
          _errorMessage = "Please enable location services";
          _isLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = "Location permission required";
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = "Location permissions permanently denied. Enable in app settings.";
          _isLoading = false;
        });
        return;
      }

      // If we get here, permissions are granted
      _startLocationUpdates();
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
      print("Permission check error: $e");
    }
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 100,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateLocationAndWeather(position);
      },
      onError: (e) {
        setState(() {
          _errorMessage = "Location error: ${e.toString()}";
          _isLoading = false;
        });
        print("Location stream error: $e");
      },
    );
  }

  Future<void> _updateLocationAndWeather(Position position) async {
    try {
      // Get location name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(Duration(seconds: 10));

      Placemark place = placemarks[0];
      String locality = place.locality ?? place.subAdministrativeArea ?? "";
      String country = place.country ?? "";
      setState(() {
        _location = locality.isNotEmpty
            ? "$locality, $country"
            : "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });

      // Fetch weather data
      await _fetchWeatherData(position);
    } catch (e) {
      setState(() {
        _errorMessage = "Location update error: ${e.toString()}";
        _isLoading = false;
      });
      print("Location update error: $e");
      Fluttertoast.showToast(
        msg: "Error updating location",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _fetchWeatherData(Position position) async {
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric');

      print("Fetching weather data from: ${url.toString()}");

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['cod'] != 200) {
          throw Exception(data['message'] ?? "Weather API error");
        }
        setState(() {
          _weatherData = data;
          _isLoading = false;
          _errorMessage = "";
        });
      } else {
        throw Exception(
            "Failed to load weather data. Status code: ${response.statusCode}. Body: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Weather data error: ${e.toString()}";
        _isLoading = false;
      });
      print("Weather fetch error: $e");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        Position position = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        await _updateLocationAndWeather(position);
      } else {
        setState(() {
          _errorMessage = "Location not found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Search error: ${e.toString()}";
        _isLoading = false;
      });
      print("Location search error: $e");
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Search Location"),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "e.g., London, UK",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _searchLocation(_searchController.text);
              _searchController.clear();
            },
            child: Text("Search"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Weather App', style: GoogleFonts.poppins()),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _currentPosition != null
                  ? () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = "";
                });
                _fetchWeatherData(_currentPosition!);
              }
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.location_on),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = "";
                });
                _checkLocationPermission();
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Fetching weather data..."),
            if (_currentPosition != null) ...[
              SizedBox(height: 10),
              Text(
                "Current position:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checkLocationPermission,
                child: Text("Retry"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              if (_errorMessage.contains("permanently"))
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSettingsScreen(),
                      ),
                    );
                  },
                  child: Text("Open Location Settings"),
                ),
            ],
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: Colors.amber, size: 50),
            SizedBox(height: 20),
            Text("No weather data available"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _currentPosition != null
                  ? () {
                _fetchWeatherData(_currentPosition!);
                setState(() {
                  _isLoading = true;
                });
              }
                  : null,
              child: Text("Retry"),
            ),
          ],
        ),
      );
    }

    return WeatherScreen(
      location: _location,
      weatherData: _weatherData!,
      position: _currentPosition,
    );
  }
}

class WeatherScreen extends StatelessWidget {
  final String location;
  final Map<String, dynamic> weatherData;
  final Position? position;

  const WeatherScreen({
    required this.location,
    required this.weatherData,
    this.position,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weather = weatherData['weather']?[0];
    final main = weatherData['main'] ?? {};
    final wind = weatherData['wind'] ?? {};
    final rain = weatherData['rain'] ?? {};
    final snow = weatherData['snow'] ?? {};
    final clouds = weatherData['clouds'] ?? {};
    final sys = weatherData['sys'] ?? {};

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    location,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  if (position != null)
                    Text(
                      "${position!.latitude.toStringAsFixed(4)}, ${position!.longitude.toStringAsFixed(4)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  if (weather?['icon'] != null)
                    Image.network(
                      'https://openweathermap.org/img/wn/${weather['icon']}@4x.png',
                      width: 120,
                      height: 120,
                    ),
                  if (weather?['main'] != null)
                    Text(
                      weather['main'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  if (weather?['description'] != null)
                    Text(
                      weather['description'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildWeatherDetailCard(
              'Temperature',
              '${main['temp']?.toStringAsFixed(1) ?? 'N/A'}°C',
              Icons.thermostat,
              Colors.orange,
              subtitle: 'Min: ${main['temp_min']?.toStringAsFixed(1) ?? 'N/A'}°C / Max: ${main['temp_max']?.toStringAsFixed(1) ?? 'N/A'}°C',
            ),
            _buildWeatherDetailCard(
              'Feels Like',
              '${main['feels_like']?.toStringAsFixed(1) ?? 'N/A'}°C',
              Icons.device_thermostat,
              Colors.deepOrange,
            ),
            _buildWeatherDetailCard(
              'Humidity',
              '${main['humidity']?.toStringAsFixed(0) ?? 'N/A'}%',
              Icons.water_drop,
              Colors.blue,
            ),
            _buildWeatherDetailCard(
              'Wind Speed',
              '${wind['speed']?.toStringAsFixed(1) ?? 'N/A'} m/s',
              Icons.air,
              Colors.grey,
              subtitle: wind['deg'] != null ? 'Direction: ${_getWindDirection(wind['deg'])}' : null,
            ),
            if (rain['1h'] != null)
              _buildWeatherDetailCard(
                'Rain (1h)',
                '${rain['1h']?.toStringAsFixed(1) ?? 'N/A'} mm',
                Icons.beach_access,
                Colors.blueAccent,
              ),
            if (snow['1h'] != null)
              _buildWeatherDetailCard(
                'Snow (1h)',
                '${snow['1h']?.toStringAsFixed(1) ?? 'N/A'} mm',
                Icons.ac_unit,
                Colors.lightBlue,
              ),
            if (clouds['all'] != null)
              _buildWeatherDetailCard(
                'Cloudiness',
                '${clouds['all']?.toStringAsFixed(0) ?? 'N/A'}%',
                Icons.cloud,
                Colors.grey,
              ),
            _buildWeatherDetailCard(
              'Pressure',
              '${main['pressure']?.toStringAsFixed(0) ?? 'N/A'} hPa',
              Icons.speed,
              Colors.deepPurple,
            ),
            if (sys['sunrise'] != null && sys['sunset'] != null)
              _buildWeatherDetailCard(
                'Daylight',
                '${_formatTime(sys['sunrise'])} - ${_formatTime(sys['sunset'])}',
                Icons.wb_sunny,
                Colors.amber,
              ),
            SizedBox(height: 20),
            Text(
              'Agricultural Advice:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            SizedBox(height: 10),
            _buildAgriculturalAdvice(weatherData),
          ],
        ),
      ),
    );
  }

  String _getWindDirection(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360) ~/ 45;
    return directions[index];
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildWeatherDetailCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgriculturalAdvice(Map<String, dynamic> weatherData) {
    final main = weatherData['main'] ?? {};
    final temp = main['temp'] ?? 0;
    final humidity = main['humidity'] ?? 0;
    final rain = weatherData['rain']?['1h'] ?? 0;
    final snow = weatherData['snow']?['1h'] ?? 0;
    final wind = weatherData['wind']?['speed'] ?? 0;
    final weather = weatherData['weather']?[0] ?? {'main': ''};

    String advice = '';

    if (temp < 0) {
      advice = '❄️ Freezing temperatures: Protect crops from frost damage. Use row covers or greenhouses.';
    } else if (temp < 10) {
      advice = '🥶 Cold weather: Only cold-resistant crops should be active. Delay planting sensitive plants.';
    } else if (temp > 30) {
      advice = '🔥 Extreme heat: Increase irrigation. Provide shade. Harvest in early morning.';
    } else if (temp > 25) {
      advice = '☀️ Warm weather: Ideal for summer crops. Ensure adequate water.';
    } else {
      advice = '🌤️ Moderate temperatures: Excellent for most agricultural activities.';
    }

    if (humidity > 80) {
      advice += '\n\n💧 High humidity: Increase plant spacing. Watch for fungal diseases.';
    } else if (humidity < 40) {
      advice += '\n\n🏜️ Low humidity: Increase irrigation. Mulch soil. Use shade cloth.';
    }

    if (rain > 10) {
      advice += '\n\n🌧️ Heavy rainfall: Avoid field work. Check drainage. Monitor for erosion.';
    } else if (rain > 5) {
      advice += '\n\n🌦️ Moderate rain: Good for soil moisture. Good transplanting time.';
    } else if (weather['main'].toString().toLowerCase().contains('rain')) {
      advice += '\n\n🌧️ Rain expected: Good for planting/fertilizer. Avoid spraying chemicals.';
    }

    if (snow > 0) {
      advice += '\n\n❄️ Snow: Protect sensitive plants. Snow insulates but may damage branches.';
    }

    if (wind > 12) {
      advice += '\n\n🌪️ Storm winds: Secure equipment. Use windbreaks. Postpone spraying.';
    } else if (wind > 8) {
      advice += '\n\n🌬️ Strong winds: Increase irrigation. Stake plants. Helps drying crops.';
    } else if (wind > 5) {
      advice += '\n\n🍃 Moderate winds: Good for pollination. Reduces fungal diseases.';
    }

    return Card(
      color: Colors.white.withOpacity(0.8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Conditions Analysis:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[900],
              ),
            ),
            SizedBox(height: 10),
            Text(
              advice,
              style: TextStyle(fontSize: 16, color: Colors.green[900]),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Permission Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'For accurate weather information, this app needs access to your device location.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'How to enable location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            _buildStep('1. Open your device Settings'),
            _buildStep('2. Go to "Apps" or "Application Manager"'),
            _buildStep('3. Find and select this app'),
            _buildStep('4. Tap "Permissions"'),
            _buildStep('5. Enable "Location" permission'),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.pop(context);
                },
                child: Text('Open Location Settings'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(Icons.arrow_right, size: 20),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}