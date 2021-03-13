import 'package:flutter/material.dart';

Widget appBarMain(BuildContext context) {
  return AppBar(
    title: Text('Confab'),
    elevation: 0.0,
    centerTitle: false,
  );
}

InputDecoration textFieldInputDecoration(String hintText) {
  return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.blueGrey[300]),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[300])),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[300])));
}

TextStyle simpleTextStyle() {
  return TextStyle(color: Colors.black, fontSize: 20);
}

TextStyle biggerTextStyle() {
  return TextStyle(color: Colors.black, fontSize: 17);
}
