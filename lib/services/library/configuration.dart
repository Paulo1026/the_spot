import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/UserProfile.dart';
import 'package:the_spot/services/library/library.dart';
import 'package:the_spot/services/library/pushNotificationManager.dart';

class Configuration {
  Configuration(
      {this.userData,
      this.screenHeight,
      this.screenWidth,
      this.textSizeFactor,
      this.updateIsAvailable,
      this.isAlgoliaOperational,
      this.isFirestoreOperational,
      this.isApplicationOperational,
      this.alertMessage});

  BuildContext context;

  UserProfile userData;

  double screenHeight;
  double screenWidth;
  double textSizeFactor;

  PushNotificationsManager pushNotificationsManager = PushNotificationsManager();

  bool updateIsAvailable;
  bool isAlgoliaOperational;
  bool isFirestoreOperational;
  bool isApplicationOperational;
  String alertMessage;

  Future<Configuration> getConfiguration(
      BuildContext context, String userId) async {
    Configuration configuration = Configuration();
    await configuration.pushNotificationsManager.init(context); //init notificationsHandler
    if (await checkConnection(context)) {
      await Firestore.instance
          .collection('configuration')
          .document('Configuration')
          .get()
          .then((document) {
        configuration.updateIsAvailable = document.data['UpdateIsAvailable'];
        configuration.isApplicationOperational =
            document.data['IsApplicationOperational'];
        configuration.isFirestoreOperational =
            document.data['IsFirestoreOperational'];
        configuration.isAlgoliaOperational =
            document.data['IsAlgoliaOperational'];
        configuration.alertMessage = document.data['AlertMessage'];
      }).catchError((err) {
        print(err.toString());
        error(err.toString(), context);
      });
      if (userId != null && userId.length > 0) {
        configuration.userData =
            await Database().getProfileData(userId, context);
        configuration.userData.devicesTokens = [await configuration.pushNotificationsManager.getToken()];
        Database().addDeviceTokenToUserProfile(context, userId, configuration.userData.devicesTokens);
      }
    }
    return configuration;
  }
}
