import 'dart:io';
import 'package:flutter/material.dart';
import 'firebase_service.dart';

class UploadVideoScreen extends StatefulWidget {
  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedVideo;
  final TextEditingController _titleController = TextEditingController();

  void _pickVideo() async {
    File? video = await _firebaseService.pickVideo();
    if (video != null) {
      setState(() => _selectedVideo = video);
    }
  }

  void _uploadVideo() async {
    if (_selectedVideo == null || _titleController.text.isEmpty) return;
    String? videoUrl = await _firebaseService.uploadVideo(_selectedVideo!);
    if (videoUrl != null) {
      await _firebaseService.saveVideoData(videoUrl, _titleController.text);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Video")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: "Title")),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _pickVideo, child: Text("Pick Video")),
            if (_selectedVideo != null) Text("Video Selected!"),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _uploadVideo, child: Text("Upload Video")),
          ],
        ),
      ),
    );
  }
}
