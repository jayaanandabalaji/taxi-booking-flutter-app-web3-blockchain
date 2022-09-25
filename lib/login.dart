import 'dart:developer';

import 'package:flutter_cab/DriverDashboard.dart';
import 'package:flutter_cab/home/home.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cab/utils/CustomColors.dart';
import 'package:flutter_cab/utils/CustomTextStyle.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import 'connect_social_account.dart';
import 'login_password.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var selected = "Driver";
  var apiUrl = "https://ws.apothem.network/"; //Replace with your API
  var httpClient = Client();

  TextEditingController ppk = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          key: _scaffoldkey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Login using XDC"),
            backgroundColor: Colors.black,
          ),
          body: Center(
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 100),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(
                            left: 8, right: 32, top: 6, bottom: 6),
                        hintText: "XDC wallet private key",
                        hintStyle: CustomTextStyle.regularTextStyle
                            .copyWith(color: Colors.grey, fontSize: 12),
                        labelStyle: CustomTextStyle.regularTextStyle
                            .copyWith(color: Colors.black, fontSize: 12),
                      ),
                      onChanged: (value) {},
                      controller: ppk,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Are you?",
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selected = "Driver";
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: (selected != "Driver")
                                    ? Colors.grey.withOpacity(0.4)
                                    : Colors.green.withOpacity(0.4),
                                border: Border.all(
                                    color: (selected != "Driver")
                                        ? Colors.grey
                                        : Colors.green)),
                            child: Text(
                              "Driver",
                              style: TextStyle(
                                  color: (selected != "Driver")
                                      ? Colors.grey
                                      : Colors.green,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "OR",
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selected = "Rider";
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: (selected != "Rider")
                                    ? Colors.grey.withOpacity(0.4)
                                    : Colors.green.withOpacity(0.4),
                                border: Border.all(
                                    color: (selected != "Rider")
                                        ? Colors.grey
                                        : Colors.green)),
                            child: Text(
                              "Rider",
                              style: TextStyle(
                                  color: (selected != "Rider")
                                      ? Colors.grey
                                      : Colors.green,
                                  fontSize: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 50),
                    Container(
                      width: double.infinity,
                      child: MaterialButton(
                          color: CustomColors.primaryColor,
                          onPressed: () async {
                            log("button tapped");
                            if (ppk.text == "") {
                              _scaffoldkey.currentState.showSnackBar(SnackBar(
                                  content: Text(
                                      'Please enter wallet private key!')));

                              log("inside blank");
                            } else {
                              log("inside value");
                              EasyLoading.show();

                              try {
                                var ethClient = Web3Client(apiUrl, httpClient);
                                var credentials = await ethClient
                                    .credentialsFromPrivateKey(ppk.text);
                                var balance = await ethClient
                                    .getBalance(credentials.address);
                                log("got balance");
                                log(balance.toString());
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setString("role", selected);
                                prefs.setString("key", ppk.text);
                                if (selected == "Driver") {
                                  Get.offAll(DriverDashboard());
                                } else {
                                  Get.offAll(Home());
                                }
                              } catch (e) {
                                log("error occured");
                                log(e.toString());
                                _scaffoldkey.currentState.showSnackBar(SnackBar(
                                    content: Text('Private key invalid!')));
                              } finally {
                                EasyLoading.dismiss();
                              }
                            }
                          },
                          child: Text(
                            "Connect Now",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          )),
                    )
                  ],
                )),
          )),
    );
  }
}
