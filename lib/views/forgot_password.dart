import 'package:confab/services/UserPresence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword>
    with WidgetsBindingObserver {
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Coming Soon'),
    );
  }
}
