import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController locationController = TextEditingController();
  bool isLoading = false;
  String result = "";

  // Function to get recommendations from Gemini AI (assuming it's integrated)
  Future<void> getRecommendations(String location) async {
    setState(() {
      isLoading = true;
    });

    // Call Google Gemini API to get soil conditions and crop recommendation
    try {
      // Replace with the actual URL and API key for Gemini
      final response = await http.post(
        Uri.parse('https://gemini-api-url.com/get_recommendations'), // Replace with actual API URL
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isLoading = false;
          result = "Soil Condition: ${data['soilCondition']}\nSuitable Crop: ${data['suitableCrop']}";
        });
      } else {
        setState(() {
          isLoading = false;
          result = "Error fetching data.";
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        result = "Failed to fetch data. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Enter Location for Recommendations",
          style: GoogleFonts.poppins(fontSize: 20),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Input Field for Location
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: "Enter your location (City/Region/Country)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Button to get recommendations
            ElevatedButton(
              onPressed: () {
                if (locationController.text.isNotEmpty) {
                  getRecommendations(locationController.text);
                } else {
                  setState(() {
                    result = "Please enter a location.";
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Get Soil & Crop Recommendation",
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),

            // Loading indicator
            if (isLoading) CircularProgressIndicator(),

            // Display the result
            if (!isLoading && result.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  result,
                  style: TextStyle(fontSize: 16, color: Colors.green[900]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
