import 'package:cached_network_image/cached_network_image.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confab/helper/constants.dart';
import 'package:confab/services/UserPresence.dart';
import 'package:confab/services/database.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'chat.dart';
import 'chatrooms.dart';

class AllPeopleView extends StatefulWidget {
  AllPeopleView({Key key}) : super(key: key);

  @override
  _AllPeopleViewState createState() => _AllPeopleViewState();
}

class _AllPeopleViewState extends State<AllPeopleView>
    with WidgetsBindingObserver {
  DatabaseMethods databaseMethods = new DatabaseMethods();
  //TextEditingController searchEditingController = new TextEditingController();
  QuerySnapshot searchResultSnapshot;

  bool isLoading = false;
  bool haveUserSearched = false;

  allUsers() async {
    await databaseMethods.getAllUser().then((snapshot) {
      searchResultSnapshot = snapshot;
      setState(() {
        isLoading = false;
        haveUserSearched = true;
      });
    });
  }

  Widget userList() {
    return haveUserSearched
        ? ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: searchResultSnapshot.docs.length,
            itemBuilder: (context, index) {
              return userTile(
                searchResultSnapshot.docs[index].data()["userName"],
                searchResultSnapshot.docs[index].data()["userEmail"],
                searchResultSnapshot.docs[index].data()["profilePhoto"],
              );
            })
        : Container();
  }

  /// 1.create a chatroom, send user to the chatroom, other userdetails
  sendMessage(String userName, String profilePhoto) {
    List<String> users = [Constants.myName, userName];

    String chatRoomId = getChatRoomId(Constants.myName, userName);

    Map<String, dynamic> chatRoom = {
      "users": users,
      "chatRoomId": chatRoomId,
    };

    databaseMethods.addChatRoom(chatRoom, chatRoomId);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Chat(
                  chatRoomId: chatRoomId,
                  userName: userName,
                  profilePhoto: profilePhoto,
                  status: 'offline',
                )));
  }

  Widget userTile(String userName, String userEmail, String profilePhoto) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircularProfileAvatar(
                    '',
                    child: profilePhoto != null
                        ? FittedBox(
                            child: CachedNetworkImage(
                              memCacheHeight: 200,
                              memCacheWidth: 200,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              imageUrl: profilePhoto,
                            ),
                            fit: BoxFit.fill)
                        : Icon(Icons.person, size: 50),
                    borderColor: Colors.blueAccent,
                    borderWidth: 4,
                    elevation: 7,
                    radius: 23,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style:
                            TextStyle(color: Colors.black, fontSize: 14.0.sp),
                        textAlign: TextAlign.start,
                      ),
                      Text(
                        userEmail,
                        style:
                            TextStyle(color: Colors.black, fontSize: 12.0.sp),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              sendMessage(userName, profilePhoto);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(24)),
              child: Text(
                "Message",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
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
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    allUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text('People'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.chat_bubble, size: 20),
          ],
        ),
      ),
      body: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Container(
              child: SingleChildScrollView(
                child: Column(
                  children: [userList()],
                ),
              ),
            ),
      bottomNavigationBar: ConvexAppBar(
          items: [
            // TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.settings_input_svideo, title: 'Profile'),
            TabItem(icon: Icons.chat_bubble, title: 'Chat'),
            TabItem(icon: Icons.people_sharp, title: 'People'),
            // TabItem(icon: Icons.people, title: 'Profile'),
          ],
          initialActiveIndex: 2, //optional, default as 0
          onTap: (int i) {
            if (i == 1) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => ChatRoom()));
            }
          }),
    );
  }
}
