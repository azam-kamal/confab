import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confab/helper/authenticate.dart';
import 'package:confab/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'chatrooms.dart';

class ImagePickScreen extends StatefulWidget {
  const ImagePickScreen({Key key}) : super(key: key);

  @override
  _ImagePickScreenState createState() => _ImagePickScreenState();
}

class _ImagePickScreenState extends State<ImagePickScreen> {
//Firestore Code (Raza Bhai)

  bool isLoading = false;

  Future<void> updateImage(String dpURL) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid)
        .update({'profilePhoto': dpURL});
  }

//Firestorage Code
  Future uploadFile() async {
    setState(() {
      isLoading = true;
    });

    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('profilePictures/${Path.basename(_image.path)}}');
    UploadTask uploadTask = storageReference.putFile(_image);
    await uploadTask;
    print('File Uploaded');
    storageReference.getDownloadURL().then((fileURL) {
      updateImage(fileURL);
      print('file URL :' + fileURL);
      setState(() {
        _uploadedFileURL = fileURL;
        isLoading = false;
      });
    });
  }

// Image Picker
//  List<File> _images = [];
  File _image;
  String _uploadedFileURL;
  Future getImage(bool gallery) async {
    ImagePicker picker = ImagePicker();
    PickedFile pickedFile;
    // Let user select photo from gallery
    if (gallery) {
      pickedFile = await picker.getImage(
        source: ImageSource.gallery,
      );
    }
    // Otherwise open camera to get new photo
    else {
      pickedFile = await picker.getImage(
        source: ImageSource.camera,
      );
    }

    setState(() {
      if (pickedFile != null) {
        // _images.add(File(pickedFile.path)); multi file
        _image = File(pickedFile.path); // Use if you only need a single picture
      } else {
        print('No image selected.');
      }
    });
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
            Text('Select Profile Photo'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.image_search, size: 20),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              AuthService().signOut();
              await Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Authenticate()));
            },
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.exit_to_app)),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await uploadFile();
          // Add your onPressed code here!
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ChatRoom()));
        },
        label: Text('Done'),
        icon: Icon(Icons.done),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProfileAvatar(
                    '',
                    child: _image != null
                        ? FittedBox(child: Image.file(_image), fit: BoxFit.fill)
                        : Icon(Icons.person, size: 60),
                    borderColor: Colors.blueAccent,
                    borderWidth: 7,
                    elevation: 5,
                    radius: 100,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RawMaterialButton(
                        fillColor: Theme.of(context).accentColor,
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                        ),
                        elevation: 8,
                        onPressed: () {
                          getImage(true);
                        },
                        padding: EdgeInsets.all(15),
                        shape: CircleBorder(),
                      ),
                      RawMaterialButton(
                        fillColor: Theme.of(context).accentColor,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                        elevation: 8,
                        onPressed: () {
                          getImage(false);
                        },
                        padding: EdgeInsets.all(15),
                        shape: CircleBorder(),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
