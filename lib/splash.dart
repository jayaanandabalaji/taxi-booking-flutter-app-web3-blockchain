import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cab/DriverDashboard.dart';
import 'package:flutter_cab/home/home.dart';
import 'package:flutter_cab/utils/CustomTextStyle.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    splashMove();
  }

  navigatePage() {}

  splashMove() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("role") != null) {
      if (prefs.getString("role") == "Driver") {
        Navigator.of(context).pushReplacement(
            new MaterialPageRoute(builder: (context) => DriverDashboard()));
      } else {
        Navigator.of(context).pushReplacement(
            new MaterialPageRoute(builder: (context) => Home()));
      }
    } else {
      Navigator.of(context).pushReplacement(
          new MaterialPageRoute(builder: (context) => Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Peer to peer ridesharing app built on XDC network",
                  style: CustomTextStyle.regularTextStyle,
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
