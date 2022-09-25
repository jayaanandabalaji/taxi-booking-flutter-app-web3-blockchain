import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cab/home/pickup_user.dart';
import 'package:flutter_cab/home/trip_info.dart';
import 'package:flutter_cab/menu/menu.dart';
import 'package:flutter_cab/my_trips.dart';
import 'package:flutter_cab/utils/CustomTextStyle.dart';
import 'package:flutter_cab/utils/solidityContracts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../utils/CustomColors.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Set<Marker> markers = new Set();
  var currentocation;
  MapController _mapController = new MapController();
  List<Marker> customMarkers = [];
  LatLng currentLocation;
  String pickedvehicle = "Car";
  TextEditingController fromLocation = TextEditingController();
  TextEditingController toLocation = TextEditingController();
  LatLng fromLatLng;
  LatLng toLatLng;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setLocation();
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
    customMarkers.add(Marker(
      anchorPos: AnchorPos.align(AnchorAlign.center),
      height: 50,
      width: 50,
      point: LatLng(13.0207811, 80.1540117),
      builder: (ctx) => Image.asset("images/marker.png"),
    ));

    setState(() {
      customMarkers = List.from(customMarkers);
    });
    print("location " +
        position.latitude.toString() +
        position.longitude.toString());
    setState(() {});
  }

  String accessToken;
  var apiUrl = "https://ws.apothem.network/"; //Replace with your API
  var httpClient = Client();
  var searchList = [];
  Future<List<String>> _fetchSuggestions(String searchValue) async {
    dio.Response response = await dio.Dio().get(
        "https://nominatim.openstreetmap.org/search/${searchValue}?format=json&addressdetails=1&limit=10&polygon_svg=1");
    searchList = response.data;
    List<String> temp = [];
    for (var location in response.data) {
      temp.add(location["display_name"]);
    }

    return temp;
  }

  final GlobalKey<ScaffoldState> _scaffoldkey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
          child: Scaffold(
        key: _scaffoldkey,
        body: Builder(
          builder: (context) {
            return Container(
              child: Stack(
                children: <Widget>[
                  FlutterMap(
                      mapController: _mapController,
                      options: new MapOptions(
                          center: currentocation,
                          zoom: 18.0,
                          minZoom: 13,
                          maxZoom: 18),
                      children: [
                        TileLayerWidget(
                            options: TileLayerOptions(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        )),
                        MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                          maxClusterRadius: 120,
                          size: Size(40, 40),
                          markers: customMarkers,
                          fitBoundsOptions: FitBoundsOptions(
                            padding: EdgeInsets.all(50),
                          ),
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  color: Colors.blue),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ))
                      ]),
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          child: IconButton(
                              icon: Icon(Icons.menu),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Menu();
                                    });
                              }),
                        ),
                      ),
                      Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        child: Container(
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
                                    child: EasyAutocomplete(
                                      controller: fromLocation,
                                      asyncSuggestions: (searchValue) async =>
                                          _fetchSuggestions(searchValue),
                                      onChanged: (value) {},
                                      onSubmitted: (value) async {
                                        log("submitted");
                                        log(value);
                                        log(searchList.toString());
                                        for (var location in searchList) {
                                          if (location["display_name"] ==
                                              value) {
                                            log("found");
                                            fromLatLng = LatLng(
                                                double.parse(location["lat"]),
                                                double.parse(location["lon"]));
                                          }
                                        }
                                      },
                                      progressIndicatorBuilder:
                                          CircularProgressIndicator(),
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Add a pickup location"),
                                    ),
                                  ),
                                  flex: 100,
                                ),
                                IconButton(
                                    onPressed: () async {
                                      Position position =
                                          await Geolocator.getCurrentPosition(
                                              desiredAccuracy:
                                                  LocationAccuracy.high);

                                      dio.Response response = await dio.Dio().get(
                                          "https://apis.mapmyindia.com/advancedmaps/v1/2639e9b1aeccd83ff69a14a24165be42/rev_geocode?lat=${position.latitude}&lng=${position.longitude}");
                                      fromLatLng = LatLng(position.latitude,
                                          position.longitude);
                                      fromLocation.text =
                                          response.data["results"][0]
                                              ["formatted_address"];
                                    },
                                    icon: Icon(Icons.location_pin))
                              ]),
                        ),
                      ),
                      Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                width: 10,
                                margin: EdgeInsets.only(left: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.yellow,
                                ),
                                height: 10,
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(left: 16),
                                  child: EasyAutocomplete(
                                    controller: toLocation,
                                    asyncSuggestions: (searchValue) async =>
                                        _fetchSuggestions(searchValue),
                                    onChanged: (value) {},
                                    onSubmitted: (value) async {
                                      for (var location in searchList) {
                                        if (location["display_name"] == value) {
                                          toLatLng = LatLng(
                                              double.parse(location["lat"]),
                                              double.parse(location["lon"]));
                                        }
                                      }
                                    },
                                    progressIndicatorBuilder:
                                        CircularProgressIndicator(),
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Add a drop location"),
                                  ),
                                ),
                                flex: 100,
                              ),
                              IconButton(
                                  onPressed: () async {
                                    Position position =
                                        await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high);

                                    dio.Response response = await dio.Dio().get(
                                        "https://apis.mapmyindia.com/advancedmaps/v1/2639e9b1aeccd83ff69a14a24165be42/rev_geocode?lat=${position.latitude}&lng=${position.longitude}");
                                    toLatLng = LatLng(
                                        position.latitude, position.longitude);
                                    toLocation.text = response.data["results"]
                                        [0]["formatted_address"];
                                  },
                                  icon: Icon(Icons.location_pin))
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.shade400,
                                          blurRadius: 20,
                                          offset: Offset(-6, -10)),
                                      BoxShadow(
                                          color: Colors.grey.shade400,
                                          blurRadius: 20,
                                          offset: Offset(-6, 10))
                                    ]),
                                child: Card(
                                  elevation: 1,
                                  margin: EdgeInsets.all(0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8))),
                                  child: Container(
                                    margin: EdgeInsets.all(24),
                                    child: Column(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              pickedvehicle = "Car";
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Text("Car",
                                                  style: TextStyle(
                                                      color: (pickedvehicle ==
                                                              "Car")
                                                          ? Colors.black
                                                          : Colors.grey,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              SizedBox(
                                                height: 2,
                                              ),
                                              Image(
                                                image: AssetImage(
                                                    "images/car.png"),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              pickedvehicle = "Budget";
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Text(
                                                "Budget",
                                                style: TextStyle(
                                                    color: (pickedvehicle ==
                                                            "Budget")
                                                        ? Colors.black
                                                        : Colors.grey,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 2,
                                              ),
                                              Image(
                                                image: AssetImage(
                                                    "images/hatchback.png"),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              pickedvehicle = "City";
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Text(
                                                "City",
                                                style: TextStyle(
                                                    color: (pickedvehicle ==
                                                            "City")
                                                        ? Colors.black
                                                        : Colors.grey,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 2,
                                              ),
                                              Image(
                                                image: AssetImage(
                                                    "images/city.png"),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              pickedvehicle = "Tuk";
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Text(
                                                "Tuk",
                                                style: TextStyle(
                                                    color:
                                                        (pickedvehicle == "Tuk")
                                                            ? Colors.black
                                                            : Colors.grey,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 2,
                                              ),
                                              Image(
                                                image: AssetImage(
                                                    "images/tuk.png"),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              pickedvehicle = "Van";
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Text(
                                                "Van",
                                                style: TextStyle(
                                                    color:
                                                        (pickedvehicle == "Van")
                                                            ? Colors.black
                                                            : Colors.grey,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(
                                                height: 2,
                                              ),
                                              Image(
                                                image: AssetImage(
                                                    "images/van.png"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        flex: 100,
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage("images/navigation.png"),
                            )),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MaterialButton(
                              color: Colors.black,
                              onPressed: () async {
                                if (fromLocation.text == "" ||
                                    toLocation.text == "") {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Please select from and to locations!"),
                                  ));
                                } else {
                                  EasyLoading.show();
                                  dio.Response response = await dio.Dio().get(
                                      "https://graphhopper.com/api/1/route?point=${fromLatLng.latitude},${fromLatLng.longitude}&point=${toLatLng.latitude},${toLatLng.longitude}&profile=car&locale=de&calc_points=false&key=737436f2-b18e-4b32-b3f8-d0c1cba29556");
                                  log("got response");
                                  log(response.data.toString());
                                  EasyLoading.dismiss();
                                  showModalBottomSheet(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      backgroundColor: Colors.white,
                                      builder: (context) => Container(
                                          padding: EdgeInsets.all(20),
                                          child: Column(children: [
                                            Text(
                                              "Confirm Ride",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            if (pickedvehicle == "Car")
                                              Row(
                                                children: [
                                                  Image.asset("images/car.png"),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    "car",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                            if (pickedvehicle == "Budget")
                                              Row(
                                                children: [
                                                  Image.asset(
                                                      "images/hatchback.png"),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    "Budget",
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                            SizedBox(height: 20),
                                            Row(children: [
                                              Icon(
                                                Icons.social_distance,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Distance : " +
                                                    ((response.data["paths"][0]
                                                                ["distance"]) /
                                                            1000)
                                                        .round()
                                                        .toString() +
                                                    " Km",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ]),
                                            SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.timer,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  "Estimated Duration : " +
                                                      ((response.data["paths"]
                                                                  [0]["time"]) /
                                                              60000)
                                                          .round()
                                                          .toString() +
                                                      " mins ",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ],
                                            ),
                                            SizedBox(height: 20),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.currency_exchange,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  "Cost : " +
                                                      (((((response.data["paths"][0]
                                                                              [
                                                                              "distance"]) /
                                                                          1000)
                                                                      .round()) *
                                                                  23) /
                                                              2.07302005854)
                                                          .toString() +
                                                      " XDC ",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(
                                                  height: 40,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.6,
                                                  child: MaterialButton(
                                                    color: Colors.black,
                                                    onPressed: () async {
                                                      Navigator.pop(context);

                                                      EasyLoading.show();
                                                      try {
                                                        var ethClient =
                                                            Web3Client(apiUrl,
                                                                httpClient);
                                                        SharedPreferences
                                                            prefs =
                                                            await SharedPreferences
                                                                .getInstance();
                                                        var credentials =
                                                            await ethClient
                                                                .credentialsFromPrivateKey(
                                                                    prefs.getString(
                                                                        "key"));
                                                        String _abiCode =
                                                            SolidityContracts
                                                                .contract;
                                                        EthereumAddress
                                                            _contractAddress =
                                                            EthereumAddress.fromHex(
                                                                CustomColors
                                                                    .contractAddress);
                                                        DeployedContract
                                                            _contract =
                                                            DeployedContract(
                                                                ContractAbi
                                                                    .fromJson(
                                                                        _abiCode,
                                                                        "Deris"),
                                                                _contractAddress);

                                                        var response1 =
                                                            await ethClient
                                                                .sendTransaction(
                                                                    credentials,
                                                                    Transaction
                                                                        .callContract(
                                                                      contract:
                                                                          _contract,
                                                                      from: credentials
                                                                          .address,
                                                                      function:
                                                                          _contract
                                                                              .function("rideRequest"),
                                                                      parameters: [
                                                                        [
                                                                          BigInt.from(fromLatLng.latitude *
                                                                              1000000000000),
                                                                          BigInt.from(fromLatLng.longitude *
                                                                              1000000000000)
                                                                        ],
                                                                        [
                                                                          BigInt.from(toLatLng.latitude *
                                                                              1000000000000),
                                                                          BigInt.from(toLatLng.longitude *
                                                                              1000000000000)
                                                                        ],
                                                                        BigInt.from((((((response.data["paths"][0]["distance"]) / 1000).round()) *
                                                                                23) /
                                                                            2.07302005854))
                                                                      ],
                                                                    ),
                                                                    chainId:
                                                                        51);
                                                        log("got response");
                                                        log(response1
                                                            .toString());
                                                        prefs.setString(
                                                            "current_transaction_id",
                                                            response1
                                                                .toString());
                                                        _scaffoldkey
                                                            .currentState
                                                            .showSnackBar(SnackBar(
                                                                content: Text(
                                                                    'Ride Scheduled successfully!')));
                                                        Get.to(TripInfo());
                                                      } catch (e) {
                                                        log("error occures");
                                                        log(e.toString());
                                                        _scaffoldkey
                                                            .currentState
                                                            .showSnackBar(SnackBar(
                                                                content: Text(e
                                                                    .toString())));
                                                      } finally {
                                                        EasyLoading.dismiss();
                                                      }
                                                    },
                                                    child: Text(
                                                      "Confirm Booking",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ])),
                                      context: context);
                                }
                              },
                              child: Text(
                                "Ride Now",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ))
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      )),
    );
  }
}
