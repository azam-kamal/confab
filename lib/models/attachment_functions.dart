import 'package:flutter/foundation.dart';
// ignore: unused_import
import 'package:provider/provider.dart';

class Attachment with ChangeNotifier {
  String file;
  Attachment({this.file});

  String get fileData {
    return file;
  }

  notifyListeners();
}

// class AttachmentItem with ChangeNotifier {
//   final file;

//   UsersItem({@required this.file});
// }

// class Users with ChangeNotifier {
//   List<AttachmentItem> _items = [];

//   List<AttachmentItem> get items {
//     return [..._items];
//   }

  // void addFileItem(AttachmentItem filee) async {
  //   final newFile = AttachmentItem(
  //     file: filee.file,
  //   );

  //   _items.add(newUser);
  //   notifyListeners();
  // }

  // void addUserName(String name) async {
  //   final newUser = UsersItem(
  //     secondUser: name,
  //   );

//     _items.add(newUser);
//     notifyListeners();
//   }

//   void deleteUsers() {
//     _items = [];
//   }
 //}

class User {
  final String uid;
  User({this.uid});
}
