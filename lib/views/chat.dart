import 'dart:async';
import 'dart:io';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import '../widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/downloads.dart';
import 'package:intl/intl.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'imageViewer.dart';
import 'videoViewer.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../services/UserPresence.dart';
import 'package:flutter_emoji_keyboard/flutter_emoji_keyboard.dart';

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String profilePhoto;
  final String status;

  Chat({this.chatRoomId, this.userName, this.profilePhoto, this.status});
  @override
  _ChatState createState() => _ChatState();
}

String roomId;

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  Stream<QuerySnapshot> chats;
  Stream<QuerySnapshot> status;
  TextEditingController messageEditingController = new TextEditingController();
  void onEmojiSelected(Emoji emoji) {
    messageEditingController.text += emoji.text;
  }

  bool isLoading = false;
  bool sc = false;

  Widget chatMessages() {
    return StreamBuilder(
      stream: chats,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                reverse: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  final reversedIndex = snapshot.data.docs.length - 1 - index;
                  if (snapshot.data.docs[reversedIndex].data()["attachment"] !=
                      null) {
                    if (snapshot.data.docs[reversedIndex].data()["type"] ==
                        'image') {
                      return MessageTile(
                          attachment: InkWell(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ImageViewer(snapshot
                                        .data.docs[reversedIndex]
                                        .data()["attachment"]))),
                            child: CachedNetworkImage(
                              memCacheHeight: 200,
                              memCacheWidth: 200,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              imageUrl: snapshot.data.docs[reversedIndex]
                                  .data()["attachment"],
                            ),
                          ),
                          sendByMe: Constants.myName ==
                              snapshot.data.docs[reversedIndex]
                                  .data()["sendBy"],
                          chatTime: snapshot.data.docs[reversedIndex]
                              .data()["chatTime"]);
                    } else if (snapshot.data.docs[reversedIndex]
                            .data()["type"] ==
                        'video') {
                      return MessageTile(
                          attachment: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => VideoViewer(snapshot
                                          .data.docs[reversedIndex]
                                          .data()["attachment"])));
                            },
                            child: Stack(
                              children: [
                                Positioned(
                                  child: CachedNetworkImage(
                                    memCacheHeight: 200,
                                    memCacheWidth: 200,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    imageUrl: snapshot.data.docs[reversedIndex]
                                        .data()["thumbnail"],
                                  ),
                                ),
                                Positioned(
                                    top: 50,
                                    left: 50,
                                    bottom: 50,
                                    right: 50,
                                    child: Center(
                                        child: Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 100,
                                      color: Colors.blue[300],
                                    ))),
                              ],
                            ),
                          ),
                          sendByMe: Constants.myName ==
                              snapshot.data.docs[reversedIndex]
                                  .data()["sendBy"],
                          chatTime: snapshot.data.docs[reversedIndex]
                              .data()["chatTime"]);
                    } else if (snapshot.data.docs[reversedIndex]
                            .data()["type"] ==
                        'other') {
                      return MessageTile(
                          attachment: Column(
                            children: [
                              IconButton(
                                  icon: Icon(
                                    Icons.file_copy,
                                    color: Colors.white,
                                  ),
                                  iconSize: 40,
                                  onPressed: () async {
                                    EasyLoading.showProgress(0.3,
                                        status: 'downloading...');
                                    await download(
                                            snapshot.data.docs[reversedIndex]
                                                .data()["attachment"],
                                            DateFormat('ddmmyy')
                                                .format(DateTime.now())
                                                .toString())
                                        .then((value) {
                                      EasyLoading.dismiss();
                                      InfoBgAlertBox(
                                          context: context,
                                          title: 'Download',
                                          buttonText: 'Ok',
                                          infoMessage:
                                              'File has being downloaded into download directory');
                                    });
                                  }),
                              Text('File',
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          ),
                          sendByMe: Constants.myName ==
                              snapshot.data.docs[reversedIndex]
                                  .data()["sendBy"],
                          chatTime: snapshot.data.docs[reversedIndex]
                              .data()["chatTime"]);
                    }
                  } else {
                    return MessageTile(
                        message:
                            snapshot.data.docs[reversedIndex].data()["message"],
                        sendByMe: Constants.myName ==
                            snapshot.data.docs[reversedIndex].data()["sendBy"],
                        chatTime: snapshot.data.docs[reversedIndex]
                            .data()["chatTime"]);
                  }
                })
            : CircularProgressIndicator();
      },
    );
  }

  addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd MMMM-kk:mm').format(now);
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'chatTime': formattedDate,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      print(DateFormat.yMMMMd('en_US').add_Hm());
      DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      UserPresence.rtdbAndLocalFsPresence(
          false, FirebaseAuth.instance.currentUser.uid);
      // went to Background
    }
    if (state == AppLifecycleState.resumed) {
      UserPresence.rtdbAndLocalFsPresence(
          true, FirebaseAuth.instance.currentUser.uid);
    }
    if (state == AppLifecycleState.inactive) {
      UserPresence.rtdbAndLocalFsPresence(
          false, FirebaseAuth.instance.currentUser.uid);
    }
  }
  // came back to Foreground

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageEditingController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    roomId = widget.chatRoomId;
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });

    DatabaseMethods().getStatus(widget.userName).then((snapshot) {
      setState(() {
        status = snapshot;
      });
    });

    super.initState();
  }

  String stats;
  String lastSeen;
// File Code/////////////////////////////////////////////

  File file;

  imageAndVideoPicker(FileType fileType, BuildContext ctx) async {
    file = await FilePicker.getFile(type: fileType);
    print(file);
    uploadFileOnStorage(fileType.toString().substring(9));
    Navigator.of(ctx).pop();

    // GradientSnackBar.showMessage(context, 'Sending attachment..');
  }

  pdfAndRarPicker(FileType fileType, BuildContext ctx) async {
    file = await FilePicker.getFile(type: fileType, allowedExtensions: [
      'pdf',
      'svg',
      'doc',
      'docx',
      'rar',
      'xlx',
      'xlxs',
      'ppt',
      'pptx',
      'mp3'
    ]);
    uploadFileOnStorage('other');
    Navigator.of(ctx).pop();
  }

//////////////
  addAttachment(String url, String fileType) {
    if (file != null) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd MMMM-kk:mm').format(now);
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": '',
        'chatTime': formattedDate,
        'time': DateTime.now().millisecondsSinceEpoch,
        'attachment': url,
        'type': fileType
      };
      print(DateFormat.yMMMMd('en_US').add_Hm());
      DatabaseMethods().addMessage(roomId, chatMessageMap);
    }
  }

  addAttachmentVideo(String url, String fileType, String tUrl) {
    if (file != null) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd MMMM-kk:mm').format(now);
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": '',
        'chatTime': formattedDate,
        'time': DateTime.now().millisecondsSinceEpoch,
        'attachment': url,
        'type': fileType,
        'thumbnail': tUrl,
      };
      print(DateFormat.yMMMMd('en_US').add_Hm());
      DatabaseMethods().addMessage(roomId, chatMessageMap);
    }
  }

//Firestorage Code
  Future uploadFileOnStorage(String fileType) async {
    setState(() {
      isLoading = true;
      EasyLoading.show(status: 'Uploading...');
    });
    if (fileType == 'video') {
      final _flutterVideoCompress = FlutterVideoCompress();
      final thumbnailFile =
          await _flutterVideoCompress.getThumbnailWithFile(file.path,
              quality: 50, // default(100)
              position: -1 // default(-1)
              );
      Reference storageReferenceThumbnails =
          FirebaseStorage.instance.ref().child('thumbnails/${(file)}}');
      UploadTask uploadTaskT =
          storageReferenceThumbnails.putFile(thumbnailFile);
      await uploadTaskT;
      print('Thumbnail Uploaded');
      storageReferenceThumbnails.getDownloadURL().then((tURL) async {
        Reference storageReference =
            FirebaseStorage.instance.ref().child('chatAttachments/${(file)}}');
        UploadTask uploadTask = storageReference.putFile(file);
        await uploadTask;
        print('File Uploaded');
        storageReference.getDownloadURL().then((fileURL) {
          //updateFileURL(fileURL);
          addAttachmentVideo(fileURL, fileType, tURL);
          print('file URL :' + fileURL);
          setState(() {
            //  _uploadedFileURL = fileURL;
            isLoading = false;
            EasyLoading.dismiss();
          });
        });
      });
    } else {
      Reference storageReference =
          FirebaseStorage.instance.ref().child('chatAttachments/${(file)}}');
      UploadTask uploadTask = storageReference.putFile(file);
      await uploadTask;
      print('File Uploaded');
      storageReference.getDownloadURL().then((fileURL) {
        //updateFileURL(fileURL);
        addAttachment(fileURL, fileType);
        print('file URL :' + fileURL);
        setState(() {
          //  _uploadedFileURL = fileURL;
          isLoading = false;
          EasyLoading.dismiss();
        });
      });
    }
  }

  ///
//Attachment Code:

  showEmojiBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return EmojiKeyboard(
            onEmojiSelected: onEmojiSelected,
          );
        });
  }

  showAttachmentBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(
                      Icons.image,
                    ),
                    title: Text('Image'),
                    onTap: () => imageAndVideoPicker(FileType.image, context)),
                ListTile(
                    leading: Icon(Icons.videocam),
                    title: Text('Video'),
                    onTap: () => imageAndVideoPicker(FileType.video, context)),
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('File'),
                  onTap: () => pdfAndRarPicker(FileType.custom, context),
                ),
              ],
            ),
          );
        });
  }

//File Code --- /////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    String userNameUpdated =
        widget.userName[0].toUpperCase() + widget.userName.substring(1);
    String titleText = userNameUpdated;

    return Scaffold(
      //appBar: appBarMain(context),
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              Navigator.of(context).pop();
            }),
        title: Row(
          children: [
            CircularProfileAvatar(
              '',
              child: widget.profilePhoto == null
                  ? Icon(Icons.person, size: 20)
                  : FittedBox(
                      child: CachedNetworkImage(
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        imageUrl: widget.profilePhoto,
                      ),
                      fit: BoxFit.fill),
              borderColor: Colors.blueAccent,
              borderWidth: 4,
              elevation: 7,
              radius: 23,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Column(
              children: [
                Text(titleText == null ? 'Confab' : titleText),
                SizedBox(height: MediaQuery.of(context).size.width * 0.01),
                StreamBuilder(
                    stream: status,
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      return snapshot.hasData
                          ? snapshot.data.docs[0].data()["state"] == 'offline'
                              ? Text(
                                  'Last Seen ' +
                                      (DateTime.fromMicrosecondsSinceEpoch(
                                                      snapshot.data.docs[0]
                                                          .data()[
                                                              "last_changed"]
                                                          .microsecondsSinceEpoch)
                                                  .hour
                                                  .toString() +
                                              ":" +
                                              (DateTime.fromMicrosecondsSinceEpoch(
                                                          snapshot.data.docs[0]
                                                              .data()[
                                                                  "last_changed"]
                                                              .microsecondsSinceEpoch)
                                                      .minute)
                                                  .toString())
                                          .toString(),
                                  style: TextStyle(fontSize: 10),
                                )
                              : Text(snapshot.data.docs[0].data()["state"],
                                  style: TextStyle(fontSize: 10))
                          : CircularProgressIndicator();
                    }),
              ],
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Icon(Icons.chat_bubble, size: 20),
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(child: chatMessages()),
            Container(
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: () {
                        showAttachmentBottomSheet(context);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        showEmojiBottomSheet(context);
                      },
                    ),

                    // Icon(Icons.),
                    Expanded(
                        child: TextField(
                      //autofocus: true,
                      controller: messageEditingController,
                      style: simpleTextStyle(),
                      decoration: InputDecoration(
                          hintText: "Message ...",
                          hintStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          border: InputBorder.none),
                    )),
                    SizedBox(
                      width: 16,
                    ),
                    GestureDetector(
                      onTap: () {
                        addMessage();
                      },
                      child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              color: Colors.blue[300],
                              borderRadius: BorderRadius.circular(40)),
                          child: Icon(Icons.arrow_upward_outlined)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final attachment;
  final chatTime;

  MessageTile(
      {this.message,
      @required this.sendByMe,
      @required this.chatTime,
      this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: sendByMe ? 0 : 24,
            right: sendByMe ? 24 : 0),
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: attachment == null
            ? Container(
                margin: sendByMe
                    ? EdgeInsets.only(left: 30)
                    : EdgeInsets.only(right: 30),
                padding:
                    EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
                decoration: BoxDecoration(
                  borderRadius: sendByMe
                      ? BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomLeft: Radius.circular(23))
                      : BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomRight: Radius.circular(23)),
                  color: sendByMe ? Colors.lightBlueAccent : Colors.green,
                ),
                child: Column(
                  children: [
                    message == null
                        ? FittedBox(
                            child: attachment,
                            fit: BoxFit.contain,
                          )
                        : Text(message,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'OverpassRegular',
                                fontWeight: FontWeight.w300)),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(chatTime == null ? '00:00' : chatTime.toString(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontFamily: 'OverpassRegular',
                          //fontWeight: FontWeight.w300
                        )),
                  ],
                ),
              )
            :
            //For Attachment
            Container(
                margin: sendByMe
                    ? EdgeInsets.only(left: 30)
                    : EdgeInsets.only(right: 30),
                padding:
                    EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
                decoration: BoxDecoration(
                  borderRadius: sendByMe
                      ? BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomLeft: Radius.circular(23))
                      : BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                          bottomRight: Radius.circular(23)),
                  color: sendByMe ? Colors.lightBlueAccent : Colors.green,
                ),
                child: Column(
                  children: [
                    message == null
                        ? FittedBox(
                            child: attachment,
                            fit: BoxFit.contain,
                          )
                        : Text(message,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'OverpassRegular',
                                fontWeight: FontWeight.w300)),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(chatTime == null ? '00:00' : chatTime.toString(),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontFamily: 'OverpassRegular',
                          //fontWeight: FontWeight.w300
                        )),
                  ],
                ),
              ));
  }
}
