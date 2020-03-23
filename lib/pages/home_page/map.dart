import 'dart:async';

import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/map_helper.dart';
import 'package:the_spot/services/mapmarker.dart';

import '../../theme.dart';

class Map extends StatefulWidget {
  const Map({Key key, this.userId}) : super(key: key);

  final String userId;

  @override
  _Map createState() => _Map();
}

class _Map extends State<Map> {
  final Completer<GoogleMapController> _mapController = Completer();

  GoogleMapController _controller;

  /// Set of displayed markers and cluster markers on the map
  final Set<Marker> _markers = Set();

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker> _clusterManager;

  ///Map type, true = normal  /  false = hybrid
  bool _mapType = true;

  /// Current map zoom. Initial zoom will be 15, street level
  double _currentZoom = 15;

  /// Map loading flag
  bool _isMapLoading = true;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  /// Url image used on normal markers
  final String _markerImageUrl =
      'https://img.icons8.com/office/80/000000/marker.png';

  /// Color of the cluster circle
  final Color _clusterColor = Colors.blue;

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  /// Example marker coordinates
  final List<LatLng> _markerLocations = [
    LatLng(41.147125, -8.611249),
    LatLng(41.145599, -8.610691),
    LatLng(41.146775, -8.614913),
    LatLng(41.146982, -8.615682),
  ];

  final List<MapMarker> markers = [];

  /// Called when the Google Map widget is created. Updates the map loading state
  /// and inits the markers.
  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);

    _controller = controller;

    setState(() {
      _isMapLoading = false;
    });

    _initMarkers();
  }

  /// Inits [Fluster] and all the markers with network images and updates the loading state.
  void _initMarkers() async {

    List spots = await Database().getSpots(context);

    if (spots != null) {
      for(MapMarker mapMarker in spots) {
        markers.add(mapMarker);
      }
    }

    _clusterManager = await MapHelper.initClusterManager(
      markers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await _updateMarkers();
  }

  /// Gets the markers and clusters to be displayed on the map for the current zoom level and
  /// updates state.
  Future<void> _updateMarkers([double updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;

    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    _markers
      ..clear()
      ..addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Google Map widget
          Opacity(
            opacity: _isMapLoading ? 0 : 1,
            child: GoogleMap(
              compassEnabled: true,
              mapType: _mapType ? MapType.normal : MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: LatLng(41.143029, -8.611274),
                zoom: _currentZoom,
              ),
              markers: _markers,
              onMapCreated: (controller) => _onMapCreated(controller),
              onCameraMove: (position) => _updateMarkers(position.zoom),
              onLongPress: showDialogConfirmCreateSpot,
            ),
          ),

          // Map loading indicator
          Opacity(
            opacity: _isMapLoading ? 1 : 0,
            child: Center(child: CircularProgressIndicator()),
          ),

          // Map markers loading indicator
          _areMarkersLoading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      elevation: 2,
                      color: PrimaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(0.0),
                ),
          Positioned(
            top: 25,
            right: 0,
            child: Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.place,
                    color: SecondaryColorDark,
                  ),
                  onPressed: () => print("AddAMarker"),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: SecondaryColorDark,
                  ),
                  onPressed: showDialogSpotLocation,
                ),
                IconButton(
                  icon: Icon(
                    Icons.map,
                    color: SecondaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _mapType = !_mapType;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showDialogSpotLocation() {
    showDialog(
        context: context,
        child: AlertDialog(
          content: Text(
              "Please show us the location of your spot by a long click on it on the map"),
          actions: <Widget>[
            FlatButton(
              child: Text("Ok"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ));
  }

  void showDialogConfirmCreateSpot(LatLng spotLocation) {
    _controller
        .animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(spotLocation.latitude - 0.0001, spotLocation.longitude), 20))
        .whenComplete(() {
      Future.delayed(Duration(seconds: 2)).whenComplete(() {
        setState(() {
          _markers.add(Marker(
              markerId: MarkerId(spotLocation.toString()),
              position: spotLocation));
          _mapType = false;
        });
      });
    });

    showDialog(
        context: context,
        child: AlertDialog(
          content: Text("Create a spot at this place?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Yes"),
              onPressed: () {
                setState(() {
                  _markers.remove(Marker(
                      markerId: MarkerId(spotLocation.toString()),
                      position: spotLocation));
                });
                Navigator.pop(context);
                createSpot(spotLocation);
              },
            ),
            FlatButton(
                child: Text("No"),
                onPressed: () {
                  setState(() {
                    _markers.remove(Marker(
                        markerId: MarkerId(spotLocation.toString()),
                        position: spotLocation));
                  });
                  Navigator.pop(context);
                })
          ],
        ));
  }

  void createSpot(LatLng tapPosition) async {

    String spotId = await Database().addASpot(context, tapPosition, widget.userId);

    if(spotId != null) {
      markers.add(MapMarker(
        id: spotId,
        position: tapPosition,
        icon: BitmapDescriptor.defaultMarker,
      ));

      _clusterManager = await MapHelper.initClusterManager(
        markers,
        _minClusterZoom,
        _maxClusterZoom,
      );

      _updateMarkers();
    }
  }
}