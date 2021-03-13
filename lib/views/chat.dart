import 'dart:async';
import 'dart:io';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail_generator/video_thumbnail_generator.dart';
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

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String profilePhoto;

  Chat({this.chatRoomId, this.userName, this.profilePhoto});
  @override
  _ChatState createState() => _ChatState();
}

String roomId;

class _ChatState extends State<Chat> {
  Stream<QuerySnapshot> chats;

  TextEditingController messageEditingController = new TextEditingController();
  ScrollController _scrollController = ScrollController();
  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  bool isLoading = false;
  bool sc = false;
  Widget chatMessages() {
    return StreamBuilder(
      stream: chats,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                //reverse: true,
                //controller: _scrollController,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  if (snapshot.data.docs[index].data()["attachment"] != null) {
                    if (snapshot.data.docs[index].data()["type"] == 'image') {
                      return MessageTile(
                          attachment: InkWell(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ImageViewer(snapshot
                                        .data.docs[index]
                                        .data()["attachment"]))),
                            child: CachedNetworkImage(
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              imageUrl: snapshot.data.docs[index]
                                  .data()["attachment"],
                            ),
                          ),
                          sendByMe: Constants.myName ==
                              snapshot.data.docs[index].data()["sendBy"],
                          chatTime:
                              snapshot.data.docs[index].data()["chatTime"]);
                    } else if (snapshot.data.docs[index].data()["type"] ==
                        'video') {
                      return MessageTile(
                          attachment: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => VideoViewer(snapshot
                                          .data.docs[index]
                                          .data()["attachment"])));
                            },
                            child: Stack(
                              children: [
                                Positioned(
                                  child: ThumbnailImage(
                                    videoUrl: snapshot.data.docs[index]
                                        .data()["attachment"],
                                    width: 250,
                                    height: 150,
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
                              snapshot.data.docs[index].data()["sendBy"],
                          chatTime:
                              snapshot.data.docs[index].data()["chatTime"]);
                    } else if (snapshot.data.docs[index].data()["type"] ==
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
                                  onPressed: () => download(
                                          snapshot.data.docs[index]
                                              .data["attachment"],
                                          DateFormat('ddmmyy')
                                              .format(DateTime.now())
                                              .toString())
                                      .then((value) => InfoBgAlertBox(
                                          context: context,
                                          title: 'Download',
                                          buttonText: 'Ok',
                                          infoMessage:
                                              'File has being downloaded into download directory'))),
                              Text('File',
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          ),
                          sendByMe: Constants.myName ==
                              snapshot.data.docs[index].data()["sendBy"],
                          chatTime:
                              snapshot.data.docs[index].data()["chatTime"]);
                    }
                  } else {
                    return MessageTile(
                        message: snapshot.data.docs[index].data()["message"],
                        sendByMe: Constants.myName ==
                            snapshot.data.docs[index].data()["sendBy"],
                        chatTime: snapshot.data.docs[index].data()["chatTime"]);
                  }
                  // _scrollToBottom();
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
  void initState() {
    roomId = widget.chatRoomId;
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });
    super.initState();
  }
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

//Firestorage Code
  Future uploadFileOnStorage(String fileType) async {
    setState(() {
      isLoading = true;
    });

    Reference storageReference =
        FirebaseStorage.instance.ref().child('chatAttachments/${(file)}}');
    //.child('profilePictures/${Path.basename(_image.path)}}');
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
      });
    });
  }

  ///
//Attachment Code:

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
    // _scrollController.animateTo(
    //   _scrollController.position.maxScrollExtent,
    //   curve: Curves.easeOut,
    //   duration: const Duration(milliseconds: 500),
    // );
    String userNameUpdated =
        widget.userName[0].toUpperCase() + widget.userName.substring(1);
    String titleText = userNameUpdated;
    // WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
            Text(titleText == null ? 'Confab' : titleText),
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
                        showAttachmentBottomSheet(context);
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
                              borderRadius: BorderRadius.circular(40)),
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_sharp)),
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
