import 'dart:async';
import 'dart:convert';
import 'package:drivers_app/pushNotification/push_notification_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../global/global_var.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  Color colorToShow = Colors.green;
  String titleToShow = "GO ONLINE NOW";
  bool isDriverAvailable = false;
  DatabaseReference? newTripRequestReference;


  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/aubergine_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  getCurrentLiveLocationOfDriver() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng possitionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: possitionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  goOnlineNow() {
    Geofire.initialize("onlineDrivers");

    Geofire.setLocation(
        FirebaseAuth.instance.currentUser!.uid,
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude,
    );

    newTripRequestReference = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid).child("newTripStatus");
    newTripRequestReference!.set("waiting");

    newTripRequestReference!.onValue.listen((event) { });
  }

  setAndGetLocationUpdates() {
    positionStreamHomePage = Geolocator.getPositionStream()
        .listen((Position position)
    {
      currentPositionOfUser  = position;

      if(isDriverAvailable == true) {
        Geofire.setLocation(
          FirebaseAuth.instance.currentUser!.uid,
          currentPositionOfUser!.latitude,
          currentPositionOfUser!.longitude,
        );

        LatLng positionLatLng = LatLng(position.latitude, position.longitude);
        controllerGoogleMap!.animateCamera(CameraUpdate.newLatLng(positionLatLng));
      }
    });
  }


  goOfflineNow() {
    // stop sharing live location updates
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);

    // stop listening to the new trip status
    newTripRequestReference!.onDisconnect();
    newTripRequestReference!.remove();
    newTripRequestReference = null;
  }

  initializePushNotificationSystem(){
    PushNotificaionSystem notificaionSystem = PushNotificaionSystem();
    notificaionSystem.generateDeviceRegistrationToken();
    notificaionSystem.startListeningForNewNotification();
    // notificaionSystem.requestingPermission();
}

@override
  void initState() {
    // TODO: implement initState
    super.initState();

    initializePushNotificationSystem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // google map
          GoogleMap(
            padding: const EdgeInsets.only(top: 136),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);

              getCurrentLiveLocationOfDriver();
            },
          ),

          Container(
            height: 136,
            width: double.infinity,
            color: Colors.black54,
          ),

          // go online offline button
          Positioned(
            top: 61,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        isDismissible: false,
                        backgroundColor: Colors.black87,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)),),
                        builder: (BuildContext context) {
                          return Container(
                            decoration: const BoxDecoration(
                              // color: Colors.black45,
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: Colors.black,
                              //     blurRadius: 0.0,
                              //     spreadRadius: 0.0,
                              //     offset: Offset(
                              //       0.0,
                              //       0.0
                              //     ),
                              //   ),
                              // ],
                            ),
                            height: 221,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 18),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 11,
                                  ),
                                  Text(
                                    (!isDriverAvailable)
                                        ? "GO ONLINE NOW"
                                        : "GO OFFLINE NOW",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 21,
                                  ),
                                  Text(
                                    (!isDriverAvailable)
                                        ? "You are about to go online, you will become available to receive trip request from users."
                                        : "You are about to go offline, you will stop receiving new trip request from users.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 25,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          style: const ButtonStyle(
                                            shape: MaterialStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                              ),
                                            ),
                                            backgroundColor: MaterialStatePropertyAll(Colors.blue)
                                          ),
                                          child: const Text(
                                            "BACK",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16,),


                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (!isDriverAvailable) {
                                              //go online
                                              goOnlineNow();

                                              // get driver location updates
                                              setAndGetLocationUpdates();

                                              Navigator.pop(context);

                                              setState(() {
                                                colorToShow = Colors.pink;
                                                titleToShow = "GO OFFLINE NOW";
                                                isDriverAvailable = true;
                                              });
                                            } else {
                                              // go offline
                                              goOfflineNow();


                                              Navigator.pop(context);

                                              setState(() {
                                                colorToShow = Colors.green;
                                                titleToShow = "GO ONLINE NOW";
                                                isDriverAvailable = false;
                                              });
                                            }
                                          },
                                          style: ButtonStyle(
                                            shape: const MaterialStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                              ),
                                            ),
                                              backgroundColor: MaterialStatePropertyAll(
                                                  (titleToShow == "GO ONLINE NOW") ? Colors.green : Colors.pink
                                              )
                                          ),

                                          // style: ElevatedButton.styleFrom(
                                          //     backgroundColor: (titleToShow == "GO ONLINE NOW")
                                          //         ? Colors.green
                                          //         : Colors.pink),

                                          child: const Text(
                                            "CONFIRM",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  },
                  style: ButtonStyle(
                      shape: const MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                      ),
                      backgroundColor: MaterialStatePropertyAll(colorToShow)),
                  child: Text(
                    titleToShow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
