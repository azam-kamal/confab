import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseMethods {
  // Future<void> addUserInfo(userData) async {
  //   Firestore.instance.collection("users").add(userData).catchError((e) {
  //     print(e.toString());
  //   });
  // }

  Future<void> addUserInfo(userData) async {
    await Firestore.instance
        .collection("users")
        .document((await FirebaseAuth.instance.currentUser()).uid)
        .setData(userData)
        .catchError((e) {
      print(e.toString());
    });
  }

  Future<void> getProfilePhoto(String userName) async {
    // await Firestore.instance
    //     .collection('users')
    //     .document((await FirebaseAuth.instance.currentUser()).uid)
    //     .get().;
    
  }

  getUserInfo(String email) async {
    return Firestore.instance
        .collection("users")
        .where("userEmail", isEqualTo: email)
        .getDocuments()
        .catchError((e) {
      print(e.toString());
    });
  }

  searchByName(String searchField) {
    return Firestore.instance
        .collection("users")
        .where('userName', isEqualTo: searchField)
        .getDocuments();
  }

  Future<bool> addChatRoom(chatRoom, chatRoomId) {
    Firestore.instance
        .collection("chatRoom")
        .document(chatRoomId)
        .setData(chatRoom)
        .catchError((e) {
      print(e);
    });
  }

  getChats(String chatRoomId) async {
    return Firestore.instance
        .collection("chatRoom")
        .document(chatRoomId)
        .collection("chats")
        .orderBy('time')
        .snapshots();
  }

  Future<void> addMessage(String chatRoomId, chatMessageData) {
    Firestore.instance
        .collection("chatRoom")
        .document(chatRoomId)
        .collection("chats")
        .add(chatMessageData)
        .catchError((e) {
      print(e.toString());
    });
  }

  //2
  // Future<void> addMessage(String chatRoomId, chatMessageData) async {
  //   Firestore.instance
  //       .collection("chatRoom")
  //       .document(chatRoomId)
  //       .collection("chats").document((await FirebaseAuth.instance.currentUser()).uid).setData(chatMessageData)
  //       .catchError((e) {
  //     print(e.toString());
  //   });
  // }
  

  getUserChats(String itIsMyName) async {
    return await Firestore.instance
        .collection("chatRoom")
        .where('users', arrayContains: itIsMyName)
        .snapshots();
  }
}
