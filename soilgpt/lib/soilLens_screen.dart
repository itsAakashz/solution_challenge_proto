import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SoilLensScreen extends StatefulWidget {
  @override
  _SoilLensScreenState createState() => _SoilLensScreenState();
}

class _SoilLensScreenState extends State<SoilLensScreen> {
  File? _image;
  bool _isLoading = false;
  String _analysisResult = "";

  final ImagePicker _picker = ImagePicker();

  // 📷 Capture Image from Camera
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _analyzeSoil(); // Call API after image is selected
    }
  }

  // 📂 Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _analyzeSoil(); // Call API after image is selected
    }
  }

  // 🌱 Send Image to AI Model for Analysis
  Future<void> _analyzeSoil() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _analysisResult = "";
    });

    var url = Uri.parse("https://your-api.com/analyze-soil"); // Replace with actual API
    var request = http.MultipartRequest("POST", url)
      ..files.add(await http.MultipartFile.fromPath("file", _image!.path));

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      setState(() {
        _isLoading = false;
        _analysisResult = jsonData["result"] ?? "No analysis found.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _analysisResult = "Error analyzing soil.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Soil Lens"), backgroundColor: Colors.green[700]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🖼 Display Selected Image
            _image != null
                ? Image.file(_image!, height: 200, fit: BoxFit.cover)
                : Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text("No Image Selected")),
            ),
            SizedBox(height: 20),

            // 🎥 Capture or Select Image Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera", style: TextStyle(color: Colors.white),),
                  onPressed: _pickImageFromCamera,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text("Gallery", style: TextStyle(color: Colors.white)),
                  onPressed: _pickImageFromGallery,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                ),
              ],
            ),
            SizedBox(height: 20),

            // ⏳ Loading Indicator
            if (_isLoading) CircularProgressIndicator(),

            // 📊 Display Analysis Result
            if (_analysisResult.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _analysisResult,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[900]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
