import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UploadVideoScreen extends StatefulWidget {
  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _video;
  bool _isUploading = false;
  String? _downloadUrl;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_video == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a video and enter title & description")));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Generate unique file name
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload video
      UploadTask uploadTask = storageRef.putFile(_video!);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      String videoUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _downloadUrl = videoUrl;
      });

      print('✅ Upload successful: $videoUrl');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video uploaded successfully!")));
    } catch (e) {
      print('❌ Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to upload video")));
    } finally {
      setState(() {
        _isUploading = false;
        _video = null;
        _titleController.clear();
        _descriptionController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Video")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            _video != null
                ? Text("Video Selected")
                : ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video"),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : _video != null
                ? ElevatedButton(
              onPressed: _uploadVideo,
              child: Text("Upload Video"),
            )
                : Container(),
            if (_downloadUrl != null) ...[
              SizedBox(height: 20),
              Text("Download URL:", style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_downloadUrl ?? ""),
            ]
          ],
        ),
      ),
    );
  }
}