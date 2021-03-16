import 'package:cached_network_image/cached_network_image.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/UserPresence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrink_sidemenu/shrink_sidemenu.dart';
import '../helper/authenticate.dart';
import '../helper/constants.dart';
import '../helper/helperfunctions.dart';
import '../services/auth.dart';
import '../services/database.dart';
import '../views/chat.dart';
import '../views/search.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:liquid_ui/liquid_ui.dart';
import 'package:intl/intl.dart';
import 'allPeopleView.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

var myName;
var myProfilePhoto;

class _ChatRoomState extends State<ChatRoom> {
  Stream chatRooms;
  Stream collectionStream =
      FirebaseFirestore.instance.collection('users').snapshots();
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
    myProfilePhoto = await HelperFunctions.getUserProfileSharedPreference();

    myName = myUserName[0].toUpperCase() + myUserName.substring(1);
    chats = (await FirebaseFirestore.instance
            .collection('chatRoom')
            .where('users', arrayContains: myUserName)
            .get())
        .docs
        .map((e) => e.data())
        .toList();

    chats.forEach((chat) {
      chat['users'].forEach((userName) {
        if (userName != myUserName) {
          otherUserNames.add(userName);
        }
      });
    });
    for (int i = 0; i < otherUserNames.length; i++) {
      otherUsers.add(((await FirebaseFirestore.instance
              .collection('users')
              .where('userName', isEqualTo: otherUserNames[i])
              .limit(1)
              .get())
          .docs[0]));
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
                profilePhoto: otherUser['profilePhoto'],
                userStatus: otherUser['state'],
                lastChanged: otherUser['last_changed'],
              );
            })
        : Center(child: CircularProgressIndicator());
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

  final GlobalKey<SideMenuState> _sideMenuKey = GlobalKey<SideMenuState>();
  @override
  Widget build(BuildContext context) {
    return SideMenu(
      key: _sideMenuKey,
      background: Colors.blue[900],
      menu: buildMenu(context),
      type: SideMenuType.slide, // check above images
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              final _state = _sideMenuKey.currentState;
              if (_state.isOpened)
                _state.closeSideMenu(); // close side menu
              else
                _state.openSideMenu(); // open side menu
            },
          ),
          title: Row(
            children: [
              Text('Chat'),
              SizedBox(width: MediaQuery.of(context).size.width * 0.01),
              Icon(Icons.chat_bubble, size: 20),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Search()));
              },
            )
          ],
        ),
        body: Container(
          child: chatRoomsList(),
        ),
        bottomNavigationBar: ConvexAppBar(
            items: [
              // TabItem(icon: Icons.home, title: 'Home'),
              TabItem(icon: Icons.settings_input_svideo, title: 'Profile'),
              TabItem(icon: Icons.chat_bubble, title: 'Chat'),
              TabItem(icon: Icons.people_sharp, title: 'People'),
              // TabItem(icon: Icons.people, title: 'Profile'),
            ],
            initialActiveIndex: 1, //optional, default as 0
            onTap: (int i) {
              if (i == 2) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllPeopleView()));
              }
            }),
      ),
    );
  }
}

class ChatRoomsTile extends StatelessWidget {
  final String userName;
  final String chatRoomId;
  final String profilePhoto;
  final String userStatus;
  final lastChanged;

  ChatRoomsTile(
      {this.userName,
      @required this.chatRoomId,
      @required this.profilePhoto,
      this.userStatus,
      this.lastChanged});
  String status;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (userStatus == 'offline') {
          // String formattedDate =
          //     DateFormat('dd MMMM-kk:mm').format(lastChanged);
          // status = formattedDate;
          status = 'offline';
        } 
        if(userStatus==null){
          status = 'offline';
        }
        if(userStatus=='online'){
          status = 'online';
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                    chatRoomId: chatRoomId,
                    userName: userName,
                    profilePhoto: profilePhoto,
                    status: status)));
      },
      child: Container(
          //  color: Colors.blue[50],
          //padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: EdgeInsets.only(bottom: 2),
          child: Card(
            elevation: 1,
            child: ListTile(
              leading: CircularProfileAvatar(
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
            ),
          )),
    );
  }
}

//SideDrawer
Widget buildMenu(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 50.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularProfileAvatar(
                '',
                child: myProfilePhoto != null
                    ? FittedBox(
                        child: CachedNetworkImage(
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          imageUrl: myProfilePhoto,
                        ),
                        fit: BoxFit.fill,
                      )
                    : Icon(Icons.person, size: 20),
                borderColor: Colors.blueAccent,
                borderWidth: 4,
                elevation: 7,
                radius: 50,
              ),
              SizedBox(height: 16.0),
              LText(
                "\l.lead{Hello},\n\l.lead.bold{$myName :)}",
                baseStyle: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20.0),
              GestureDetector(
                onTap: () async {
                  await UserPresence.rtdbAndLocalFsPresence(
                      false, FirebaseAuth.instance.currentUser.uid);
                  AuthService().signOut();
                  await Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Authenticate()));
                },
                child: Container(
                  padding: EdgeInsets.only(left: 5, top: 260),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.05,
                      ),
                      Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
