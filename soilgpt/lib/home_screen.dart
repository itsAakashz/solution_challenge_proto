import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> getCropRecommendation() async {
    final url = Uri.parse("http://YOUR_FLASK_SERVER_IP:5000/predict");

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text("SOIL GPT"),
        backgroundColor: Colors.green[700],
      ),
      drawer: Drawer(  // <-- Added Hamburger Menu
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/img.jpg"),  // Make sure this image exists
                  fit: BoxFit.cover,  // Cover the full header area
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),  // Dark overlay for text visibility
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "🌱 SOIL GPT",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.home, color: Colors.green),
              title: Text("Home"),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.dirty_lens_rounded, color: Colors.orange),
              title: Text("Soil Lens"),
              onTap: () {
                Navigator.pop(context);
                _showDialog(context, "Contact", "Email: support@cropai.com\nPhone: +123 456 7890");
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text("About"),
              onTap: () {
                Navigator.pop(context);
                _showDialog(context, "About", "This app recommends crops based on soil and climate conditions.");
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Enter Soil & Weather Conditions",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
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
            ElevatedButton(
              onPressed: getCropRecommendation,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                backgroundColor: Colors.green[700],
              ),
              child: Text("Recommend Crop", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 20),
            if (recommendedCrop.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "🌾 Recommended Crop: $recommendedCrop",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ),
          ],
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

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
