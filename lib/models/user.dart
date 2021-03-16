import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:provider/provider.dart';

class UserName with ChangeNotifier {
  String secondUser;
  UserName({this.secondUser});

  String get chatterName {
    return secondUser;
  }

  notifyListeners();
}

class UsersItem with ChangeNotifier {
  final secondUser;

  UsersItem({@required this.secondUser});
}

class Users with ChangeNotifier {
  List<UsersItem> _items = [];

  List<UsersItem> get items {
    return [..._items];
  }

  void addUserItem(UsersItem userr) async {
    final newUser = UsersItem(
      secondUser: userr.secondUser,
    );

    _items.add(newUser);
    notifyListeners();
  }

  void addUserName(String name) async {
    final newUser = UsersItem(
      secondUser: name,
    );

    _items.add(newUser);
    notifyListeners();
  }

  void deleteUsers() {
    _items = [];
  }
}

class Userr {
  final String uid;
  Userr({this.uid});
}

class Video {
  String link;
  Video({this.link});
}

class UserData {
  final String uid;
  UserData({this.uid});
}
