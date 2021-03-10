import 'package:cached_network_image/cached_network_image.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confab/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/authenticate.dart';
import '../helper/constants.dart';
import '../helper/helperfunctions.dart';
import '../helper/theme.dart';
import '../services/auth.dart';
import '../services/database.dart';
import '../views/chat.dart';
import '../views/search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  Stream chatRooms;
  Stream collectionStream = Firestore.instance.collection('users').snapshots();
  String photoURL;
  bool isLoading = true;
  List chats = [];
  List otherUsers = [];
  List<String> otherUserNames = [];
 
  @override
  void initState() {
    getUsers();
    getUserInfogetChats();
    super.initState();
  }

  void getUsers() async {
    isLoading = true;
    setState(() {});
    var myUserName = await HelperFunctions.getUserNameSharedPreference();
    chats = (await Firestore.instance
            .collection('chatRoom')
            .where('users', arrayContains: myUserName)
            .getDocuments())
        .documents
        .map((e) => e.data)
        .toList();

    chats.forEach((chat) {
      chat['users'].forEach((userName) {
        if (userName != myUserName) {
          otherUserNames.add(userName);
        }
      });
    });
    for (int i = 0; i < otherUserNames.length; i++) {
      otherUsers.add(((await Firestore.instance
              .collection('users')
              .where('userName', isEqualTo: otherUserNames[i])
              .limit(1)
              .getDocuments())
          .documents[0]));
    }
    isLoading = false;
    setState(() {});
  }

  Widget chatRoomsList() {
    return !isLoading && chats.length > 0
        ? ListView.builder(
            itemCount: chats.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var chat = chats[index];
              var userName = otherUserNames[index];
              var otherUser = otherUsers[index];
              return ChatRoomsTile(
                  userName: userName,
                  chatRoomId: chat["chatRoomId"],
                  profilePhoto: otherUser['profilePhoto']);
            })
        : Container();
  }

  getUserInfogetChats() async {
    Constants.myName = await HelperFunctions.getUserNameSharedPreference();
    DatabaseMethods().getUserChats(Constants.myName).then((snapshots) {
      setState(() {
        chatRooms = snapshots;
        print(
            "we got the data + ${chatRooms.toString()} this is name  ${Constants.myName}");
      });
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
            Text('Chats'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.chat_bubble, size: 20),
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
      body: Container(
        child: chatRoomsList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          size: 30,
        ),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Search()));
        },
      ),
    );
  }
}

class ChatRoomsTile extends StatelessWidget {
  final String userName;
  final String chatRoomId;
  final String profilePhoto;

  ChatRoomsTile(
      {this.userName, @required this.chatRoomId, @required this.profilePhoto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                    chatRoomId: chatRoomId,
                    userName: userName,
                    profilePhoto: profilePhoto)));
      },
      child: Container(
          color: Colors.blue[50],
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ListTile(
            leading: CircularProfileAvatar(
              '',
              child: profilePhoto != null
                  ? FittedBox(
                      child: CachedNetworkImage(
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                imageUrl: profilePhoto,
                              ),
                      fit: BoxFit.fill,
                    )
                  : Icon(Icons.person, size: 20),
              borderColor: Colors.blueAccent,
              borderWidth: 4,
              elevation: 7,
              radius: 25,
            ),
            title: Text(userName[0].toUpperCase() + userName.substring(1),
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'OverpassRegular',
                    fontWeight: FontWeight.w400)),
          )),
    );
  }
}
