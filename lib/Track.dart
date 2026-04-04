import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitiled/Map%20screen%20page.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Apiutils.dart';
import 'Homescreens/save_alarm_page.dart';
import 'adhelper.dart';

int id = 0;
const int notificationId= 888;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Track extends StatefulWidget {
  final AlarmDetails? alarm;
  final String? selectedRingtone;

  const Track({
    super.key,
    this.alarm,
    this.selectedRingtone,
  });

  @override
  State<Track> createState() => _TrackState();
}

class _TrackState extends State<Track> {
  final GlobalKey repaintBoundaryKey = GlobalKey();
  Image? capturedImage;
  double radius = 0;
  BannerAd? _bannerAd;

  updateradiusvalue(value) {
    print("updatevalue:" + value.toString());
    setState(() {
      radius = value;
      print("updatevalue:" + value.toString());
    });
  }

  double targetZoomLevel = 15.0;
  bool isMapInitialized = false;
  GoogleMapController? mapController;
  late String ringtonePath;
  late String selectedRingtone;

  void _saveSelectedRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedRingtone', selectedRingtone);
  }

  Future<void> _loadSelectedRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRingtone = prefs.getString('selectedRingtone') ?? "alarm6.mp3";
    setState(() {
      selectedRingtone = savedRingtone;
    });
  }

  bool _isLoading = true;
  bool isAnimated = false;
  TextEditingController controller = TextEditingController();
  location.LocationData? currentLocation;
  location.Location _locationService = location.Location();
  bool _isCameraMoving = false;
  final LatLng _defaultLocation =
      const LatLng(13.067439, 80.237617); // Default location
  TextEditingController searchController = TextEditingController();
  List<AlarmDetails> alarms = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _requestLocationPermission();
    _isAndroidPermissionGranted();
    _requestPermissions();
    _loadSelectedRingtone();
    _saveSelectedRingtone();
    loadData();
    markLocation();
    setState(() {
      radius = widget.alarm!.locationRadius;
    });
  }

  void _loadBannerAd() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  double degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    double lat1 = degreesToRadians(point1.latitude);
    double lat2 = degreesToRadians(point2.latitude);
    double lon1 = degreesToRadians(point1.longitude);
    double lon2 = degreesToRadians(point2.longitude);
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              MyHomePage();
            },
          );

          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void checkAlarm() {
    if (currentLocation != null) {
      log("checking alarm");
      for (var alarm in alarms) {
        if (alarm.isEnabled == false) {
          continue;
        }
        double distance = calculateDistance(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          LatLng(alarm.lat, alarm.lng),
        );
        log('$distance-${alarm.locationRadius}');

        if (distance <= alarm.locationRadius) {
          log('triggering');
          // Alarm is triggered

          break; // Exit loop after triggering the first alarm
        }
      }
    }
  }

  LatLng? _target = null;

  Future markLocation() async {
    // double radius = radius;
    Marker? current;
    ByteData byteData = await rootBundle.load('assets/locationmark10.png');
    Uint8List imageData = byteData.buffer.asUint8List();
    // Create a BitmapDescriptor from the image data
    BitmapDescriptor customIcon = BitmapDescriptor.fromBytes(imageData);
    setState(() {
      if (_markers.isNotEmpty) {
        current = _markers.first;
      }
      _markers.clear();
      _circles.clear();
      if (current != null) {
        _markers.add(current!);
      }

      if (widget.alarm != null) {
        AlarmDetails alarmDetails =
            alarms.firstWhere((element) => element.id == widget.alarm!.id);

        // Add marker for alarm
        _markers.add(Marker(
          markerId: MarkerId(alarmDetails.id),
          // Use the same ID for the marker
          icon: customIcon,
          position: LatLng(alarmDetails.lat, alarmDetails.lng),
          draggable: true,

          // Enable marker dragging
          onDragEnd: (newPosition) async {
            setState(() {
              AlarmDetails old = alarms
                  .firstWhere((element) => element.id == widget.alarm!.id);
              old.lat = newPosition.latitude;
              old.lng = newPosition.longitude;
              alarms.removeWhere((element) => element.id == widget.alarm!.id);
              alarms.add(old);
            });
            List<Placemark> placemarks = await placemarkFromCoordinates(
                newPosition.latitude, newPosition.longitude);

            // Extract the location name from the placemark
            String locationName = placemarks.isEmpty
                ? 'Default'
                : [
                    placemarks[0].name,
                    placemarks[0].subLocality,
                    placemarks[0].locality,
                  ]
                    .toList()
                    .where((element) => element != null && element != '')
                    .join(', ');

            // Update the alarm name controller with the location name (optional)
            alramnamecontroller.text = locationName;

            SharedPreferences prefs = await SharedPreferences.getInstance();
            List<Map<String, dynamic>> alarmsJson =
                alarms.map((alarm) => alarm.toJson()).toList();
            await prefs.setStringList(
                'alarms', alarmsJson.map((json) => jsonEncode(json)).toList());

            await loadData();
            await markLocation();
            _showCustomBottomSheet(
              context,
            );
          },
        ));
        print("locationradius:" + widget.alarm!.locationRadius.toString());
        // Add circle for alarm
        _circles.add(Circle(
          circleId: CircleId(alarmDetails.id),
          // Use the same ID for the circle
          center: LatLng(alarmDetails.lat, alarmDetails.lng),
          radius: alarmDetails.locationRadius,
          // Set your desired radius in meters
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ));
      } else {
        // Add markers and circles for all alarms
        _markers.addAll(
          alarms.map((AlarmDetails alarm) => Marker(
                markerId: MarkerId(alarm.id),
                // Use unique IDs for markers
                icon: customIcon,
                position: LatLng(alarm.lat, alarm.lng),
                draggable: true,
                // Enable marker dragging
                onDragEnd: (newPosition) async {
                  setState(() {
                    AlarmDetails old =
                        alarms.firstWhere((element) => element.id == alarm.id);
                    old.lat = newPosition.latitude;
                    old.lng = newPosition.longitude;
                    alarms.removeWhere((element) => element.id == alarm.id);
                    alarms.add(old);
                  });

                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  List<Map<String, dynamic>> alarmsJson =
                      alarms.map((alarm) => alarm.toJson()).toList();
                  await prefs.setStringList('alarms',
                      alarmsJson.map((json) => jsonEncode(json)).toList());
                  await loadData();
                  await markLocation();
                },
              )),
        );
        _circles.addAll(
          alarms.map((AlarmDetails alarm) => Circle(
                circleId: CircleId(alarm.id),
                // Use unique IDs for circles
                center: LatLng(alarm.lat, alarm.lng),
                radius: alarm.locationRadius,
                // Set your desired radius in meters
                fillColor: Colors.blue.withOpacity(0.3),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              )),
        );
      }
    });
  }

  void saveAlarm(BuildContext context) async {
    print(
      "locationradius:" + radius.toString(),
    );

    setState(() {
      AlarmDetails newAlarm = AlarmDetails(
        alarmName: alramnamecontroller.text,
        notes: notescontroller.text,
        locationRadius: radius,
        isAlarmOn: true,
        isFavourite: false,
        lat: _target!.latitude,
        lng: _target!.longitude,
        id: Uuid().v4(),
        isEnabled: true,
      );
      alarms.add(newAlarm);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> alarmsJson =
        alarms.map((alarm) => alarm.toJson()).toList();
    await prefs.setStringList(
        'alarms', alarmsJson.map((json) => jsonEncode(json)).toList());

    loadData();
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyAlarmsPage(),
      ),
    );
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String alarmName = alramnamecontroller.text;
    String notes = notescontroller.text;
    double radius = widget.alarm!.locationRadius;
    ; // Assuming you have a way to get the radius
    // Save data to SharedPreferences
    await prefs.setString('alarmName', alarmName);
    await prefs.setDouble('radius', radius);
    await prefs.setString('notes', notes);
    List<String>? alarmsJson = prefs.getStringList('alarms');
    print("alarms");
    print(alarmsJson);
    setState(() {
      if (alarmsJson != null) {
        alarms = alarmsJson
            .map((json) => AlarmDetails.fromJson(jsonDecode(json)))
            .toList();
      } else {
        alarms = [];
      }
    });
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      setState(() {});
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      setState(() {});
    }
  }

  TextEditingController notescontroller = TextEditingController();

  // Initialize the TextEditingController with the default value
  TextEditingController alramnamecontroller =
      TextEditingController(text: "Welcome");

  LatLngBounds _calculateMarkerBounds(LatLng current, LatLng target) {
    return LatLngBounds(
      southwest: LatLng(
        current.latitude < target.latitude ? current.latitude : target.latitude,
        current.longitude < target.longitude
            ? current.longitude
            : target.longitude,
      ),
      northeast: LatLng(
        current.latitude > target.latitude ? current.latitude : target.latitude,
        current.longitude > target.longitude
            ? current.longitude
            : target.longitude,
      ),
    );
  }

  LatLngBounds padLatLngBounds(LatLngBounds bounds, double padding) {
    double latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
    double lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;
    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - padding * latDiff,
          bounds.southwest.longitude - padding * lngDiff),
      northeast: LatLng(bounds.northeast.latitude + padding * latDiff,
          bounds.northeast.longitude + padding * lngDiff),
    );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    location.PermissionStatus permissionStatus =
        await _locationService.hasPermission();
    if (permissionStatus == location.PermissionStatus.denied) {
      permissionStatus = await _locationService.requestPermission();
      if (permissionStatus != location.PermissionStatus.granted) {
        return;
      }
      _startLocationUpdates();
    }

    LatLng? _current = LatLng(13.067439, 80.237617);
    _target = LatLng(widget.alarm!.lat, widget.alarm!.lng);
    log("location 1");
    _locationService.onLocationChanged
        .listen((location.LocationData newLocation) async {
      log("location changed");
      if (_isCameraMoving) return;
      setState(() {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          _current = LatLng(newLocation.latitude!, newLocation.longitude!);
          setState(() {
            _isLoading = false;
          });
        }
        currentLocation = newLocation;
        _markers.clear();
        _markers.add(Marker(
          markerId: MarkerId("_currentLocation"),
          icon: BitmapDescriptor.defaultMarker,
          position: currentLocation != null
              ? LatLng(currentLocation!.latitude!, currentLocation!.longitude!)
              : _defaultLocation,
        ));
        // _isLoading = false;
        // print("loader will be stop");
      });

      await markLocation();
      setState(() {
        _isLoading = false;
        print("loader will be stop");
      });
      if (mapController != null && !isAnimated) {
        isAnimated = true;
        LatLngBounds markerBounds = _calculateMarkerBounds(_current!, _target!);

        // Animate camera to fit both markers with some padding
        double padding = 50.0; // Adjust padding as needed (in pixels)
        CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(
          padLatLngBounds(markerBounds, 0.10), // 10% padding
          padding,
        );
        await mapController!.animateCamera(cameraUpdate);
        setState(() {
          _isLoading = false;
          print("loader will be stop");
        });
      }
      print("alarm ring");
      checkAlarm();
    });
    log("location 2");
  }

  void _showCustomBottomSheet(BuildContext context) async {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    loadData();
    alramnamecontroller.text;
    notescontroller.text = widget.alarm!.notes;
    //  notescontroller.clear();
    List<AlarmDetails> alarms = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? alarmsJson = prefs.getStringList('alarms');
    if (alarmsJson != null) {
      alarms = alarmsJson
          .map((json) => AlarmDetails.fromJson(jsonDecode(json)))
          .toList();
    } else {
      alarms = [];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        String counterText;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: height / 1.9384615384615,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // Call the saveAlarm function
                      },
                      child: Text("Cancel"),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: width / 3),
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          int index = alarms.indexWhere(
                              (alarm) => alarm.id == widget.alarm!.id);
                          if (index == -1) {
                            // Alarm not found, handle error (optional)
                            return;
                          }
                          // Get values from UI elements
                          String newAlarmName = alramnamecontroller.text;
                          String newNotes = notescontroller.text;
                          double newRadius = radius;
                          // Update the alarm details
                          alarms[index].alarmName = newAlarmName;
                          alarms[index].notes = newNotes;
                          alarms[index].locationRadius = newRadius;

                          // Save the updated list of alarms as JSON strings
                          List<Map<String, dynamic>> alarmsJson =
                              alarms.map((alarm) => alarm.toJson()).toList();
                          await prefs.setStringList(
                              'alarms',
                              alarmsJson
                                  .map((json) => jsonEncode(json))
                                  .toList());

                          // Optionally, clear UI elements or navigate to MyAlarmsPage
                          alramnamecontroller.text = '';
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Success"),
                                  content:
                                      Text("Location changed successfully."),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () async {
                                        await _interstitialAd?.show();
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MyAlarmsPage()),
                                        );
                                      },
                                      child: Text("OK"),
                                    ),
                                  ],
                                );
                              });
                        },
                        child: Text("Save"),
                      ),
                    ),
                  ],
                ),

                // Integrate the MeterCalculatorWidget
                MeterCalculatorWidget(
                  callback: updateradiusvalue,
                  //radius: widget.alarm?.locationRadius,
                ),

                Padding(
                  padding: EdgeInsets.only(left: width / 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Align text to the start horizontally
                    children: [
                      Text(
                        "Alarm Name:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        //height: 70,
                        width: width / 1.1612903225806,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: width / 22.5, right: width / 22.5),
                          child: TextField(
                            textAlign: TextAlign.start,
                            // keyboardType: TextInputType.multiline,
                            maxLines: 2,
                            controller: alramnamecontroller,
                            // Set the desired number of lines for multi-line input
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: "Alarmname",
                              border: InputBorder.none,
                              // Remove borders if desired (optional)
                              enabledBorder: InputBorder
                                  .none, // Remove borders if desired (optional)
                              // Show current character count and limit
                            ),
                            maxLength: 50,
                            onChanged: (value) => counterText =
                                '${alramnamecontroller.text.length}/50', // Set the maximum allowed characters
                          ),
                        ),
                      ),
                      //Text("Alarmname cannot exceed 50 words",style: Theme.of(context).textTheme.bodySmall,),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Notes:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        //height: 70,
                        width: width / 1.1612903225806,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: width / 22.5, right: width / 22.5),
                          child: TextField(
                            textAlign: TextAlign.start,
                            // keyboardType: TextInputType.multiline,
                            maxLines: 2,
                            controller: notescontroller,
                            // Set the desired number of lines for multi-line input
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: "Notes",
                              border: InputBorder.none,
                              // Remove borders if desired (optional)
                              enabledBorder: InputBorder
                                  .none, // Remove borders if desired (optional)
                              // Show current character count and limit
                            ),
                            maxLength: 150,
                            onChanged: (value) => counterText =
                                '${notescontroller.text.length}/150', // Set the maximum allowed characters
                          ),
                        ),
                      ),
                      //Text("Notes cannot exceed 150 words",style: Theme.of(context).textTheme.bodySmall,),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startLocationUpdates() {
    _locationService.onLocationChanged
        .listen((location.LocationData newLocation) async {});
  }

  Future<void> initializeNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
            'ic_notification'); //TODO: Replace 'icon' with your notification icon resource name

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  final Uri toLaunch =
      Uri(scheme: 'https', host: 'www.cylog.org', path: 'headers/');

  Future<void> _goToCurrentLocation() async {
    if (currentLocation == null) {
      await _requestLocationPermission();

      return; // Wait for location to be updated
    }

    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          3000.0, // Adjust zoom level as needed
        ),
      );

      // Ensure loader hides after 10 seconds, even if other operations take longer
      Future.delayed(const Duration(seconds: 50), () {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  int screenIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading == true
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  circles: _circles,
                  zoomGesturesEnabled: true,
                  mapType: MapType.normal,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                    zoom: 13,
                    target: _defaultLocation,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    isMapInitialized = true;
                  },
                  markers: _markers,
                  onCameraMoveStarted: () {
                    setState(() {
                      _isCameraMoving = false;
                    });
                  },
                  onCameraIdle: () {
                    setState(() {
                      _isCameraMoving = false;
                    });
                  },
                ),
          Positioned(
            right: 24, bottom: 120,
            // padding:  EdgeInsets.only(top:height/1.68,left: 280),
            child: IconButton.filledTonal(
              onPressed: () {
                _goToCurrentLocation();
                setState(() {
                  _isLoading = false;
                });
              },
              icon: Icon(Icons.my_location),
              // child: Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 72,
            right: 24,
            child: IconButton.filledTonal(
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.zoomIn(),
                );
              },
              icon: Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: IconButton.filledTonal(
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.zoomOut(),
                );
              },
              icon: Icon(Icons.remove),
            ),
          ),
          Positioned(
              top: 50,
              left: 15,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
              )),
          _bannerAd != null
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 50,
                    color: Colors.transparent,
                  ),
                )
        ],
      ),
    );
  }
}

class MeterCalculatorWidget extends StatefulWidget {
  final Function(double) callback;
  final double? radius;

  const MeterCalculatorWidget({
    Key? key,
    required this.callback,
    this.radius,
  }) : super(key: key);

  @override
  _MeterCalculatorWidgetState createState() => _MeterCalculatorWidgetState();
}

class _MeterCalculatorWidgetState extends State<MeterCalculatorWidget> {
  double _radius = 200;
  bool _imperial = false;
  double meterRadius = 100; // Initial value for meter radius
  double milesRadius = 0.10;

  @override
  void initState() {
    _loadSelectedUnit();
    // _loadRadiusData();
    super.initState();
  }

  Future<void> _loadSelectedUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedUnit = prefs.getString('selectedUnit');
    double meterdefault = prefs.getDouble('meterRadius') ?? 2000;
    double milesdefault = prefs.getDouble('milesRadius') ?? 1.04;
    print("metersdefault:" + meterdefault.toString());
    print("milesdefault:" + milesdefault.toString());
    setState(() {
      _imperial = (selectedUnit == 'Imperial system (mi/ft)');
      _radius = widget.radius ?? (_imperial ? milesdefault : meterdefault);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Radius',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: EdgeInsets.only(left: width / 2.5714),
              child: Text((_radius / (_imperial ? 1 : 1000))
                      .toStringAsFixed(_imperial ? 2 : 2) +
                  ' ${_imperial ? 'miles' : 'Kilometers'}'),
            ),
          ],
        ),
        Container(
          width: width / 1.16129,
          child: Slider(
            // Adjust max value according to your requirement
            value: _radius,
            divisions: 100,
            min: _imperial ? milesRadius : meterRadius,
            max: _imperial ? 2.00 : 3000,
            onChanged: (value) {
              widget.callback(_imperial ? (value * 1609.34) : value);
              print("kmvalue:" + value.toString());
              print("metercalculatedvalue:" + value.toString());
              setState(() {
                _radius = double.parse(value.toStringAsFixed(2));
                print("Radius:" + _radius.toString());
              });
            },
          ),
        ),
      ],
    );
  }
}
