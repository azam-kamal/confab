import 'allPeopleView.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

import 'chatrooms.dart';

class ProfileView extends StatefulWidget {
  ProfileView({Key key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
        ),
        bottomNavigationBar: ConvexAppBar(
            items: [
              // TabItem(icon: Icons.home, title: 'Home'),
              TabItem(icon: Icons.settings_input_svideo, title: 'Profile'),
              TabItem(icon: Icons.chat_bubble, title: 'Chat'),
              TabItem(icon: Icons.people_sharp, title: 'People'),
              // TabItem(icon: Icons.people, title: 'Profile'),
            ],
            initialActiveIndex: 0, //optional, default as 0
            onTap: (int i) {
              // if (i == 0) {
              //   Navigator.push(context,
              //       MaterialPageRoute(builder: (context) => ChatRoom()));
              if (i == 1) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatRoom()));
                if (i == 2) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AllPeopleView()));
                }
              }
            }),
      ),
    );
  }
}
