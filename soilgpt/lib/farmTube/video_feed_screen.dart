import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Short Video Feed',
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  List<String> videoUrls = [];
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  Future<void> _initVideos() async {
    try {
      final storage = await _getStorageClient();
      final bucketName = 'soilgpt';

      var objects = await storage.objects.list(bucketName);
      var urls = objects.items!
          .where((item) => item.name!.endsWith('.mp4'))
          .map((item) => 'https://storage.googleapis.com/$bucketName/${item.name}')
          .toList();

      setState(() {
        videoUrls = urls;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching videos: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<StorageApi> _getStorageClient() async {
    final user = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (user == null) throw Exception('User not signed in');

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) throw Exception('Failed to get authenticated client');

    return StorageApi(authClient);
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoUrls.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (context, index) {
          return VideoItem(
            videoUrl: videoUrls[index],
            isCurrent: index == _currentPage,
          );
        },
      ),
    );
  }
}

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final bool isCurrent;

  VideoItem({required this.videoUrl, required this.isCurrent});

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
      allowFullScreen: false,
    );

    if (!widget.isCurrent) {
      _videoController.pause();
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_videoController.value.isPlaying) {
      _videoController.play();
    } else if (!widget.isCurrent && _videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
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
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@username',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Video Description',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}