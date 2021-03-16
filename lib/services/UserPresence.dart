import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class UserPresence {
  static final _app = Firebase.app();
  static final FirebaseDatabase _db = FirebaseDatabase(
    app: _app,
    databaseURL: 'https://confab-65022-default-rtdb.firebaseio.com/',
  );
  static rtdbAndLocalFsPresence(bool login, uid) async {
    // All the refs required for updation
    //var uid = await (FirebaseAuth.instance.currentUser.uid);
    if (login == true && uid != null) {
      var userStatusDatabaseRef = _db.reference().child('/users/' + uid);
      var userStatusFirestoreRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      var isOfflineForDatabase = {
        "state": 'offline',
        "last_changed": ServerValue.timestamp,
      };

      var isOnlineForDatabase = {
        "state": 'online',
        "last_changed": ServerValue.timestamp,
      };

      // Firestore uses a different server timestamp value, so we'll
      // create two more constants for Firestore state.
      var isOfflineForFirestore = {
        "state": 'offline',
        "last_changed": FieldValue.serverTimestamp(),
      };

      var isOnlineForFirestore = {
        "state": 'online',
        "last_changed": FieldValue.serverTimestamp(),
      };

      _db
          .reference()
          .child('.info/connected')
          .onValue
          .listen((Event event) async {
        if (event.snapshot.value == false) {
          FirebaseDatabase.instance.reference().keepSynced(false);
          // Instead of simply returning, we'll also set Firestore's state
          // to 'offline'. This ensures that our Firestore cache is aware
          // of the switch to 'offline.'
          userStatusFirestoreRef.update(isOfflineForFirestore);
          return;
        }
        //  FirebaseDatabase.instance.reference().keepSynced(true);
        await userStatusDatabaseRef
            .onDisconnect()
            .update(isOfflineForDatabase)
            .then((snap) {
          userStatusDatabaseRef.set(isOnlineForDatabase);

          // We'll also add Firestore set here for when we come online.
          userStatusFirestoreRef.update(isOnlineForFirestore);
        });
      });
    } else if (login == false) {
      var isOfflineForFirestore = {
        "state": 'offline',
        "last_changed": FieldValue.serverTimestamp(),
      };

      FirebaseDatabase.instance.reference().keepSynced(false);
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(isOfflineForFirestore);
      return;
    }
  }
}
