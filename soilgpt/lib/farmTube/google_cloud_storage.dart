import 'dart:io';
import 'package:google_cloud_storage/google_cloud_storage.dart'; // Ensure correct import
import 'package:path/path.dart';

class GoogleCloudStorageService {
  static final GoogleCloudStorageService _instance = GoogleCloudStorageService._internal();

  factory GoogleCloudStorageService() {
    return _instance;
  }

  GoogleCloudStorageService._internal(); // Private Constructor

  Future<String?> uploadVideo(File video) async {
    try {
      String fileName = basename(video.path);
      final storageRef = FirebaseStorage.instance.ref().child('videos/$fileName');

      UploadTask uploadTask = storageRef.putFile(video);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print("✅ Video uploaded: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("❌ Upload failed: $e");
      return null;
    }
  }
}
