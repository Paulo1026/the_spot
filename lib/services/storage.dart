import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_spot/app_localizations.dart';
import 'package:the_spot/services/library/blurhash_encoding.dart';

import '../theme.dart';

class Storage {
  Future<String> getPhotoFromUserStorageAndUpload(
      {@required String storageRef,
      @required BuildContext context,
      bool getPhotoFromGallery = false,
      bool letUserChooseImageSource = true,
      bool getBlurHash = false,
      CropAspectRatio cropAspectRatio,
      CropStyle cropStyle,
      int maxHeight = 1080,
      int maxWidth = 1080,
      int compressQuality = 75}) async {
    File _file;
    if (letUserChooseImageSource) {
      getPhotoFromGallery = null;
      AlertDialog errorAlertDialog = new AlertDialog(
        elevation: 0,
        backgroundColor: PrimaryColorDark,
        title: Text(
          AppLocalizations.of(context).translate("Get image from:"),
          style: TextStyle(color: PrimaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate("Camera"),
                style: TextStyle(color: PrimaryColorLight),
              ),
              leading: Icon(
                Icons.photo_camera,
                color: PrimaryColorLight,
              ),
              onTap: () {
                getPhotoFromGallery = false;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate("Gallery"),
                style: TextStyle(color: PrimaryColorLight),
              ),
              leading: Icon(
                Icons.photo_library,
                color: PrimaryColorLight,
              ),
              onTap: () {
                getPhotoFromGallery = true;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );

      await showDialog(context: context, child: errorAlertDialog);
    }
    if (getPhotoFromGallery != null) {
      _file = await ImagePicker.pickImage(
          source:
              getPhotoFromGallery ? ImageSource.gallery : ImageSource.camera);

      if (_file != null) {
        try {
          _file = await ImageCropper.cropImage(
              sourcePath: _file.path,
              aspectRatio: cropAspectRatio,
              cropStyle: cropStyle,
              maxHeight: maxHeight,
              maxWidth: maxWidth,
              compressQuality: compressQuality,
              androidUiSettings: AndroidUiSettings(
                toolbarColor: PrimaryColorDark,
                toolbarWidgetColor: Colors.white,
                activeControlsWidgetColor: PrimaryColorLight,
                lockAspectRatio: true,
              ),
              iosUiSettings: IOSUiSettings(
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
              ));

          final StorageReference storageReference =
              FirebaseStorage().ref().child(storageRef);
          final StorageUploadTask uploadTask = storageReference.putFile(_file);
          await uploadTask.onComplete;
          if (uploadTask.isSuccessful) {
            print("Image uploaded with success");
            if (getBlurHash)
              return await getImageBlurHash(_file, addWidthAndHeightToHash: true);
            else
              return "success";
          } else {
            print("Error when uploading image...");
            return "error";
          }
        } catch (err) {
          print(err);
          return "error";
        }
      }
    }
    return "error";
  }

  Future<String> getUrlPhoto(String locationOnStorage) async {
    StorageReference storageReference =
        FirebaseStorage().ref().child(locationOnStorage);
    String picture = await storageReference.getDownloadURL();
    return picture;
  }
}
