import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final String image;

  ImageViewer(this.image);
  // const ImageViewer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
              child: Container(
         // margin: EdgeInsets.all(20),
          child: CachedNetworkImage(
            placeholder: (context, url) => CircularProgressIndicator(),
            imageUrl: image,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.arrow_back_ios,
          size: 30,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
