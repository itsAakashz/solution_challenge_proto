import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:SoilGPT/contact_screen.dart';
import 'package:SoilGPT/soilLens_screen.dart';
import 'package:http/http.dart' as http;
import 'location_screen.dart';
import 'package:SoilGPT/mandi_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController nitrogenController = TextEditingController();
  final TextEditingController phosphorusController = TextEditingController();
  final TextEditingController potassiumController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController rainfallController = TextEditingController();

  String? savedLocation;

  bool isLoading = false;
  String result = "";
  String recommendedCrop = "";  // Declare recommendedCrop here

  @override
  void initState() {
    super.initState();
    _loadSavedLocation(); // Load the saved location when the screen is initialized
  }

  // Load saved location from SharedPreferences
  Future<void> _loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedLocation = prefs.getString('savedLocation');
    });
  }

  // Save location to SharedPreferences
  Future<void> _saveLocation(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedLocation', location);
    setState(() {
      savedLocation = location;
    });
  }

  // Location input dialog
  void _showLocationDialog() {
    final TextEditingController locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Location"),
          content: TextField(
            controller: locationController,
            decoration: InputDecoration(hintText: "Country/State/Region"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String location = locationController.text;
                if (location.isNotEmpty) {
                  _saveLocation(location); // Save the entered location
                }
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  // API Integration with Google API
  Future<void> getCropRecommendation() async {
    // Close the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final apiKey = "AIzaSyBX55Wxz61k-TpRhcuLyOGr8vU2PdFeS1Q";
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    String prompt = """
You are an expert in agronomy. Based on the given soil and weather conditions, 
provide the best crop recommendation. Ensure it is based on scientific knowledge.

- Nitrogen: ${nitrogenController.text} mg/kg
- Phosphorus: ${phosphorusController.text} mg/kg
- Potassium: ${potassiumController.text} mg/kg
- Temperature: ${temperatureController.text} °C
- Humidity: ${humidityController.text} %
- Soil pH: ${phController.text}
- Rainfall: ${rainfallController.text} mm

Suggest the best crop(s) along with reasons.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 200
          }
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('candidates') && jsonResponse['candidates'].isNotEmpty) {
          setState(() {
            recommendedCrop = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          });
        } else {
          setState(() {
            recommendedCrop = "No valid response from API.";
          });
        }
      } else {
        setState(() {
          recommendedCrop = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        recommendedCrop = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.green[900], size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            "SOIL GPT",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          Icon(Icons.eco_rounded, color: Colors.green[700], size: 28),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.green[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/img.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Soil GPT',
                    style: TextStyle(
                        fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.camera_alt, 'Soil Lens',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => SoilLensScreen()))),
            _buildDrawerItem(Icons.contact_page, 'Contact',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen()))),
            _buildDrawerItem(Icons.location_on, 'Set Location', _showLocationDialog),
            _buildDrawerItem(Icons.shopping_cart_rounded, 'Mandi Price',
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => MandiScreen()))),
            Divider(),
            _buildDrawerItem(Icons.logout, 'Logout', logout, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle("Enter Soil & Weather Conditions"),
          SizedBox(height: 15),
          _buildTextField(nitrogenController, "Nitrogen (N)", Icons.science_outlined),
          _buildTextField(phosphorusController, "Phosphorus (P)", Icons.thermostat_auto),
          _buildTextField(potassiumController, "Potassium (K)", Icons.water_drop),
          _buildTextField(temperatureController, "Temperature (°C)", Icons.thermostat_rounded),
          _buildTextField(humidityController, "Humidity (%)", Icons.cloud),
          _buildTextField(phController, "pH Level", Icons.bubble_chart),
          _buildTextField(rainfallController, "Rainfall (mm)", Icons.grain),
          SizedBox(height: 20),
          _buildRecommendButton(),
          if (isLoading) CircularProgressIndicator(),
          if (!isLoading && recommendedCrop.isNotEmpty) // Use recommendedCrop here
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                recommendedCrop,
                style: TextStyle(fontSize: 18, color: Colors.green[900]),
              ),
            ),
          if (savedLocation != null && savedLocation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Location: $savedLocation",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green[900]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.green[900],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          prefixIcon: Icon(icon, color: Colors.green[700]),
        ),
      ),
    );
  }

  Widget _buildRecommendButton() {
    return Center(
      child: ElevatedButton(
        onPressed: getCropRecommendation,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Recommend Crop",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFb2f7b0), Color(0xFFd2f8d2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }
}



