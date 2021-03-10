import 'dart:async';
import 'dart:io';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import '../widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/downloads.dart';
import 'package:intl/intl.dart';

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String profilePhoto;

  Chat({this.chatRoomId, this.userName, this.profilePhoto});
  @override
  _ChatState createState() => _ChatState();
}

String roomId;

//Download progressbar widget
String _progress = "-";
Widget progressBar() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Download progress:',
        ),
        Text(
          '$_progress',
        ),
      ],
    ),
  );
}

class _ChatState extends State<Chat> {
  Stream<QuerySnapshot> chats;

  TextEditingController messageEditingController = new TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  Widget chatMessages() {
    //   final items = List<String>.generate(50, (i) => "Item $i");
    return StreamBuilder(
      stream: chats,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                //reverse: true,
                controller: _scrollController,
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  if (snapshot.data.documents[index].data["attachment"] !=
                      null) {
                    if (snapshot.data.documents[index].data["type"] ==
                        'image') {
                      return MessageTile(
                          attachment: Image.network(snapshot
                              .data.documents[index].data["attachment"]),
                          sendByMe: Constants.myName ==
                              snapshot.data.documents[index].data["sendBy"],
                          chatTime:
                              snapshot.data.documents[index].data["chatTime"]);
                    } else if (snapshot.data.documents[index].data["type"] ==
                        'video') {
                      return MessageTile(
                          attachment: IconButton(
                              icon: Icon(Icons.play_arrow),
                              iconSize: 40,
                              onPressed: () => download(
                                  snapshot
                                      .data.documents[index].data["attachment"],
                                  DateFormat('ddmmyy')
                                      .format(DateTime.now())
                                      .toString())),
                          sendByMe: Constants.myName ==
                              snapshot.data.documents[index].data["sendBy"],
                          chatTime:
                              snapshot.data.documents[index].data["chatTime"]);
                    } else if (snapshot.data.documents[index].data["type"] ==
                        'other') {
                      return MessageTile(
                          attachment: IconButton(
                              icon: Icon(Icons.file_copy),
                              iconSize: 40,
                              onPressed: () => download(
                                  snapshot
                                      .data.documents[index].data["attachment"],
                                  DateFormat('ddmmyy')
                                      .format(DateTime.now())
                                      .toString())),
                          sendByMe: Constants.myName ==
                              snapshot.data.documents[index].data["sendBy"],
                          chatTime:
                              snapshot.data.documents[index].data["chatTime"]);
                    }
                    // return MessageTile(
                    //     attachment:
                    //         snapshot.data.documents[index].data["attachment"],
                    //     sendByMe: Constants.myName ==
                    //         snapshot.data.documents[index].data["sendBy"],
                    //     chatTime: snapshot.data.documents[index].data["time"]);
                  } else {
                    return MessageTile(
                        message: snapshot.data.documents[index].data["message"],
                        sendByMe: Constants.myName ==
                            snapshot.data.documents[index].data["sendBy"],
                        chatTime:
                            snapshot.data.documents[index].data["chatTime"]);
                  }
                })
            : Container();
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
    Get.snackbar('', 'Sending attachment..');
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
      'pptx'
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

    StorageReference storageReference =
        FirebaseStorage.instance.ref().child('chatAttachments/${(file)}}');
    //.child('profilePictures/${Path.basename(_image.path)}}');
    StorageUploadTask uploadTask = storageReference.putFile(file);
    await uploadTask.onComplete;
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

  // Downloading Progress
  void _onReceiveProgress(int received, int total) {
    if (total != -1) {
      setState(() {
        _progress = (received / total * 100).toStringAsFixed(0) + "%";
      });
    }
  }

//File Code --- /////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    print(widget.profilePhoto);
    Timer(Duration(milliseconds: 1000), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      print(widget.profilePhoto);
    });
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
                      child: Image.network(widget.profilePhoto),
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
          top: 8, bottom: 8, left: sendByMe ? 0 : 24, right: sendByMe ? 24 : 0),
      alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:
            sendByMe ? EdgeInsets.only(left: 30) : EdgeInsets.only(right: 30),
        padding: EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
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
          color: sendByMe ? Colors.blue : Colors.green,
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
      ),
    );
  }
}
