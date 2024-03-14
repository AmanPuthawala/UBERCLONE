import 'package:drivers_app/models/trip_details.dart';
import 'package:drivers_app/widgets/loading_dialog.dart';
import 'package:drivers_app/widgets/notification_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PushNotificaionSystem {
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async{
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();

    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("deviceToken");


    referenceOnlineDriver.set(deviceRecognitionToken);
    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");
  }

  startListeningForNewNotification(BuildContext context) async {
     ///1 Terminated
     //when the app is completely closed
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote)
    {
      if(messageRemote != null)
      {
        String? tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID!, context);
      }

    });

     ///2 Foreground
     //when the app is open and it receives a push notification
     FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote)
     {

       if(messageRemote != null)
       {
         String? tripID = messageRemote.data["tripID"];
         retrieveTripRequestInfo(tripID!, context);
       }

     });

     //3 Background
     // when the app is in the background
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote) {

       if(messageRemote != null) {
         String? tripID = messageRemote.data["tripID"];
         retrieveTripRequestInfo(tripID!, context);
       }

     });
  }

  retrieveTripRequestInfo(String tripID, BuildContext context)
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageText: "getting details..."),
    );

    DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequest").child(tripID);
    tripRequestRef.once().then((dataSnapshot)
    {
      Navigator.pop(context);
      //play notification sound

      TripDetails tripDetailsInfo = TripDetails();
      double pickUpLat =  double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["latitude"]);
      double pickUpLng = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["longitude"]);
      tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);

      tripDetailsInfo.pickupAddress = (dataSnapshot.snapshot.value! as Map)["pickUpAddress"];

      double dropOffLat = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["latitude"]);
      double dropOffLng = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["longitude"]);
      tripDetailsInfo.dropOffLatLng = LatLng(pickUpLat, pickUpLng);

      tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value! as Map)["dropOffAddress"];

      tripDetailsInfo.userName = (dataSnapshot.snapshot.value! as Map)["userName"];
      tripDetailsInfo.userPhone = (dataSnapshot.snapshot.value! as Map)["userPhone"];

      showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialog(tripDetailsInfo: tripDetailsInfo,),
      );

    });
  }
}