import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'firebase_service.dart';

class VideoFeedScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FarmTube"),  backgroundColor: Colors.green[700],),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getVideos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var videos = snapshot.data!.docs;
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              var video = videos[index];
              return VideoCard(video: video);
            },
          );
        },
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final QueryDocumentSnapshot video;
  VideoCard({required this.video});

  @override
  _VideoCardState createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.video['videoUrl'])
      ..initialize().then((_) {
        setState(() {});
      });
    _chewieController = ChewieController(videoPlayerController: _videoController, autoPlay: false, looping: true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          _videoController.value.isInitialized
              ? Chewie(controller: _chewieController)
              : Center(child: CircularProgressIndicator()),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.video['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up),
                      onPressed: () => _firebaseService.likeVideo(widget.video.id),
                    ),
                    Text("${widget.video['likes']} Likes"),
                  ],
                ),
                Text("Comments:"),
                ...List.generate(widget.video['comments'].length, (i) => Text("- ${widget.video['comments'][i]}")),
                TextField(
                  onSubmitted: (comment) => _firebaseService.addComment(widget.video.id, comment),
                  decoration: InputDecoration(labelText: "Add a comment"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
