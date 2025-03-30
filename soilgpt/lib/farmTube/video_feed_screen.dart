import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'upload_video_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Short Video Feed',
      theme: ThemeData.dark(),
      home: ShortVideoFeed(),
    );
  }
}

class ShortVideoFeed extends StatefulWidget {
  @override
  _ShortVideoFeedState createState() => _ShortVideoFeedState();
}

class _ShortVideoFeedState extends State<ShortVideoFeed> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  Future<void> _initVideos() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('videos').orderBy('timestamp', descending: true).get();

      final List<Map<String, dynamic>> videoData = querySnapshot.docs.map((doc) {
        return {
          'url': doc['videoUrl'] as String,
          'title': doc['title'] as String,
          'description': doc['description'] as String,
          'username': doc['username'] ?? 'Unknown',
        };
      }).toList();

      setState(() {
        videos = videoData;
      });
    } catch (e) {
      print('Error fetching videos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Short Video Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadVideoScreen()),
              ).then((_) => _initVideos());
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : videos.isEmpty
          ? Center(child: Text('No videos available'))
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoItem(
            videoUrl: videos[index]['url']!,
            title: videos[index]['title']!,
            description: videos[index]['description']!,
            username: videos[index]['username']!,
          );
        },
      ),
    );
  }
}

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final String username;

  VideoItem({required this.videoUrl, required this.title, required this.description, required this.username});

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: true,
      showControls: false,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _shareVideo() {
    Share.share(widget.videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_videoController.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
      },
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          Positioned(
            bottom: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.username}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.description,
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(Icons.share, color: Colors.black),
              onPressed: _shareVideo,
            ),
          ),
        ],
      ),
    );
  }
}
