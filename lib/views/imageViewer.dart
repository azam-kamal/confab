import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final String image;

  ImageViewer(this.image);
  // const ImageViewer({Key key}) : super(key: key);

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
            Text('Image'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.image, size: 20),
          ],
        ),
      ),
      body: Container(
        // margin: EdgeInsets.all(20),
        child: CachedNetworkImage(
          placeholder: (context, url) => CircularProgressIndicator(),
          imageUrl: image,
        ),
      ),
    );
  }
}
