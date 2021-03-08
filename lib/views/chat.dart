import 'dart:async';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import '../widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class Chat extends StatefulWidget {
  final String chatRoomId;
  final String userName;
  final String profilePhoto;

  Chat({this.chatRoomId, this.userName, this.profilePhoto});
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  Stream<QuerySnapshot> chats;

  TextEditingController messageEditingController = new TextEditingController();
  ScrollController _scrollController = ScrollController();

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
                  return MessageTile(
                    message: snapshot.data.documents[index].data["message"],
                    sendByMe: Constants.myName ==
                        snapshot.data.documents[index].data["sendBy"],
                  );
                })
            : Container();
            
      },
    );
  }

  addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Constants.myName,
        "message": messageEditingController.text,
        'time': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  @override
  void initState() {
    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.profilePhoto);
    Timer(
      Duration(milliseconds: 100),
      () =>
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent),
    );
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
              child: widget.profilePhoto != null
                  ? FittedBox(
                      child: Image.network(widget.profilePhoto),
                      fit: BoxFit.fill)
                  : Icon(Icons.person, size: 50),
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
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

  MessageTile({@required this.message, @required this.sendByMe});

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
          // gradient: LinearGradient(
          //   colors: sendByMe
          //       ? [const Color(0xff007EF4), const Color(0xff2A75BC)]
          //       : [const Color(0x1AFFFFFF), const Color(0x1AFFFFFF)],
          // )
          color: sendByMe ? Colors.blue : Colors.green,
        ),
        child: Text(message,
            textAlign: TextAlign.start,
            style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontFamily: 'OverpassRegular',
                fontWeight: FontWeight.w300)),
      ),
    );
  }
}
