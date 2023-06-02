// import 'dart:io';

// import 'package:camera/camera.dart';

// void main() {
//   startApp();
// }

// void startApp() async {
//   print("work");
// }
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:myflutter/homess.dart';


// void main() async {
//   print("work");
// }



// List<CameraDescription> cameras = [];
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: MyHomePage(
//       cameras,
//     ),
//   ));
// }


import 'package:flutter/material.dart';
// import 'package:flutter_application_3/home.dart';
import "package:camera/camera.dart";
import 'package:myflutter/home.dart';

List<CameraDescription>? cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primaryColor: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        home: Home());
  }
}
