import 'package:flutter/material.dart';
import 'package:flutter_cab/home/payment_menu.dart';
import 'package:flutter_cab/home/trip_info.dart';
import 'package:flutter_cab/login.dart';
import 'package:flutter_cab/modal/menu_list_item.dart';
import 'package:flutter_cab/utils/CustomTextStyle.dart';
import 'package:flutter_cab/utils/menu_title.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import '../book_late_pick_date.dart';
import '../emergency_contact.dart';
import '../help_support.dart';
import '../my_trips.dart';
import '../news_offers.dart';
import '../profile.dart';
import '../rate_card.dart';

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  List<MenuListItem> listMenuItem = new List();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setBalance();
    listMenuItem.add(
        createMenuItem(MenuTitle.MENU_MY_TRIPS, "images/menu/my_trips.png"));
    listMenuItem.add(createMenuItem("Logout", "images/menu/user.png"));
  }

  String Publickey = "";
  String balance = "";
  var apiUrl = "https://ws.apothem.network/"; //Replace with your API
  var httpClient = Client();

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
    setState(() {
      balance = balance1.toString();
    });
  }

  createMenuItem(String title, String imgIcon) {
    return MenuListItem(title, imgIcon);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Card(
          margin: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16))),
          elevation: 0,
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade50,
                        blurRadius: 1,
                        offset: Offset(0, 1)),
                  ]),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 12, top: 8, right: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          key: Key("UserNameMobile"),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              height: 8,
                            ),
                            (Publickey != "")
                                ? Text(
                                    Publickey,
                                    style: CustomTextStyle.mediumTextStyle,
                                  )
                                : CircularProgressIndicator(),
                            SizedBox(
                              height: 4,
                            ),
                            Text(balance,
                                style: CustomTextStyle.mediumTextStyle
                                    .copyWith(color: Colors.grey, fontSize: 12))
                          ],
                        ),
                        IconButton(
                            key: Key("CloseIcon"),
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            })
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  ListView.builder(
                    key: Key("ListMenu"),
                    shrinkWrap: true,
                    primary: true,
                    itemBuilder: (context, position) {
                      return createMenuListItemWidget(position);
                    },
                    itemCount: listMenuItem.length,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              )),
        )
      ],
    );
  }

  createMenuListItemWidget(int position) {
    return GestureDetector(
      onTap: () async {
        if (listMenuItem[position].title == MenuTitle.MENU_PROFILE) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => Profile()));
        } else if (listMenuItem[position].title == MenuTitle.MENU_PAYMENT) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => PaymentMenu()));
        } else if (listMenuItem[position].title == MenuTitle.MENU_BOOK_LATER) {
          Navigator.of(context).push(new MaterialPageRoute(
              builder: (context) => BookLaterDatePicker()));
        } else if (listMenuItem[position].title == MenuTitle.MENU_MY_TRIPS) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => TripInfo()));
        } else if (listMenuItem[position].title == "Logout") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.clear();
          Get.offAll(Login());
        } else if (listMenuItem[position].title == MenuTitle.MENU_RATE_CARD) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => RateCard()));
        } else if (listMenuItem[position].title ==
            MenuTitle.MENU_EMERGENCY_CONTACTS) {
          Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => EmergencyContacts()));
        } else if (listMenuItem[position].title ==
            MenuTitle.MENU_HELP_SUPPORT) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => HelpSupport()));
        } else if (listMenuItem[position].title == MenuTitle.MENU_NEWS_OFFERS) {
          Navigator.of(context)
              .push(new MaterialPageRoute(builder: (context) => NewsOffers()));
        }
      },
      child: Container(
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 8,
            ),
            Image(
              image: AssetImage(listMenuItem[position].imgIcon),
            ),
            SizedBox(
              width: 14,
            ),
            Container(
              child: Text(listMenuItem[position].title),
              margin: EdgeInsets.only(left: 12),
            )
          ],
        ),
      ),
    );
  }
}
