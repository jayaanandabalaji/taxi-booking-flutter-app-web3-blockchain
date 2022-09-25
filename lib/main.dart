import 'package:flutter/material.dart';
import 'package:flutter_cab/splash.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'login.dart';

/*
* Start Date : 16-07-2019
* Author : Aakash Kareliya
* */

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 55.0
    ..radius = 10.0
    ..progressColor = Colors.blue
    ..backgroundColor = Colors.white
    ..indicatorColor = Colors.blue
    ..textColor = Colors.yellow
    ..maskColor = Colors.black.withOpacity(0.3)
    ..maskType = EasyLoadingMaskType.custom
    ..userInteractions = true
    ..contentPadding = EdgeInsets.all(25)
    ..dismissOnTap = false;
}

void main() {
  configLoading();
  runApp(new GetMaterialApp(
    navigatorKey: Get.key,
    builder: EasyLoading.init(),
    home: Splash(),
    routes: <String, WidgetBuilder>{
      "\login": (context) => Login(),
    },
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.black,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.black)
            .copyWith(secondary: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      home: Splash(),
      builder: EasyLoading.init(),
    );
  }
}
