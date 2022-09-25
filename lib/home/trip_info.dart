import 'package:dio/dio.dart' as dio;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_cab/home/trip_end.dart';
import 'package:flutter_cab/utils/CustomTextStyle.dart';
import 'package:flutter_cab/utils/DottedLine.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../utils/CustomColors.dart';
import '../utils/solidityContracts.dart';
import 'dialog/payment_dialog.dart';
import 'dialog/promo_code_dialog.dart';

class TripInfo extends StatefulWidget {
  @override
  _TripInfoState createState() => _TripInfoState();
}

class _TripInfoState extends State<TripInfo> {
  var currentLocation;
  var apiUrl = "https://ws.apothem.network/"; //Replace with your API
  var httpClient = Client();
  var fromLocation = "";
  var toLocation = "";
  var cost = "";
  String Publickey = "";
  String balance = "";
  var current_transaction_id = "";
  var pairing = "";
  var arrivalTime = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTrip();
    setLocation();
    setBalance();
  }

  setBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var temp = prefs.getString("key");
    setState(() {
      Publickey = (temp ?? "").substring(0, 4) +
          "..." +
          (temp ?? "").substring((temp ?? "").length - 4, (temp ?? "").length);
    });
    var ethClient = Web3Client(apiUrl, httpClient);
    var credentials = await ethClient.credentialsFromPrivateKey(temp);
    var balance1 = await ethClient.getBalance(credentials.address);
    log("got balance");
    log(balance1.toString());
    var temp1 = prefs.getString("current_transaction_id");
    setState(() {
      balance = balance1.toString();
      current_transaction_id = temp1;
    });
  }

  getTrip() async {
    await Future.delayed(const Duration(milliseconds: 5000));

    EasyLoading.show();
    var ethClient = Web3Client(apiUrl, httpClient);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var credentials =
        await ethClient.credentialsFromPrivateKey(prefs.getString("key"));
    String _abiCode = SolidityContracts.contract;
    EthereumAddress _contractAddress =
        EthereumAddress.fromHex(CustomColors.contractAddress);
    DeployedContract _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "Deris"), _contractAddress);

    var response1 = await ethClient.call(
        contract: _contract,
        function: _contract.function("users"),
        params: [credentials.address]);
    log("contract got");
    log(response1.toString());

    dio.Response response = await dio.Dio().get(
        "https://apis.mapmyindia.com/advancedmaps/v1/2639e9b1aeccd83ff69a14a24165be42/rev_geocode?lat=${(int.parse(response1[4][0].toString()) / 1000000000000).toString()}&lng=${(int.parse(response1[4][1].toString()) / 1000000000000).toString()}");

    setState(() {
      fromLocation = response.data["results"][0]["formatted_address"];
    });

    dio.Response response2 = await dio.Dio().get(
        "https://apis.mapmyindia.com/advancedmaps/v1/2639e9b1aeccd83ff69a14a24165be42/rev_geocode?lat=${(int.parse(response1[5][0].toString()) / 1000000000000).toString()}&lng=${(int.parse(response1[5][1].toString()) / 1000000000000).toString()}");
    log('response 2');
    log(response2.data.toString());
    setState(() {
      toLocation = response2.data["results"][0]["formatted_address"];
    });
    EasyLoading.dismiss();
    setState(() {
      pairing = response1[3].toString();
      arrivalTime = response1[6].toString();
    });
  }

  setLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(position.latitude, position.longitude), 18);
    currentLocation = LatLng(position.latitude, position.longitude);

    print("location " +
        position.latitude.toString() +
        position.longitude.toString());
    setState(() {});
  }

  MapController _mapController = new MapController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
          child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Row(children: [
            Text(Publickey),
            SizedBox(width: 25),
            if (balance != "")
              Text((int.parse(balance
                              .replaceAll("EtherAmount: ", "")
                              .replaceAll(" wei", "")
                              .substring(0, 7)) /
                          1000)
                      .toString() +
                  " xdc")
          ]),
        ),
        body: Container(
          child: Stack(
            children: <Widget>[
              FlutterMap(
                  mapController: _mapController,
                  options: new MapOptions(
                      center: currentLocation,
                      zoom: 18.0,
                      minZoom: 13,
                      maxZoom: 18),
                  children: [
                    TileLayerWidget(
                        options: TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ))
                  ]),
              Column(
                key: Key("AddressSection"),
                children: <Widget>[
                  SizedBox(height: 16),
                  Card(
                    key: Key("CardSourceAddress"),
                    margin: EdgeInsets.symmetric(horizontal: 30, vertical: 6),
                    child: Container(
                      key: Key("ContainerSourceAddress"),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            width: 10,
                            margin: EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            height: 10,
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Text(
                                fromLocation,
                                style: CustomTextStyle.regularTextStyle
                                    .copyWith(color: Colors.grey.shade800),
                              ),
                            ),
                            flex: 100,
                          ),
                          IconButton(
                              icon: Icon(
                                Icons.favorite_border,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () {})
                        ],
                      ),
                    ),
                  ),
                  Card(
                    key: Key("CardDestAddress"),
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      key: Key("ContainerDestAddress"),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            width: 10,
                            margin: EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            height: 10,
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              padding: EdgeInsets.only(top: 16, bottom: 16),
                              child: Text(
                                toLocation,
                                style: CustomTextStyle.regularTextStyle
                                    .copyWith(color: Colors.grey.shade800),
                              ),
                            ),
                            flex: 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    key: Key("SizedBox_16"),
                    height: 16,
                  ),
                  RaisedButton(
                    key: Key("btnCancelTrip"),
                    onPressed: () {},
                    child: Text(
                      "Cancel Trip",
                      style: CustomTextStyle.regularTextStyle,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    color: Colors.black.withOpacity(0.6),
                  )
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  height: Get.height * 0.3,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        current_transaction_id,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.normal),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (pairing == "" ||
                          pairing ==
                              "0x0000000000000000000000000000000000000000")
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black)),
                          child: Column(
                            children: [
                              Container(
                                width: Get.width - 65,
                                child: Row(
                                  children: [
                                    Icon(Icons.update),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      width: Get.width * 0.8,
                                      child: Text(
                                        "Status : " +
                                            "Waiting for a driver to accept...",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              MaterialButton(
                                color: Colors.black,
                                onPressed: () async {
                                  EasyLoading.show();
                                  var ethClient =
                                      Web3Client(apiUrl, httpClient);
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  var credentials =
                                      await ethClient.credentialsFromPrivateKey(
                                          prefs.getString("key"));
                                  String _abiCode = SolidityContracts.contract;
                                  EthereumAddress _contractAddress =
                                      EthereumAddress.fromHex(
                                          CustomColors.contractAddress);
                                  DeployedContract _contract = DeployedContract(
                                      ContractAbi.fromJson(_abiCode, "Deris"),
                                      _contractAddress);

                                  var response1 = await ethClient.call(
                                      contract: _contract,
                                      function: _contract.function("users"),
                                      params: [credentials.address]);
                                  log("contract got");
                                  log(response1.toString());
                                  setState(() {
                                    pairing = response1[3].toString();
                                    arrivalTime = response1[6].toString();
                                  });
                                  EasyLoading.dismiss();
                                },
                                child: Text(
                                  "Retry",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                      if (pairing != "" &&
                          pairing !=
                              "0x0000000000000000000000000000000000000000")
                        Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black)),
                            child: Column(children: [
                              Container(
                                  width: Get.width * 0.8,
                                  child: Text(
                                    "Driver connected!!! Arriving to your location in " +
                                        arrivalTime +
                                        " mins",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ))
                            ]))
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      )),
    );
  }
}
