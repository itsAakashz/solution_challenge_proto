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

    final url = Uri.parse("http://YOUR_FLASK_SERVER_IP:5000/predict");

    try {
      final response = await http.post(
        url,
        body: {
          'Nitrogen': nitrogenController.text,
          'Phosphorus': phosphorusController.text,
          'Potassium': potassiumController.text,
          'Temperature': temperatureController.text,
          'Humidity': humidityController.text,
          'Ph': phController.text,
          'Rainfall': rainfallController.text,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          recommendedCrop = jsonDecode(response.body)['result'];
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
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text("SOIL GPT"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
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
