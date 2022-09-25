import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:flutter/material.dart';
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

class DriverDashboard extends StatefulWidget {
  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
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
  var nearbyList = [];

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
                  Column(children: <Widget>[
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
                  ]),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.white,
                      child: Container(
                        height: Get.height * 0.5,
                        width: Get.width,
                        child: ListView(
                          padding: EdgeInsets.all(20),
                          children: [
                            Text(
                              "Nearby Rides",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            for (var ride in nearbyList)
                              Container(
                                height:
                                    MediaQuery.of(context).size.width * 0.17,
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.05),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromARGB(20, 149, 157, 165),
                                      blurRadius: 24.0,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("John Doe",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20)),
                                        Row(
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  "Cost",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  "\$10",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                )
                                              ],
                                            ),
                                            SizedBox(
                                              width: 40,
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  "Time",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  "30 min",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                )
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Divider(
                                      color: Colors.grey,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.pin_drop_outlined,
                                              color: Colors.blueGrey,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "Porur, chennai, Tamil nadu",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            )
                                          ],
                                        ),
                                        Text(
                                          "5:30 PM",
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 20),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.pin_drop_outlined,
                                              color: Colors.blueGrey,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "Panimalar Engineering College, Poonamalle",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            )
                                          ],
                                        ),
                                        Text(
                                          "6:10 PM",
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 20),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
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
