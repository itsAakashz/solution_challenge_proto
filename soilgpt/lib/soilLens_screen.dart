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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _analyzeSoil();
    }
  }

  Future<void> _analyzeSoil() async {
    if (_image == null) return;
    setState(() {
      _isLoading = true;
      _analysisResult = "";
    });

    var url = Uri.parse("https://your-api.com/analyze-soil");
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
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          "Soil Lens",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  image: _image != null
                      ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _image == null
                    ? Center(
                  child: Text(
                    "No Image Selected",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text("Camera"),
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text("Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(color: Colors.green[700]),
                  SizedBox(height: 10),
                  Text("Analyzing...", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            if (_analysisResult.isNotEmpty)
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.green[200]!, Colors.green[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Soil Analysis Result",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _analysisResult,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
