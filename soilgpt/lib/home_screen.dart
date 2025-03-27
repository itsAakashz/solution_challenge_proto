import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

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

  String recommendedCrop = "";
  bool isLoading = false;

  Future<void> getCropRecommendation() async {
    setState(() {
      isLoading = true;
    });

    final apiKey = "AIzaSyBX55Wxz61k-TpRhcuLyOGr8vU2PdFeS1Q";
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateText?key=$apiKey");

    // 🔥 Improved Prompt for More Accurate Recommendations
    String prompt = """
  You are an expert in agronomy and soil science. Based on the given soil and weather conditions, 
  provide the most suitable crop recommendation. Consider essential agronomic factors and scientific knowledge 
  for the best yield and sustainability.

  Here are the details:
  - Nitrogen: ${nitrogenController.text} mg/kg
  - Phosphorus: ${phosphorusController.text} mg/kg
  - Potassium: ${potassiumController.text} mg/kg
  - Temperature: ${temperatureController.text} °C
  - Humidity: ${humidityController.text} %
  - Soil pH: ${phController.text}
  - Rainfall: ${rainfallController.text} mm

  Based on this data, suggest the best crop(s) for cultivation. Also, explain why they are suitable and provide 
  tips for maximizing yield.
  """;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "prompt": {"text": prompt},
          "temperature": 0.7, // Adjust for creativity (0.3 for conservative results)
          "maxTokens": 200, // Limit response size
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String geminiResponse = jsonResponse['candidates'][0]['output'];

        setState(() {
          recommendedCrop = geminiResponse;
        });
      } else {
        setState(() {
          recommendedCrop = "Error: Could not get recommendation.";
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


  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Set scaffold key
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text("SOIL GPT"),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open drawer
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.logout),
        //     onPressed: logout,
        //   ),
        // ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/img.jpg"), // Background image
                  fit: BoxFit.cover, // Ensures full coverage
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Dark overlay for better text visibility
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Soil GPT',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Soil Lens'),
              onTap: () {
                // Navigate to Soil Lens page
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_page),
              title: Text('Contact'),
              onTap: () {
                // Navigate to Contact page
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to Settings
              },
            ),
            Spacer(), // Push logout to bottom
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: logout,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Enter Soil & Weather Conditions",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              _buildTextField(nitrogenController, "Nitrogen (N)"),
              _buildTextField(phosphorusController, "Phosphorus (P)"),
              _buildTextField(potassiumController, "Potassium (K)"),
              _buildTextField(temperatureController, "Temperature (°C)"),
              _buildTextField(humidityController, "Humidity (%)"),
              _buildTextField(phController, "pH Level"),
              _buildTextField(rainfallController, "Rainfall (mm)"),
              SizedBox(height: 20),

              Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: isLoading
                      ? CircularProgressIndicator(key: ValueKey('loading'))
                      : ElevatedButton(
                    key: ValueKey('button'),
                    onPressed: getCropRecommendation,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                      backgroundColor: Colors.green[700],
                    ),
                    child: Text(
                      "Recommend Crop",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: recommendedCrop.isNotEmpty ? 1.0 : 0.0,
                child: Center(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: recommendedCrop.isNotEmpty ? double.infinity : 0,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "🌾 Recommended Crop: $recommendedCrop",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
