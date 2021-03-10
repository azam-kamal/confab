import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

//Download Path
Future<Directory> _getDownloadDirectory() async {
  if (Platform.isAndroid) {
    return await DownloadsPathProvider.downloadsDirectory;
  }

  // in this example we are using only Android and iOS so I can assume
  // that you are not trying it for other platforms and the if statement
  // for iOS is unnecessary

  // iOS directory visible to user
  return await getApplicationDocumentsDirectory();
}

//Storage Permission
Future<bool> _requestPermissions() async {
  var permission =
      await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);

  if (permission != PermissionStatus.granted) {
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
  }

  return permission == PermissionStatus.granted;
}

//Download Method
Future<void> download(String fileUrl, String fileName) async {
  int perPos = fileUrl.lastIndexOf('.');
  String ext = fileUrl.substring(perPos, perPos + 4);
  print(ext);
  final dir = await _getDownloadDirectory();
  final isPermissionStatusGranted = await _requestPermissions();

  if (isPermissionStatusGranted) {
    final savePath = path.join(dir.path, fileName+ext);
    await _startDownload(fileUrl, savePath)
        .then((value) => print('Download Complete!'));
  } else {
    // handle the scenario when user declines the permissions
  }
}

//Download Process

final Dio _dio = Dio();

Future<void> _startDownload(String fileUrl, savePath) async {
  print('downloadsssssssssssssssssss');
  print(savePath);
  print(fileUrl);
  await _dio.download(fileUrl, savePath);
}

//This to be included in UI
//   // Downloading Progress
//   void _onReceiveProgress(int received, int total) {
//     if (total != -1) {
//       setState(() {
//         _progress = (received / total * 100).toStringAsFixed(0) + "%";
//       });
//     }
//   }

//   //progressbar widget
// String _progress = "-";
// Widget progressBar() {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         Text(
//           'Download progress:',
//         ),
//         Text(
//           '$_progress',
//         ),
//       ],
//     ),
//   );
// }
