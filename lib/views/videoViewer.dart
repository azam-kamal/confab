import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  final String videoLink;
  VideoViewer(this.videoLink);

  @override
  _VideoViewerState createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController controller;
  ChewieController chewieController;

  @override
  void initState() {
    controller = VideoPlayerController.network(widget.videoLink);
    chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: true,
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    chewieController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                Navigator.of(context).pop();
              }),
          title: Row(
            children: [
              Text('Video'),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Icon(Icons.play_arrow, size: 20),
            ],
          ),
        ),
        body: SafeArea(
          child: Container(
            child: Chewie(
              controller: chewieController,
            ),
          ),
        ));
  }
}
