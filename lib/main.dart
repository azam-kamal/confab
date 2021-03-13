import 'package:firebase_core/firebase_core.dart';
import 'helper/authenticate.dart';
import 'helper/helperfunctions.dart';
import 'views/chatrooms.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'models/user.dart';

const debug = true;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool userIsLoggedIn;

  @override
  void initState() {
    getLoggedInState();
    super.initState();
  }

  getLoggedInState() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
      setState(() {
        userIsLoggedIn = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      //return LayoutBuilder
      builder: (context, constraints) {
        return OrientationBuilder(
          //return OrientationBuilder
          builder: (context, orientation) {
            //initialize SizerUtil()
            SizerUtil().init(constraints, orientation);
            return MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    // create:(ctx) => Products(),
                    value: Users(),
                  ),
                ],
                child: MaterialApp(
                  title: 'ConFab',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primaryColor: Colors.blue,
                    scaffoldBackgroundColor: Colors.white,
                    //Colors.blue[50],
                    accentColor: Colors.blue,
                    fontFamily: "OverpassRegular",
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                  ),
                  home: userIsLoggedIn != null
                      ? userIsLoggedIn
                          ? ChatRoom()
                          : Authenticate()
                      : Container(
                          child: Center(
                            child: Authenticate(),
                          ),
                        ),
                  //home: ImagePickScreen()
                ));
          },
        );
      },
    );
  }
}
