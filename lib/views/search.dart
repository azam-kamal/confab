import 'package:cached_network_image/cached_network_image.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:confab/helper/authenticate.dart';
import 'package:confab/services/UserPresence.dart';
import 'package:confab/services/auth.dart';
import 'package:confab/views/allPeopleView.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';
import '../helper/constants.dart';
import '../services/database.dart';
import '../views/chat.dart';
import '../widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'chatrooms.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with WidgetsBindingObserver {
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController searchEditingController = new TextEditingController();
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

  initiateSearch() async {
    if (searchEditingController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await databaseMethods
          .searchByName(searchEditingController.text)
          .then((snapshot) {
        searchResultSnapshot = snapshot;
        print("$searchResultSnapshot");
        setState(() {
          isLoading = false;
          haveUserSearched = true;
        });
      });
    }
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
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    allUsers();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    searchEditingController.dispose();
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
            Text('Chats'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Icon(Icons.chat_bubble, size: 20),
          ],
        ),
        actions: [
          // GestureDetector(
          //   onTap: () async {
          //     AuthService().signOut();
          //     await Navigator.pushReplacement(context,
          //         MaterialPageRoute(builder: (context) => Authenticate()));
          //   },
          //   child: Container(
          //       padding: EdgeInsets.symmetric(horizontal: 16),
          //       child: Icon(Icons.exit_to_app)),
          // )
        ],
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
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 8, left: 5, right: 5),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.blue[400],
                          borderRadius: BorderRadius.circular(60)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchEditingController,
                              style: simpleTextStyle(),
                              decoration: InputDecoration(
                                hintText: 'search user',
                                hintStyle: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 20,
                                ),
                                // border: InputBorder.none
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              initiateSearch();
                            },
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                        const Color(0x36FFFFFF),
                                        const Color(0x0FFFFFFF)
                                      ],
                                      begin: FractionalOffset.topLeft,
                                      end: FractionalOffset.bottomRight),
                                  borderRadius: BorderRadius.circular(40)),
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.search_sharp,
                                color: Colors.white,
                              ),
                              // Image.asset(
                              //   "assets/images/search_white.png",
                              //   height: 25,
                              //   width: 25,
                              // )
                            ),
                          )
                        ],
                      ),
                    ),
                    userList()
                  ],
                ),
              ),
            ),
    );
  }
}
