import 'package:fluster/fluster.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta/meta.dart';
import 'package:the_spot/services/library/userGrade.dart';

enum Type{
  Spot,
  User
}

class MapMarker extends Clusterable {
  final String id;
  LatLng position;
  final Type type;
  BitmapDescriptor icon;
  final String name;
  final String description;
  final List<String> imagesDownloadUrls;
  final List<UserGrades> usersGrades;

  MapMarker({
    @required this.id,
    @required this.position,
    @required this.type,
    this.icon,
    this.name,
    this.description,
    this.imagesDownloadUrls,
    this.usersGrades,
    isCluster = false,
    clusterId,
    pointsSize,
    childMarkerId,
  }) : super(
          markerId: id,
          latitude: position.latitude,
          longitude: position.longitude,
          isCluster: isCluster,
          clusterId: clusterId,
          pointsSize: pointsSize,
          childMarkerId: childMarkerId,
        );

  Marker toMarker() => Marker(
        markerId: MarkerId(id),
        position: LatLng(
          position.latitude,
          position.longitude,
        ),
        icon: icon,
      );
}
