import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_video_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Short Video Feed',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.green.shade900,
        fontFamily: 'Poppins',
      ),
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  Future<void> _initVideos() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          videos = [];
        });
        return;
      }

      final List<Map<String, dynamic>> videoData = [];

      for (var doc in querySnapshot.docs) {
        try {
          bool isLiked = false;
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final likeDoc = await FirebaseFirestore.instance
                .collection('videos')
                .doc(doc.id)
                .collection('likes')
                .doc(currentUser.uid)
                .get();
            isLiked = likeDoc.exists;
          }

          final likesSnapshot = await FirebaseFirestore.instance
              .collection('videos')
              .doc(doc.id)
              .collection('likes')
              .get();

          videoData.add({
            'url': doc['videoUrl'] as String,
            'title': doc['title'] as String,
            'description': doc['description'] as String,
            'username': doc['username'] ?? 'Unknown',
            'videoId': doc.id,
            'isLiked': isLiked,
            'likeCount': likesSnapshot.size,
          });
        } catch (e) {
          print('Error processing video ${doc.id}: $e');
        }
      }

      setState(() {
        videos = videoData;
        _hasError = false;
      });
    } catch (e) {
      print('Error fetching videos: $e');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVideos() async {
    setState(() {
      _isLoading = true;
    });
    await _initVideos();
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
        title: Text('Short Video Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadVideoScreen()),
              ).then((_) => _refreshVideos());
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshVideos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading videos', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshVideos,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : videos.isEmpty
          ? Center(child: Text('No videos available', style: TextStyle(color: Colors.white70)))
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoItem(
            key: ValueKey(videos[index]['videoId']),
            videoUrl: videos[index]['url']!,
            title: videos[index]['title']!,
            description: videos[index]['description']!,
            username: videos[index]['username']!,
            videoId: videos[index]['videoId']!,
            isLiked: videos[index]['isLiked'] ?? false,
            likeCount: videos[index]['likeCount'] ?? 0,
            onLikeChanged: (bool isLiked, int newCount) {
              setState(() {
                videos[index]['isLiked'] = isLiked;
                videos[index]['likeCount'] = newCount;
              });
            },
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
  final String videoId;
  final bool isLiked;
  final int likeCount;
  final Function(bool, int) onLikeChanged;

  VideoItem({
    required Key key,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.username,
    required this.videoId,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeChanged,
  }) : super(key: key);

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late bool _isLiked;
  late int _likeCount;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.videoUrl)
        ..addListener(() {
          if (_videoController.value.hasError) {
            setState(() {
              _hasError = true;
            });
          }
        });

      await _videoController.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        showControls: true,
        allowFullScreen: true,
        aspectRatio: _videoController.value.aspectRatio, // Dynamic aspect ratio
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 50),
                SizedBox(height: 10),
                Text(
                  'Error loading video',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _retryVideo,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isVideoInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _isVideoInitialized = false;
        _hasError = true;
      });
    }
  }

  Future<void> _retryVideo() async {
    setState(() {
      _isVideoInitialized = false;
      _hasError = false;
    });
    await _initializeVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeVideo();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _shareVideo() {
    Share.share('Check out this video: ${widget.title}\n${widget.videoUrl}');
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentSection(videoId: widget.videoId);
      },
    );
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to like videos')),
      );
      return;
    }

    final likeRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoId)
        .collection('likes')
        .doc(currentUser.uid);

    try {
      if (_isLiked) {
        await likeRef.delete();
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await likeRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': currentUser.uid,
        });
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
      widget.onLikeChanged(_isLiked, _likeCount);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text(
              'Error loading video',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryVideo,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _chewieController == null) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Video Container with dynamic aspect ratio
        Container(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio, // Dynamic aspect ratio
              child: GestureDetector(
                onTap: () {
                  if (_videoController.value.isPlaying) {
                    _videoController.pause();
                  } else {
                    _videoController.play();
                  }
                },
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),

        // Video info
        Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${widget.username}',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Text(widget.title,
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              SizedBox(height: 5),
              Text(widget.description,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),

        // Like, Share, and Comment buttons
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: _toggleLike,
              ),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.comment, color: Colors.white),
                onPressed: () => _showComments(context),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: _shareVideo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentSection extends StatefulWidget {
  final String videoId;

  const CommentSection({required this.videoId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment(String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    if (text.trim().isEmpty) return;

    try {
      final commentRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add({
        'text': text,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('videos')
                  .doc(widget.videoId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No comments yet.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final commentDoc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(commentDoc['text']),
                      subtitle: Text('User ${commentDoc['userId']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.reply),
                        onPressed: () {
                          // Handle replying to comment
                          print("Replying to ${commentDoc['text']}");
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Add a comment',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (text) {
              _addComment(text);
            },
          ),
        ],
      ),
    );
  }
}
