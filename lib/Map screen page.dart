// import 'package:flutter/painting.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:typed_data';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_places_flutter/google_places_flutter.dart';
// import 'package:google_places_flutter/model/prediction.dart';
// import 'package:location/location.dart' as location;
// import 'package:geocoding/geocoding.dart' as geocoding;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:untitiled/Homescreens/settings.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:uuid/uuid.dart';
// import 'Apiutils.dart';
// import 'Homescreens/save_alarm_page.dart';
// import 'about page.dart';
//
//
//
// class MyHomePage extends StatefulWidget {
//
//
//
//   final String? title;
//
//   const MyHomePage({super.key,  this.title, });
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
// class _MyHomePageState extends State<MyHomePage> {
//   double meterRadius = 100; // Initial value for meter radius
//   double milesRadius = 0.31;
//   Future<void> _loadRadiusData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       meterRadius = prefs.getDouble('meterRadius') ?? 0.0;
//       milesRadius = prefs.getDouble('milesRadius') ?? 0.0;
//     });
//   }
//
//   var latlong;
//   double radius=0;
//   Future<void> _goToCurrentLocation() async {
//     if (currentLocation == null) {
//
//       await _requestLocationPermission();
//
//       return; // Wait for location to be updated
//     }
//
//     if (mapController != null) {
//       await mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
//           15.0, // Adjust zoom level as needed
//         ),
//       );
//     }
//   }
//   updateradiusvalue(value){
//     print("value:"+value.toString());
//     setState(() {
//       radius=value;
//     });
//   }
//   bool _hasCallSupport = false;
//   Future<void>? _launched;
//   String _phone = '';
//   final Uri toLaunch =
//   Uri(scheme: 'https', host: 'www.cylog.org', path: 'headers/');
//   TextEditingController controller = TextEditingController();
//   GoogleMapController? mapController;
//   location.LocationData? currentLocation;
//   location.Location _locationService = location.Location();
//   bool _isCameraMoving = true;
//
//   final LatLng _defaultLocation = const LatLng(
//       13.067439, 80.237617); // Default location
//
//   TextEditingController searchController = TextEditingController();
//   List<AlarmDetails> alarms = [];
//   @override
//   void initState() {
//     super.initState();
//     _requestLocationPermission();
//     alramnamecontroller.text="Welcome";
//     _loadRadiusData();
//     loadData();
//
//   }
//
//   Future<void> loadData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     List<String>? alarmsJson = prefs.getStringList('alarms');
//
//     if (alarmsJson != null) {
//       alarms = alarmsJson.map((json) => AlarmDetails.fromJson(jsonDecode(json))).toList();
//     } else {
//       alarms = [];
//     }
//
//     setState(() {});
//   }
//
//
//
//   Future<void> _requestLocationPermission() async {
//     bool serviceEnabled = await _locationService.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _locationService.requestService();
//       if (!serviceEnabled) {
//         return;
//       }
//     }
//
//     location.PermissionStatus permissionStatus = await _locationService
//         .hasPermission();
//     if (permissionStatus == location.PermissionStatus.denied) {
//       permissionStatus = await _locationService.requestPermission();
//       if (permissionStatus != location.PermissionStatus.granted) {
//         return;
//       }
//     }
//
//
//     log("location 1");
//     _locationService.onLocationChanged.listen((
//         location.LocationData newLocation) async {
//       log("location changed");
//       if (_isCameraMoving) return;
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       if(mounted) {
//         setState(() {
//           if (newLocation.latitude != null && newLocation.longitude != null) {
//             _current = LatLng(newLocation.latitude!, newLocation.longitude!);
//           }
//           currentLocation = newLocation;
//
//           prefs.setDouble('current_latitude', newLocation.latitude!);
//           prefs.setDouble('current_longitude', newLocation.longitude!);
//
//           // Example usage: retrieve the stored location later
//           double? storedLatitude = prefs.getDouble('current_latitude');
//           double? storedLongitude = prefs.getDouble('current_longitude');
//           if (storedLatitude != null && storedLongitude != null) {
//             print('Stored location: ($storedLatitude, $storedLongitude)');
//             Marker? tap = _markers.length > 1 ? _markers.last : null;
//
//             _markers.clear();
//             _markers.add(Marker(
//               markerId: MarkerId("_currentLocation"),
//               icon: BitmapDescriptor.defaultMarker,
//               position: currentLocation != null
//                   ? LatLng(
//                   currentLocation!.latitude!, currentLocation!.longitude!)
//                   : _defaultLocation,
//             ));
//             if (tap != null) {
//               _markers.add(tap);
//             }
//           }
//         });
//       }
//
//       if (mapController != null && _markers.length<2) {
//         mapController!.animateCamera(CameraUpdate.newLatLng(
//           LatLng(newLocation.latitude!, newLocation.longitude!),
//         ));
//       }
//     });
//     log("location 2");
//   }
//
//
//   Future<void> _moveToLocation(String locationName) async {
//     List<geocoding.Location> locations = await geocoding.locationFromAddress(
//         locationName);
//     if (locations.isNotEmpty) {
//       LatLng destination = LatLng(
//           locations[0].latitude!, locations[0].longitude!);
//
//       if (mapController != null) {
//         mapController!.animateCamera(CameraUpdate.newLatLng(destination));
//       }
//     }
//   }
//   Set<Marker> _markers={};
//
//   LatLng? _current = const LatLng(
//       13.067439, 80.237617);
//   LatLng? _target = null;
//   bool _handletap = false;
//   TextEditingController notescontroller = TextEditingController();
//   // Initialize the TextEditingController with the default value
//   TextEditingController alramnamecontroller = TextEditingController(text: "Welcome");
//   Future<void> _launchInBrowser(Uri url) async {
//     if (!await launchUrl(
//       url,
//       mode: LaunchMode.externalApplication,
//     )) {
//       throw Exception('Could not launch $url');
//     }
//   }
//   String _appBarTitle = '';
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   int screenIndex=1;
//   void handleScreenChanged(int index) {
//     switch (index) {
//       case 0: // Alarm List
//         Navigator.of(context).push(
//             MaterialPageRoute(builder: (context) => MyAlarmsPage()));
//         // Replace with your AlarmListPage widget
//         break;
//       case 1: // Alarm List
//         Navigator.of(context).push(
//             MaterialPageRoute(builder: (context) => MyHomePage()));
//
//         // Replace with your AlarmListPage widget
//         break;
//
//       case 2: // Saved Alarms
//         Navigator.of(context).push(
//             MaterialPageRoute(builder: (context) => Settings())); // Replace with your SavedAlarmsPage widget
//         break;
//       case 3:
//         final RenderBox box = context.findRenderObject() as RenderBox;
//         Rect dummyRect = Rect.fromCenter(center: box.localToGlobal(Offset.zero), width: 1.0, height: 1.0);
//         Share.share(
//           'Check out my awesome app: ! Download it from the app store: ',
//           subject: 'Share this amazing app!',
//           sharePositionOrigin: dummyRect,
//         );
//         break;
//       case 4:
//
//         _launchInBrowser(toLaunch);
//
//
//         break;
//       case 5:
//
//         Navigator.of(context).push(
//             MaterialPageRoute(builder: (context) => About()));
//
//         break;
//
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//         double height=MediaQuery.of(context).size.height;
//         double width=MediaQuery.of(context).size.width;
//     final Uri toLaunch =
//     Uri(scheme: 'https', host: 'www.google.com');
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: NavigationDrawer(
//         onDestinationSelected: (int index) {
//           handleScreenChanged(index); // Assuming you have a handleScreenChanged function
//         },
//         selectedIndex: screenIndex,
//         children: <Widget>[
//           SizedBox(
//             height: 32,
//           ),
//           NavigationDrawerDestination(
//
//             icon: Icon(Icons.alarm_on_outlined), // Adjust size as needed
//             label: Text('Saved Alarms'),
//             // Set selected based on screenIndex
//           ),
//           NavigationDrawerDestination(
//             icon: Icon(Icons.alarm),
//             label: Text('Set a Alarm'),
//             // Set selected based on screenIndex
//           ),
//           NavigationDrawerDestination(
//             icon: Icon(Icons.settings_outlined),
//             label: Text('Settings'),
//             // Set selected based on screenIndex
//           ),
//           Divider(),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
//             child: Text(
//               'Communicate', // Assuming this is the header
//               style: Theme.of(context).textTheme.titleSmall,
//             ),
//           ),
//           NavigationDrawerDestination(
//             icon: Icon(Icons.share_outlined),
//             label: Text('Share'),
//
//             // Set selected based on screenIndex
//           ),
//           NavigationDrawerDestination(
//             icon: Icon(Icons.rate_review_outlined),
//             label: Text('Rate/Review'),
//             // Set selected based on screenIndex
//           ),
//           Divider(),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
//             child: Text(
//               'App', // Assuming this is the header
//               style: Theme.of(context).textTheme.titleSmall,
//             ),
//           ),
//           NavigationDrawerDestination(
//             icon: Icon(Icons.error_outline_outlined),
//             label: Text('About'),
//             // Set selected based on screenIndex
//           ),
//         ],
//       ),
//
//
//       body: Stack(
//         children: [
//           GoogleMap(
//
//             mapType: MapType.normal,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             initialCameraPosition: CameraPosition(
//               zoom: 15,
//               target: _defaultLocation,
//             ),
//             onMapCreated: (GoogleMapController controller) {
//               mapController = controller;
//             },
//             markers: _markers,
//             onLongPress: _handleTap,
//
//
//             onCameraMoveStarted: () {
//               setState(() {
//                 _isCameraMoving = true;
//               });
//             },
//             onCameraIdle: () {
//               setState(() {
//                 _isCameraMoving = false;
//               });
//             },
//
//           ),
//           Positioned(
//             top: 50,
//             left: 70,
//             right: 20,
//             child:
//             // Material(
//             //
//             //   child: Container(
//             //
//             //     height: 50,
//             //     decoration: BoxDecoration(
//             //       color: Colors.white,
//             //
//             //       borderRadius: BorderRadius.circular(30),
//             //     ),
//             //     child:
//             //
//
//               placesAutoCompleteTextField(),),
//
//
//
//
//
//           Padding(
//             padding: const EdgeInsets.only(top: 100.0,left: 100),
//             child: Container(
//               height:height/ 25.2,
//               width:width/ 1.8,
//               decoration: BoxDecoration(
//                 color: Colors.white70,
//                 border: Border.all(
//                   color: Colors.black,
//                 ),
//                 borderRadius: BorderRadius.circular(10),
//               ), child: Center(child: Text("or long press on the map")),),
//           ),
//           Positioned(
//             right: 24,bottom: 120,
//             // padding:  EdgeInsets.only(top:height/1.68,left: 280),
//             child:IconButton.filledTonal(
//
//               onPressed: _goToCurrentLocation,
//               icon: Icon(Icons.my_location),
//               // child: Icon(Icons.my_location),
//             ),
//           ),
//           Positioned(
//             bottom: 72,right: 24,
//             // padding: const EdgeInsets.only(left: 280.0,top: 500),
//             child: IconButton.filledTonal(
//               onPressed: () {
//                 mapController?.animateCamera(
//                   CameraUpdate.zoomIn(),
//                 );
//               },
//               icon: Icon(Icons.add),
//             ),
//           ),
//           Positioned(
//             bottom: 24,right: 24,
//
//             // padding: const EdgeInsets.only(left: 280.0,top: 600),
//             child: IconButton.filledTonal(
//               onPressed: () {
//                 mapController?.animateCamera(
//                   CameraUpdate.zoomOut(),
//                 );
//               },
//               icon: Icon(Icons.remove),
//             ),
//           ),
//           Positioned(
//             top: 50,left: 15,
//               child: IconButton(
//                 onPressed: () { _scaffoldKey.currentState?.openDrawer(); }, icon: Icon(Icons.menu),)),
//
//         ],
//       ),
//     );
//   }
//   void _showCustomBottomSheet(BuildContext context)async {
//     double height=MediaQuery.of(context).size.height;
//     double width=MediaQuery.of(context).size.width;
//     if (!_handletap) {
//
//       // Show a snackbar if a destination is not selected
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select a destination on the map.'),
//         ),
//       );
//       return;
//     }
//     loadData();
//     alramnamecontroller.text=_appBarTitle;
//     notescontroller.clear();
//     List<AlarmDetails> alarms = [];
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     List<String>? alarmsJson = prefs.getStringList('alarms');
//
//     if (alarmsJson != null) {
//       alarms = alarmsJson.map((json) => AlarmDetails.fromJson(jsonDecode(json))).toList();
//     } else {
//       alarms = [];
//     }
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Container(
//
//             height: height/2.29090,
//             width: double.infinity,
//
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//
//                     OutlinedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop(); // Call the saveAlarm function
//                       },
//                       child: Text("Cancel"),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 120.0),
//                       child: FilledButton(
//                         onPressed: () {
//                           saveAlarm(context); // Call the saveAlarm function
//                         },
//                         child: Text("Set"),
//                       ),
//                     ),
//
//                     // ElevatedButton(
//                     //   onPressed: () {
//                     //     // Add your start logic here
//                     //   },
//                     //   style: ElevatedButton.styleFrom(
//                     //     backgroundColor: Color(0xffFFEF9A9A),
//                     //   ),
//                     //   child: Text('Start'),
//                     // ),
//                   ],
//                 ),
//
//                 // Integrate the MeterCalculatorWidget
//                 MeterCalculatorWidget(
//                   callback: updateradiusvalue,
//
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Alarm Name:", style: Theme.of(context).textTheme.titleMedium,),
//
//                     Container(
//                       height:height/ 15.12,
//                       width: width/1.2,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.black12),
//
//                       ),child: Padding(
//                       padding:  EdgeInsets.only(left: width/36),
//                       child: TextField(
//                         controller: alramnamecontroller,
//
//                         style: Theme.of(context).textTheme.bodyMedium,
//                         decoration: InputDecoration(
//                           hintText: "Alarm name",
//                           border: InputBorder.none,
//                           enabledBorder: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                     ),
//
//
//                     Text("Notes:",style: Theme.of(context).textTheme.titleMedium,),
//
//                     Container(
//                       height: height/10.8,
//                       width:width/1.2,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.black12),
//
//                       ),child: Padding(
//                       padding:  EdgeInsets.only(left: width/36),
//                       child: TextField(
//                         controller: notescontroller,
//                         style: Theme.of(context).textTheme.bodyMedium,
//                         decoration: InputDecoration(
//                           hintText: "Notes",
//                           border: InputBorder.none,
//                           enabledBorder: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                     ),
//
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//   void saveAlarm(BuildContext context) async {
//     if (alramnamecontroller.text.isEmpty ||
//
//         radius == null) {
//       Navigator.of(context).pop();
//       // Show a Snackbar prompting the user to fill in the required fields
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please fill in all the required fields.'),
//
//         ),
//       );
//       return; // Exit the function without saving the data
//     }
//     print("locationradius:" +radius.toString(),);
//
//     setState(() {
//
//       AlarmDetails newAlarm = AlarmDetails(
//         alarmName: alramnamecontroller.text,
//         notes: notescontroller.text,
//         locationRadius:  radius,
//         isAlarmOn: true, isFavourite: false, lat: _target!.latitude, lng: _target!.longitude, id:Uuid().v4(), isEnabled: true,
//       );
//       alarms.add(newAlarm);
//     });
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<Map<String, dynamic>> alarmsJson =
//     alarms.map((alarm) => alarm.toJson()).toList();
//     await prefs.setStringList(
//         'alarms', alarmsJson.map((json) => jsonEncode(json)).toList());
//
//     loadData();
//     Navigator.of(context).pop();
//
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => MyAlarmsPage(
//         ),
//       ),
//     );
//   }
//   placesAutoCompleteTextField() {
//     return Material(
//
//       borderRadius: BorderRadius.circular(30.0),
//       child: Container(
//
//
//         // padding: EdgeInsets.symmetric(horizontal: 10),
//         child: GooglePlaceAutoCompleteTextField(
//           textEditingController: controller,
//           googleAPIKey: "AIzaSyA3byIibe-X741Bw5rfEzOHZEKuWdHvCbw",
//           // boxDecoration: BoxDecoration(
//           //   borderRadius: BorderRadius.circular(double.infinity),
//           // ),
//           boxDecoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(30.0), // Adjust the radius as needed
//            // border: Border.all(color: Colors.black26), // Add border color
//           ),
//           inputDecoration: InputDecoration(
//
//             hintText: "Alarm location",
//             border: InputBorder.none,
//             suffixIcon: Icon(Icons.search,size: 25,color: Colors.black,),
//             enabledBorder: InputBorder.none,
//           ),
//           debounceTime: 400,
//           countries: ["in", "fr"],
//           isLatLngRequired: true,
//           getPlaceDetailWithLatLng: (Prediction prediction) async {
//             print("placeDetails" + prediction.lat.toString());
//             print("placeDetails - Lat: ${prediction.lat}, Lng: ${prediction.lng}");
//             double lat = double.parse(prediction.lat!);
//             double lng = double.parse(prediction.lng!);
//             // // Call _handleTap to add a marker at the selected location
//             await _handleTap(LatLng(lat,lng ));
//             if (mapController != null) {
//               mapController!.animateCamera(CameraUpdate.newLatLng(
//                 LatLng(lat, lng),
//               ));
//             }
//           },
//
//           // itemClick: (Prediction prediction) async {
//           //   print(prediction.lat);
//           //   print(prediction.lng);
//           //
//           //  await _handleTap(LatLng(prediction.lat as double, prediction.lng as double));
//           //   controller.text = prediction.description ?? "";
//           //   controller.selection = TextSelection.fromPosition(
//           //       TextPosition(offset: prediction.description?.length ?? 0));
//           // },
//           itemClick: (Prediction prediction) async {
//             // Extract the latitude and longitude from the prediction
//
//             print("enter");
//
//             // Set the text field value to the prediction description
//             controller.text = prediction.description ?? "";
//             controller.selection = TextSelection.fromPosition(
//                 TextPosition(offset: prediction.description?.length ?? 0));
//           },
//
//
//
//           seperatedBuilder: Divider(),
//           containerHorizontalPadding: 10,
//
//           // OPTIONAL// If you want to customize list view item builder
//           itemBuilder: (context, index, Prediction prediction) {
//             return Container(
//               padding: EdgeInsets.all(10),
//               child: Row(
//                 children: [
//                   Icon(Icons.location_on),
//                   SizedBox(
//                     width: 7,
//                   ),
//                   Expanded(child: Text("${prediction.description ?? ""}"))
//                 ],
//               ),
//             );
//           },
//
//           isCrossBtnShown: true,
//
//           // default 600 ms ,
//         ),
//       ),
//     );
//   }
//   _handleTap(LatLng point) async {
//
//     _handletap=true;
//     ByteData byteData = await rootBundle.load('assets/locationimage.png');
//     Uint8List imageData = byteData.buffer.asUint8List();
//
//     // Create a BitmapDescriptor from the image data
//     BitmapDescriptor customIcon = BitmapDescriptor.fromBytes(imageData);
//     setState(() {
//       _target=point;
//       Marker? tap = _markers.isNotEmpty ? _markers.first : null;
//
//       _markers.clear();
//       if(tap != null) {
//         _markers.add(tap);
//       }
//       // Convert the set to a list
//       List<Marker> markerList = _markers.toList();
//
//       // Load the custom icon image
//
//
//       // Add a new marker with the custom icon
//       markerList.add(Marker(
//         markerId: MarkerId(point.toString()),
//         position: point,
//         infoWindow: InfoWindow(
//           title: _appBarTitle,
//         ),
//         icon: customIcon,
//       ));
//
//       // Convert the list back to a set
//       _markers = markerList.toSet();
//     });
//
//     // Perform reverse geocoding to get the address from coordinates
//     List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
//
//     // Extract the location name from the placemark
//     String name = placemarks.isEmpty ? 'Default' : [
//       placemarks[0].name,
//       placemarks[0].subLocality,
//       placemarks[0].locality,
//     ].toList()
//         .where((element) => element != null && element != '')
//         .join(', ');
//     String locationName = name;
//
//     // Update the app bar title with the location name
//     setState(() {
//       _appBarTitle = locationName;
//     });
//
//     _showCustomBottomSheet(context);
//   }
// }
//
// class MeterCalculatorWidget extends StatefulWidget {
//   final Function(double) callback;
//
//   const MeterCalculatorWidget({
//     Key? key,
//     required this.callback,
//   }) : super(key: key);
//
//   @override
//   _MeterCalculatorWidgetState createState() => _MeterCalculatorWidgetState();
// }
// class _MeterCalculatorWidgetState extends State<MeterCalculatorWidget> {
//   double _radius = 200;
//   bool _imperial = false;
//
//   @override
//   void initState() {
//     _loadSelectedUnit();
//     super.initState();
//   }
//
//   Future<void> _loadSelectedUnit() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? selectedUnit = prefs.getString('selectedUnit');
//     double meterdefault = prefs.getDouble('meterRadius')?? 2000;
//     double milesdefault = prefs.getDouble('milesRadius')?? 1.04;
//   print(meterdefault);
//   print(milesdefault);
//     setState(() {
//       _imperial = (selectedUnit == 'Imperial system (mi/ft)');
//       _radius = _imperial ? milesdefault : meterdefault;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double height=MediaQuery.of(context).size.height;
//     double width=MediaQuery.of(context).size.width;
//     return Column(
//       children: [
//         Row(
// mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Text(
//               'Radius',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             Padding(
//               padding:  EdgeInsets.only(left:width/2.5714),
//               child:
//              // Text((_radius).toStringAsFixed(_imperial ? 0:(0))+' ${_imperial ? 'miles' : 'Kilometers'}'),
//               Text(
//                   (_radius / (_imperial ? 1 : 1000)).toStringAsFixed(_imperial ? 2 : 0) +
//                       ' ${_imperial ? 'miles' : 'Kilometers'}'
//               ),
//             ),
//           ],
//         ),
//         Container(
//           width:width/1.16129,
//           child: Slider(
//              // Adjust max value according to your requirement
//             value: _radius,
//             divisions: 100,
//             min: _imperial ? 0.05 : 50,
//             max: _imperial ? 5.05 : 5000,
//             onChanged: (value) {
//               print("metercalculatedvalue:"+value.toString());
//               setState(() {
//                 _radius = double.parse(value.toStringAsFixed(2));
//               });
//               widget.callback(_imperial? (value * 1609.34):(value));
//             },
//           ),
//         ),
//         // Container(
//         //   width: width / 1.16129,
//         //   child: Slider(
//         //     value: _radius, // Ensure _radius is within the adjusted min-max range
//         //     divisions: 100,
//         //     min: _imperial ? 1.0 : 0.001, // Set minimum radius to 1 mile/1 meter
//         //     max: _imperial ? 3.0 : 3.0,   // Set maximum radius to 3 miles/3 km
//         //     onChanged: (value) {
//         //       setState(() {
//         //         // Clamp the value within the min-max range
//         //         _radius = value.clamp(_imperial ? 1.0 : 0.001, _imperial ? 3.0 : 3.0);
//         //       });
//         //       widget.callback(_imperial? (value * 1609.34):(value/1000));
//         //     },
//         //   ),
//         // ),
//       ],
//     );
//   }
// }
// class MeterCalculatorWidget extends StatefulWidget {
//   final Function(double) callback;
//
//   const MeterCalculatorWidget({
//     Key? key,
//     required this.callback,
//   }) : super(key: key);
//
//   @override
//   _MeterCalculatorWidgetState createState() => _MeterCalculatorWidgetState();
// }
//
// class _MeterCalculatorWidgetState extends State<MeterCalculatorWidget> {
//   double _radius = 2000.0; // Default in meters
//   bool _imperial = false;
//
//   @override
//   void initState() {
//     _loadSelectedUnit();
//     super.initState();
//   }
//
//   Future<void> _loadSelectedUnit() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? selectedUnit = prefs.getString('selectedUnit');
//     double meterValue = prefs.getDouble('meterRadius') ?? 2000.0;
//     double milesValue = prefs.getDouble('milesRadius') ?? 1.04;
//
//     setState(() {
//       _imperial = (selectedUnit == 'Imperial system (mi/ft)');
//       _radius = _imperial ? milesValue : meterValue; // Convert if needed
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double height = MediaQuery.of(context).size.height;
//     double width = MediaQuery.of(context).size.width;
//
//     // Convert radius to kilometers if needed for display
//     double displayedRadius = _imperial ? _radius : _radius / 1000.0;
//
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Text(
//               'Radius',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             Padding(
//               padding: EdgeInsets.only(left: width / 2.5714),
//               child: Text(
//                 displayedRadius.toStringAsFixed(2) +
//                     ' ${_imperial ? 'miles' : 'kilometers'}',
//               ),
//             ),
//           ],
//         ),
//         Container(
//           width: width / 1.16129,
//           child: Slider(
//             value: _radius, // Maintain value in meters internally
//             divisions: 100,
//             min: _imperial ? 1.609 : 0.001, // Convert min to miles/km
//             max: _imperial ? 4.828 : 3.0, // Convert max to miles/km
//             onChanged: (value) {
//               setState(() {
//                 _radius = value.clamp(
//                     _imperial ? 1.609 : 0.001, _imperial ? 4.828 : 3.0);
//               });
//               widget.callback(_imperial ? (value * 1609.34) : (value)); // Convert to meters for callback
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_places_flutter/google_places_flutter.dart';        // ADD THIS
import 'package:google_places_flutter/model/prediction.dart';              // ADD THIS
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitiled/Homescreens/settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'Apiutils.dart';
import 'Homescreens/save_alarm_page.dart';
import 'about page.dart';
import 'adhelper.dart';
import 'drawer.dart';
import 'main.dart';

class MyHomePage extends StatefulWidget {
  final String? title;

  const MyHomePage({
    super.key,
    this.title,
  });

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  double meterRadius = 100; // Initial value for meter radius
  double milesRadius = 0.31;
  var latlong;
  double radius = 0;
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  Future<InitializationStatus> _initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }

  Future<void> _loadRadiusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double meterdefault = prefs.getDouble('meterRadius') ?? 2000;
    double milesdefault = prefs.getDouble('milesRadius') ?? 1.04;
    setState(() {
      meterRadius = prefs.getDouble('meterRadius') ?? 0.0;
      milesRadius = prefs.getDouble('milesRadius') ?? 0.0;
      radius = (prefs.getString('selectedUnit') == 'Imperial system (mi/ft)')
          ? milesdefault
          : meterdefault;
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (currentLocation == null) {
      setState(() {
        _isLoading = true; // Show loading animation
      });

      await _requestLocationPermission();

      return; // Wait for location to be updated
    }

    // Rest of your code...
  }

  updateradiusvalue(value) {
    print("updatevalue:" + value.toString());
    setState(() {
      radius = value;
      print("updatevalue:" + value.toString());
    });
  }

  final Uri playStoreUri = Uri(
    scheme: 'https',
    host: 'play.google.com',
    path: 'store/apps/details',
    queryParameters: {'id': 'com.inodesys.gps_alarm', 'hl': 'en'},
  );
  TextEditingController controller = TextEditingController();
  GoogleMapController? mapController;
  location.LocationData? currentLocation;
  location.Location _locationService = location.Location();
  bool _isCameraMoving = false;
  final LatLng _defaultLocation =
      const LatLng(13.067439, 80.237617); // Default location
  TextEditingController searchController = TextEditingController();
  List<AlarmDetails> alarms = [];
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _initGoogleMobileAds();
    initConnectivity();
    _requestLocationPermission();
    alramnamecontroller.text = "Welcome";
    _loadRadiusData();
    loadData();
    Timer(Duration(seconds: 160), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _loadBannerAd() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      // Use test ad unit ID for testing: 'ca-app-pub-3940256099942544/6300978111'
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

  Future<void> initConnectivity() async {
    List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? alarmsJson = prefs.getStringList('alarms');

    if (alarmsJson != null) {
      alarms = alarmsJson
          .map((json) => AlarmDetails.fromJson(jsonDecode(json)))
          .toList();
    } else {
      alarms = [];
    }

    setState(() {});
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        setState(()
            // dart
            // Copy code
            {
          _isLoading = false; // Hide loading animation
        });
        return;
      }
    }

    location.PermissionStatus permissionStatus =
        await _locationService.hasPermission();
    if (permissionStatus == location.PermissionStatus.denied) {
      permissionStatus = await _locationService.requestPermission();
      if (permissionStatus != location.PermissionStatus.granted) {
        setState(() {
          _isLoading = false; // Hide loading animation
        });
        return;
      }
    }

    log("location 1");
    _locationService.onLocationChanged
        .listen((location.LocationData newLocation) async {
      log("location changed");
      if (_isCameraMoving) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          if (newLocation.latitude != null && newLocation.longitude != null) {
            _current = LatLng(newLocation.latitude!, newLocation.longitude!);
          }
          currentLocation = newLocation;

          prefs.setDouble('current_latitude', newLocation.latitude!);
          prefs.setDouble('current_longitude', newLocation.longitude!);

          // Example usage: retrieve the stored location later
          double? storedLatitude = prefs.getDouble('current_latitude');
          double? storedLongitude = prefs.getDouble('current_longitude');
          if (storedLatitude != null && storedLongitude != null) {
            print('Stored location: ($storedLatitude, $storedLongitude)');
            Marker? tap = _markers.length > 1 ? _markers.last : null;

            _markers.clear();
            _markers.add(Marker(
              markerId: MarkerId("_currentLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: currentLocation != null
                  ? LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!)
                  : _defaultLocation,
            ));
            if (tap != null) {
              _markers.add(tap);
            }
          }
        });

        if (mapController != null && _markers.length < 2) {
          mapController!.animateCamera(CameraUpdate.newLatLng(
            LatLng(newLocation.latitude!, newLocation.longitude!),
          ));
          setState(() {
            _isLoading = false; // Hide loading animation after camera moves
          });
        }
      }
    });
    log("location 2");
  }

  Future<void> checkLocation() async {
    location.Location ls = new location.Location();
    if (await Permission.notification.request().isGranted &&
        await Permission.location.request().isGranted &&
        await ls.serviceEnabled()) {
      await initializeService();
      print('Permissions are granted');
    } else {
      print('Permissions are not granted');
    }
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.hybrid;      // satellite + clear road labels
      } else if (_currentMapType == MapType.hybrid) {
        _currentMapType = MapType.terrain;     // terrain/topographic
      } else {
        _currentMapType = MapType.normal;      // back to normal
      }
    });
  }

  Set<Marker> _markers = {};
  LatLng? _current = const LatLng(13.067439, 80.237617);
  LatLng? _target = null;
  bool _handletap = false;
  bool _isAlarmNameValid = false;
  bool _isLoading = true;
  TextEditingController notescontroller = TextEditingController();

  // Initialize the TextEditingController with the default value
  TextEditingController alramnamecontroller =
      TextEditingController(text: "Welcome");

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  String _appBarTitle = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int screenIndex = 1;

  // void handleScreenChanged(int index) {
  //   switch (index) {
  //     case 0: // Alarm List
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => MyAlarmsPage()));
  //       break;
  //     case 1: // Alarm List
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => MyHomePage()));
  //       break;
  //     case 2:
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => Settings()));
  //       break;
  //     case 3:
  //       final RenderBox box = context.findRenderObject() as RenderBox;
  //       Rect dummyRect = Rect.fromCenter(center: box.localToGlobal(Offset.zero), width: 1.0, height: 1.0);
  //       Share.share(
  //         'Check out my awesome app! Download it from the app store:',
  //         subject: 'Share this amazing app!',
  //         sharePositionOrigin: dummyRect,
  //       );
  //       break;
  //     case 4:
  //       _launchInBrowser(toLaunch);
  //       break;
  //     case 5:
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => About()));
  //       break;
  //   }
  // }
  // void handleScreenChanged(int index) {
  //   switch (index) {
  //     case 0:
  //       Navigator.of (context).pop();// Alarm List
  //       Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => MyAlarmsPage()));
  //       break;
  //     case 1:
  //       Navigator.of (context).pop();// Alarm List
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => MyHomePage()));
  //       break;
  //     case 2:
  //       Navigator.of (context).pop();
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => Settings()));
  //       break;
  //     case 3:
  //       Navigator.of (context).pop();
  //       final RenderBox box = context.findRenderObject() as RenderBox;
  //       Rect dummyRect = Rect.fromCenter(center: box.localToGlobal(Offset.zero), width: 1.0, height: 1.0);
  //       Share.share(
  //         'Check out my awesome app! Download it from the app store:',
  //         subject: 'Share this amazing app!',
  //         sharePositionOrigin: dummyRect,
  //       );
  //       break;
  //     case 4:
  //       Navigator.of (context).pop();
  //       _launchInBrowser(toLaunch);
  //       break;
  //     case 5:
  //       Navigator.of (context).pop();
  //       Navigator.of(context).push(
  //           MaterialPageRoute(builder: (context) => About()));
  //       break;
  //   }
  // }
  // void handleScreenChanged(int index) {
  //   switch (index) {
  //     case 0:
  //       Navigator.of(context).pop();
  //       // No pop needed for screen1 as it's likely the first screen
  //      Navigator.of(context).push(
  //        MaterialPageRoute(builder: (context)=>My)
  //      )// Navigate to screen1
  //       break;
  //     case 1:
  //       Navigator.of(context).pop();
  //       // No pop needed for screen2 as it's likely the first screen
  //      // Navigator.pushNamed(context, '/secondpage');
  //        Navigator.popUntil(context, ModalRoute.withName('/secondpage'));
  //       // Navigate to screen2
  //       break;
  //     case 2:
  //       Navigator.of(context).pop();
  //       // Navigator.pushNamed(context, '/thirdpage');
  //       Navigator.popUntil(context, ModalRoute.withName('/thirdpage'));// Navigate to screen3
  //       break;
  //     case 3:
  //       Navigator.of(context).pop();
  //       // Share functionality, no navigation
  //       final RenderBox box = context.findRenderObject() as RenderBox;
  //       Rect dummyRect = Rect.fromCenter(center: box.localToGlobal(Offset.zero), width: 1.0, height: 1.0);
  //       Share.share(
  //         'Check out my awesome app! Download it from the app store:',
  //         subject: 'Share this amazing app!',
  //         sharePositionOrigin: dummyRect,
  //       );
  //
  //       break;
  //     case 4:
  //       Navigator.of(context).pop();
  //       // Launch URL, no navigation
  //       _launchInBrowser(toLaunch);
  //       break;
  //     case 5:
  //       Navigator.of(context).pop();
  //      // Navigator.pushNamed(context, '/fouthpage');
  //       Navigator.popUntil(context, ModalRoute.withName('/fouthpage'));// Navigate to screen4
  //       break;
  //   }
  // }
  void handleScreenChanged(int index) {
    Navigator.of(context).pop();
    switch (index) {
      case 0:
        // No pop needed for screen1 as it's likely the first screen
        //   Navigator.pushNamed(context, '/home'); // Navigate to screen1
        //   Navigator.of(context).pushReplacement(
        //       MaterialPageRoute(builder: (context)=>MyAlarmsPage()));
        //   Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyAlarmsPage()),
          (Route<dynamic> route) =>
              false, // This condition will remove all routes
        );
        break;
      case 1:
        Navigator.of(context).pop();
        //Navigate to screen3
        break;
      case 2:
        // Navigator.pushNamed(context, '/thirdpage');
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => Settings())); //Navigate to screen3
        break;
      case 3:
        // Share functionality, no navigation
        final RenderBox box = context.findRenderObject() as RenderBox;
        Share.share(
          'Check out my awesome app! Download it from the app store: https://play.google.com/store/apps/details?id=com.inodesys.gps_alarm&hl=en',
          subject: 'Share this amazing app!',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
        break;
      case 4:
        // Launch URL, no navigation
        _launchInBrowser(playStoreUri);
        break;
      case 5:
        // Navigator.pushNamed(context, '/fouthpage'); // Navigate to screen4
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => About()));
        break;
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   double height = MediaQuery.of(context).size.height;
  //   double width = MediaQuery.of(context).size.width;
  //   final Uri toLaunch = Uri(scheme: 'https', host: 'www.google.com');
  //   return Scaffold(
  //     key: _scaffoldKey,
  //     drawer: NavigationDrawer(
  //       onDestinationSelected: (int index) {
  //         handleScreenChanged(
  //             index); // Assuming you have a handleScreenChanged function
  //       },
  //       selectedIndex: screenIndex,
  //       children: <Widget>[
  //         SizedBox(
  //           height: height / 23.625,
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.alarm_on_outlined), // Adjust size as needed
  //           label: Text('Saved Alarms'),
  //           // Set selected based on screenIndex
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.alarm),
  //           label: Text('Set a Alarm'),
  //           // Set selected based on screenIndex
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.settings_outlined),
  //           label: Text('Settings'),
  //           // Set selected based on screenIndex
  //         ),
  //         Divider(),
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
  //           child: Text(
  //             'Communicate', // Assuming this is the header
  //             style: Theme.of(context).textTheme.titleSmall,
  //           ),
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.share_outlined),
  //           label: Text('Share'),
  //
  //           // Set selected based on screenIndex
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.rate_review_outlined),
  //           label: Text('Rate/Review'),
  //           // Set selected based on screenIndex
  //         ),
  //         Divider(),
  //         Padding(
  //           padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
  //           child: Text(
  //             'App', // Assuming this is the header
  //             style: Theme.of(context).textTheme.titleSmall,
  //           ),
  //         ),
  //         NavigationDrawerDestination(
  //           icon: Icon(Icons.error_outline_outlined),
  //           label: Text('About'),
  //           // Set selected based on screenIndex
  //         ),
  //       ],
  //     ),
  //     body: StreamBuilder<List<ConnectivityResult>>(
  //       stream: _connectivity.onConnectivityChanged,
  //       builder: (context, snapshot) {
  //         if (snapshot.hasError) {
  //           return Text('Error: ${snapshot.error}');
  //         }
  //
  //         if (!snapshot.hasData) {
  //           print("Internet connection");
  //           return Center(
  //               child:
  //                   CircularProgressIndicator()); // Or a custom loading indicator
  //         }
  //
  //         List<ConnectivityResult>? result = snapshot.data;
  //
  //         bool isOffline = result != null && result.contains(ConnectivityResult.none);
  //
  //
  //
  //         // Display message or disable functionality based on connectivity
  //         if (isOffline) {
  //           return Center(
  //             child: Text(
  //               'No Internet connection',
  //               style: Theme.of(context).textTheme.titleMedium,
  //             ),
  //           );
  //         }else {
  //           print("Internet connection");
  //           // Rest of your GPS alarm app functionality that requires internet
  //           return Stack(
  //             children: [
  //               Center(
  //                 child: AnimatedBuilder(
  //                   animation: AlwaysStoppedAnimation(0.0),
  //                   builder: (context, child) {
  //                     return Transform.rotate(
  //                       angle: 3.14 * 2 * 0.5,
  //                       // child: Icon(Icons.refresh), // Use any loading icon you prefer
  //                     );
  //                   },
  //                 ),
  //                 // CircularProgressIndicator(), // Adjust style as needed
  //               ),
  //               // GoogleMap(
  //               //   mapType: MapType.normal,
  //               //   myLocationButtonEnabled: false,
  //               //   zoomControlsEnabled: false,
  //               //   initialCameraPosition: CameraPosition(
  //               //     zoom: 15,
  //               //     target: _defaultLocation,
  //               //   ),
  //               //   onMapCreated: (GoogleMapController controller) {
  //               //     mapController = controller;
  //               //     setState(() {
  //               //       _isLoading = false; // Hide loading animation when the map is created
  //               //     });
  //               //   },
  //               //   markers: _markers.toSet(),
  //               //   onLongPress: _handleTap,
  //               //   onCameraMoveStarted: () {
  //               //     setState(() {
  //               //       _isCameraMoving = true;
  //               //     });
  //               //   },
  //               //   onCameraIdle: () {
  //               //     setState(() {
  //               //       _isCameraMoving = false;
  //               //     });
  //               //   },
  //               // ),
  //               // if (_isLoading)
  //               //   Center(
  //               //     child: CircularProgressIndicator(), // Adjust style as needed
  //               //   ),
  //               // Positioned(
  //               //     top: 200,
  //               //     left: 70,
  //               //     right: 20,
  //               //     child: Image.asset("assets/locationmark11.png")),
  //               GoogleMap(
  //                 mapType: _currentMapType,
  //                 myLocationButtonEnabled: false,
  //                 zoomControlsEnabled: false,
  //                 initialCameraPosition: CameraPosition(
  //                   zoom: 15,
  //                   target: _defaultLocation,
  //                 ),
  //                 onMapCreated: (GoogleMapController controller) {
  //                   mapController = controller;
  //                 },
  //                 markers: _markers.toSet(),
  //                 onLongPress: _handleTap,
  //                 onCameraMoveStarted: () {
  //                   setState(() {
  //                     _isCameraMoving = true;
  //                   });
  //                 },
  //                 onCameraIdle: () {
  //                   setState(() {
  //                     _isCameraMoving = false;
  //                   });
  //                 },
  //               ),
  //               if (_isLoading)
  //                 Stack(
  //                   children: [
  //                     BackdropFilter(
  //                       filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
  //                       child: Container(
  //                         color: Colors.black
  //                             .withOpacity(0.5), // Semi-transparent background
  //                       ),
  //                     ),
  //                     Center(
  //                       child: Container(
  //                         width: 100,
  //                         height: 100,
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           // Background color of the loader container
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                         child: Center(
  //                           child:
  //                               CircularProgressIndicator(), // Adjust style as needed
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //
  //               Visibility(
  //                 visible: _isLoading,
  //                 child: Center(
  //                   child:
  //                       CircularProgressIndicator(), // Adjust style as needed
  //                 ),
  //               ),
  //               Positioned(
  //                 top: 50,
  //                 left: 70,
  //                 right: 20,
  //                 child: placesAutoCompleteTextField(),
  //               ),
  //               Padding(
  //                 padding:
  //                     EdgeInsets.only(top: height / 6.56, left: width / 3.6),
  //                 child: Container(
  //                   height: height / 25.2,
  //                   width: width / 1.8,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white70,
  //                     border: Border.all(
  //                       color: Colors.black,
  //                     ),
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: Center(
  //                       child: AutoSizeText(
  //                         maxFontSize: 14,
  //                     minFontSize: 2,
  //
  //                     "or long press on the map",
  //                     style: Theme.of(context).textTheme.titleMedium,
  //                   )),
  //                 ),
  //               ),
  //               Positioned(
  //                 right: 24, bottom: 162,
  //                 // padding:  EdgeInsets.only(top:height/1.68,left: 280),
  //                 child: IconButton.filledTonal(
  //                   onPressed: _goToCurrentLocation,
  //                   icon: Icon(Icons.my_location),
  //                   // child: Icon(Icons.my_location),
  //                 ),
  //               ),
  //               Positioned(
  //                 bottom: 112, right: 24,
  //                 // padding: const EdgeInsets.only(left: 280.0,top: 500),
  //                 child: IconButton.filledTonal(
  //                   onPressed: () {
  //                     mapController?.animateCamera(
  //                       CameraUpdate.zoomIn(),
  //                     );
  //                   },
  //                   icon: Icon(Icons.add),
  //                 ),
  //               ),
  //               Positioned(
  //                 bottom: 62, right: 24,
  //
  //                 // padding: const EdgeInsets.only(left: 280.0,top: 600),
  //                 child: IconButton.filledTonal(
  //                   onPressed: () {
  //                     mapController?.animateCamera(
  //                       CameraUpdate.zoomOut(),
  //                     );
  //                   },
  //                   icon: Icon(Icons.remove),
  //                 ),
  //               ),
  //               Positioned(
  //                   top: 50,
  //                   left: 15,
  //                   child: IconButton(
  //                     onPressed: () {
  //                       _scaffoldKey.currentState?.openDrawer();
  //                     },
  //                     icon: Icon(Icons.menu),
  //                   )),
  //               Positioned(
  //                 right: 24,
  //                 bottom: 212,
  //                 child: IconButton.filledTonal(
  //                   onPressed: _toggleMapType,
  //                   icon: Icon(Icons.map),
  //                 ),
  //               ),
  //               Stack(
  //                 children: [
  //                   _bannerAd != null
  //                       ? Align(
  //                           alignment: Alignment.bottomCenter,
  //                           child: Container(
  //                             width: _bannerAd!.size.width.toDouble(),
  //                             height: _bannerAd!.size.height.toDouble(),
  //                             child: AdWidget(ad: _bannerAd!),
  //                           ),
  //                         )
  //                       : Align(
  //                           alignment: Alignment.bottomCenter,
  //                           child: Container(
  //                             height: 50,
  //                             color: Colors.transparent,
  //                           ),
  //                         )
  //                 ],
  //               )
  //             ],
  //           );
  //         }
  //       },
  //     ),
  //
  //     // bottomNavigationBar: _bannerAd != null
  //     //     ? Align(
  //     //   alignment: Alignment.bottomCenter,
  //     //   child: Container(
  //     //     width: _bannerAd!.size.width.toDouble(),
  //     //     height: _bannerAd!.size.height.toDouble(),
  //     //     child: AdWidget(ad: _bannerAd!),
  //     //   ),
  //     // )
  //     //     : Text('Loading ad...'),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    bool isTablet = ResponsiveHelper.isTablet(context);

    double topOffset = isTablet ? 60 : 50;
    double menuLeft = isTablet ? 20 : 15;
    double searchLeft = isTablet ? 90 : 70;
    double iconRight = isTablet ? 30 : 24;
    double btn1Bottom = isTablet ? 200 : 162;
    double btn2Bottom = isTablet ? 150 : 112;
    double btn3Bottom = isTablet ? 100 : 62;
    double btn4Bottom = isTablet ? 250 : 212;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer( selectedIndex: screenIndex,
        onDestinationSelected: handleScreenChanged,
      ),
      body: StreamBuilder<List<ConnectivityResult>>(
        stream: _connectivity.onConnectivityChanged,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<ConnectivityResult>? result = snapshot.data;
          bool isOffline =
              result != null && result.contains(ConnectivityResult.none);

          if (isOffline) {
            return Center(
              child: Text('No Internet connection',
                  style: Theme.of(context).textTheme.titleMedium),
            );
          }

          return Stack(
            children: [
              // Map
              GoogleMap(
                mapType: _currentMapType,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(
                  zoom: 15,
                  target: _defaultLocation,
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                markers: _markers.toSet(),
                onLongPress: _handleTap,
                onCameraMoveStarted: () =>
                    setState(() => _isCameraMoving = true),
                onCameraIdle: () => setState(() => _isCameraMoving = false),
              ),

              // Loading overlay
              if (_isLoading)
                Stack(children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                  Center(
                    child: Container(
                      width: isTablet ? 140 : 100,
                      height: isTablet ? 140 : 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ]),

              // Search bar
              Positioned(
                top: topOffset,
                left: searchLeft,
                right: isTablet ? 30 : 20,
                child: placesAutoCompleteTextField(),
              ),

              // "or long press" hint
              Positioned(
                top: topOffset + (isTablet ? 70 : 55),
                left: width * 0.35,
                right: isTablet ? 30 : 20,
                child: Container(
                  height: isTablet ? 36 : height / 25.2,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),

                  ),
                  child: Center(
                    child: AutoSizeText(
                      "or long press on the map",
                      maxFontSize: isTablet ? 12 : 10,
                      minFontSize: 8,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),

              // Menu button
              Positioned(
                top: topOffset,
                left: menuLeft,
                child: IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: Icon(Icons.menu, size: isTablet ? 30 : 24),
                ),
              ),

              // My location button
              Positioned(
                right: iconRight,
                bottom: btn1Bottom,
                child: IconButton.filledTonal(
                  onPressed: _goToCurrentLocation,
                  icon: Icon(Icons.my_location, size: isTablet ? 28 : 24),
                ),
              ),

              // Zoom in
              Positioned(
                bottom: btn2Bottom,
                right: iconRight,
                child: IconButton.filledTonal(
                  onPressed: () =>
                      mapController?.animateCamera(CameraUpdate.zoomIn()),
                  icon: Icon(Icons.add, size: isTablet ? 28 : 24),
                ),
              ),

              // Zoom out
              Positioned(
                bottom: btn3Bottom,
                right: iconRight,
                child: IconButton.filledTonal(
                  onPressed: () =>
                      mapController?.animateCamera(CameraUpdate.zoomOut()),
                  icon: Icon(Icons.remove, size: isTablet ? 28 : 24),
                ),
              ),

              // Map type toggle
              Positioned(
                right: iconRight,
                bottom: btn4Bottom,
                child: IconButton.filledTonal(
                  onPressed: _toggleMapType,
                  icon: Icon(Icons.map, size: isTablet ? 28 : 24),
                ),
              ),

              // Banner ad
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  void _showCustomBottomSheet(BuildContext context) async
  {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    int characterCount = 0;
    if (!_handletap) {
      // Show a snackbar if a destination is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a destination on the map.'),
        ),
      );
      return;
    }
    loadData();
    alramnamecontroller.text = _appBarTitle;
    notescontroller.clear();
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
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   builder: (BuildContext context) {
    //     String counterText;
    //     return SingleChildScrollView(
    //       child: Padding(
    //         padding: EdgeInsets.only(
    //           bottom: MediaQuery.of(context).viewInsets.bottom,
    //         ),
    //         child: Container(
    //          // height: height / 1.9384615384615,
    //           width: double.infinity,
    //           child: Column(
    //               mainAxisSize: MainAxisSize.min, // 🔥 VERY IMPORTANT
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //
    //               children: [
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //                   children: [
    //                     FilledButton(
    //                       onPressed: () {
    //                         Navigator.of(context)
    //                             .pop(); // Call the saveAlarm function
    //                       },
    //                       child: Text("Cancel"),
    //                     ),
    //                     Padding(
    //                       padding: EdgeInsets.only(left: width / 3),
    //                       child: FilledButton(
    //                         onPressed: () {
    //                           saveAlarm(context);
    //                         },
    //                         // Call the saveAlarm function
    //
    //                         child: Text("Set"),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //
    //                 // Integrate the MeterCalculatorWidget
    //                 MeterCalculatorWidget(
    //                   callback: updateradiusvalue,
    //                 ),
    //                 // Column(
    //                 //   crossAxisAlignment: CrossAxisAlignment.start,
    //                 //   children: [
    //                 //     Text("Alarm Name:", style: Theme.of(context).textTheme.titleMedium,),
    //                 //
    //                 //     // Container(
    //                 //     //   height:height/ 15.12,
    //                 //     //   width: width/1.2,
    //                 //     //   decoration: BoxDecoration(
    //                 //     //     color: Colors.white,
    //                 //     //     borderRadius: BorderRadius.circular(10),
    //                 //     //     border: Border.all(color: Colors.black12),
    //                 //     //
    //                 //     //   ),child: Padding(
    //                 //     //   padding:  EdgeInsets.only(left: width/36),
    //                 //     //   child: TextField(
    //                 //     //     controller: alramnamecontroller,
    //                 //     //
    //                 //     //     style: Theme.of(context).textTheme.bodyMedium,
    //                 //     //     decoration: InputDecoration(
    //                 //     //       hintText: "Alarm name",
    //                 //     //       border: InputBorder.none,
    //                 //     //       enabledBorder: InputBorder.none,
    //                 //     //     ),
    //                 //     //   ),
    //                 //     // ),
    //                 //     // ),
    //                 //     // Container(
    //                 //     //   height: height / 15.12,
    //                 //     //   width: width / 1.2,
    //                 //     //   decoration: BoxDecoration(
    //                 //     //     color: Colors.white,
    //                 //     //     borderRadius: BorderRadius.circular(10),
    //                 //     //     border: Border.all(color: Colors.black12),
    //                 //     //   ),
    //                 //     //   child: Padding(
    //                 //     //     padding: EdgeInsets.only(left: width / 36),
    //                 //     //     child: TextFormField( // Use TextFormField instead of TextField
    //                 //     //       controller: alramnamecontroller,
    //                 //     //       style: Theme.of(context).textTheme.bodyMedium,
    //                 //     //       decoration: InputDecoration(
    //                 //     //         hintText: "Alarm name",
    //                 //     //         border: InputBorder.none,
    //                 //     //         enabledBorder: InputBorder.none,
    //                 //     //         counterText: '', // Hide default character counter
    //                 //     //       ),
    //                 //     //       maxLength: 100, // Set character limit
    //                 //     //       validator: (value) {
    //                 //     //         if (value == null || value.isEmpty) {
    //                 //     //           return 'Alarm name is required.';
    //                 //     //         }
    //                 //     //         if (value.length > 100) {
    //                 //     //           return 'Alarm name cannot exceed 100 characters.';
    //                 //     //         }
    //                 //     //         return null; // Valid input
    //                 //     //       },
    //                 //     //       onChanged: (value) {
    //                 //     //         // Optional: Update counter text manually (if desired)
    //                 //     //         // setState(() {
    //                 //     //          // counterText = value.length.toString();
    //                 //     //         // });
    //                 //     //       },
    //                 //     //     ),
    //                 //     //   ),
    //                 //     // ),
    //                 //     Container(
    //                 //       height: height / 15.12,
    //                 //       width: width / 1.2,
    //                 //       decoration: BoxDecoration(
    //                 //         color: Colors.white,
    //                 //         borderRadius: BorderRadius.circular(10),
    //                 //         border: Border.all(color: Colors.black12),
    //                 //       ),
    //                 //       child: Row(
    //                 //         children: [
    //                 //           Expanded(
    //                 //             child: Padding(
    //                 //               padding: EdgeInsets.only(left: width / 36),
    //                 //               child: TextFormField(
    //                 //                 controller: alramnamecontroller,
    //                 //                 style: Theme.of(context).textTheme.bodyMedium,
    //                 //                 decoration: InputDecoration(
    //                 //                   hintText: "Alarm name",
    //                 //                   border: InputBorder.none,
    //                 //                   enabledBorder: InputBorder.none,
    //                 //                   counterText: '', // Hide default character counter
    //                 //                 ),
    //                 //                 maxLength: 100, // Set character limit
    //                 //                 validator: (value) {
    //                 //                   // Check if the input is only whitespace characters or empty
    //                 //                   if (value!.trim().isEmpty) {
    //                 //                     return 'Alarm name is required.';
    //                 //                   }
    //                 //                   if (value.split(' ').length > 50) {
    //                 //                     return 'Alarm name cannot exceed 50 words.';
    //                 //                   }
    //                 //                   if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    //                 //                     return 'Alarm name cannot contain special characters.';
    //                 //                   }
    //                 //                   return null; // Valid input
    //                 //                 },
    //                 //                 onChanged: (value) {
    //                 //                   // Optional: Update counter text manually (if desired)
    //                 //                   // setState(() {
    //                 //                   //   counterText = value.length.toString();
    //                 //                   // });
    //                 //                 },
    //                 //               ),
    //                 //             ),
    //                 //           ),
    //                 //
    //                 //         ],
    //                 //       ),
    //                 //     ),
    //                 //
    //                 //     Text("Notes:",style: Theme.of(context).textTheme.titleMedium,),
    //                 //     Container(
    //                 //       height: height/10.8,
    //                 //       width:width/1.2,
    //                 //       decoration: BoxDecoration(
    //                 //         color: Colors.white,
    //                 //         borderRadius: BorderRadius.circular(10),
    //                 //         border: Border.all(color: Colors.black12),
    //                 //       ),child: Padding(
    //                 //       padding:  EdgeInsets.only(left: width/36),
    //                 //       child: TextField(
    //                 //         controller: notescontroller,
    //                 //         style: Theme.of(context).textTheme.bodyMedium,
    //                 //         decoration: InputDecoration(
    //                 //           hintText: "Notes",
    //                 //           border: InputBorder.none,
    //                 //           enabledBorder: InputBorder.none,
    //                 //         ),
    //                 //       ),
    //                 //     ),
    //                 //     ),
    //                 //   ],
    //                 // ),
    //                 Padding(
    //                   padding: EdgeInsets.only(left: width / 15),
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     // Align text to the start horizontally
    //                     children: [
    //                       Text(
    //                         "Alarm Name:",
    //                         style: Theme.of(context).textTheme.titleMedium,
    //                       ),
    //                       Container(
    //                         //height: 70,
    //                         width: width / 1.1612903225806,
    //                         decoration: BoxDecoration(
    //                           color: Colors.white,
    //                           borderRadius: BorderRadius.circular(10),
    //                           border: Border.all(color: Colors.black12),
    //                         ),
    //                         child: Padding(
    //                           padding: EdgeInsets.only(
    //                               left: width / 22.5, right: width / 22.5),
    //                           child: TextField(
    //                             textAlign: TextAlign.start,
    //                             // keyboardType: TextInputType.multiline,
    //                             maxLines: 2,
    //                             controller: alramnamecontroller,
    //                             // Set the desired number of lines for multi-line input
    //                             style: Theme.of(context).textTheme.bodyMedium,
    //                             decoration: InputDecoration(
    //                               hintText: "Alarmname",
    //                               border: InputBorder.none,
    //                               // Remove borders if desired (optional)
    //                               enabledBorder: InputBorder
    //                                   .none, // Remove borders if desired (optional)
    //                               // Show current character count and limit
    //                             ),
    //                             maxLength: 50,
    //                             onChanged: (value) => counterText =
    //                                 '${alramnamecontroller.text.length}/50', // Set the maximum allowed characters
    //                           ),
    //                         ),
    //                       ),
    //                       //Text("Alarmname cannot exceed 50 words",style: Theme.of(context).textTheme.bodySmall,),
    //                       SizedBox(
    //                         height: 10,
    //                       ),
    //                       Text(
    //                         "Notes:",
    //                         style: Theme.of(context).textTheme.titleMedium,
    //                       ),
    //                       Container(
    //                         //height: 70,
    //                         width: width / 1.1612903225806,
    //                         decoration: BoxDecoration(
    //                           color: Colors.white,
    //                           borderRadius: BorderRadius.circular(10),
    //                           border: Border.all(color: Colors.black12),
    //                         ),
    //                         child: Padding(
    //                           padding: EdgeInsets.only(
    //                               left: width / 22.5, right: width / 22.5),
    //                           child: TextField(
    //                             textAlign: TextAlign.start,
    //                             // keyboardType: TextInputType.multiline,
    //                             maxLines: 2,
    //                             controller: notescontroller,
    //                             // Set the desired number of lines for multi-line input
    //                             style: Theme.of(context).textTheme.bodyMedium,
    //                             decoration: InputDecoration(
    //                               hintText: "Notes",
    //                               border: InputBorder.none,
    //                               // Remove borders if desired (optional)
    //                               enabledBorder: InputBorder
    //                                   .none, // Remove borders if desired (optional)
    //                               // Show current character count and limit
    //                             ),
    //                             maxLength: 150,
    //                             onChanged: (value) => counterText =
    //                                 '${notescontroller.text.length}/150', // Set the maximum allowed characters
    //                           ),
    //                         ),
    //                       ),
    //                       //Text("Notes cannot exceed 150 words",style: Theme.of(context).textTheme.bodySmall,),
    //                     ],
    //                   ),
    //                 ),
    //               ]),
    //         ),
    //       ),
    //     );
    //   },
    // );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔥 Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // 🔥 Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel"),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => saveAlarm(context),
                              child: Text("Set"),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      // 🔥 Radius widget
                      MeterCalculatorWidget(
                        callback: updateradiusvalue,
                      ),

                      SizedBox(height: 20),

                      // 🔥 Alarm Name
                      Text("Alarm Name:",
                          style: Theme.of(context).textTheme.titleMedium),

                      SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: alramnamecontroller,
                          maxLength: 50,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Alarm name",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // 🔥 Notes
                      Text("Notes:",
                          style: Theme.of(context).textTheme.titleMedium),

                      SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: notescontroller,
                          maxLength: 150,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Notes",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void saveAlarm(BuildContext context) async {
    if (alramnamecontroller.text.isEmpty || radius == null) {
      Navigator.of(context).pop();
      // Show a Snackbar prompting the user to fill in the required fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all the required fields.'),
        ),
      );
      return; // Exit the function without saving the data
    }
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
    List<String> alarmsJson =
        alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
    print("alarms: $alarmsJson");

    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // List<Map<String, dynamic>> alarmsJson =
    // alarms.map((alarm) => alarm.toJson()).toList();
    // await prefs.setStringList(
    //     'alarms', alarmsJson.map((json) => jsonEncode(json)).toList());

    // SharedPreferences prefs = await SharedPreferences.getInstance();
    //
    // // Convert each AlarmDetails object to a JSON string
    // List<String> alarmsJson = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    //
    // // Save the list of JSON strings to SharedPreferences
    // await prefs.setStringList('alarms', alarmsJson);
    //
    // print('Alarms saved successfully: $alarmsJson');

    loadData();
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
    }
    Navigator.of(context).pop();
    Navigator.of(context).pop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MyAlarmsPage(),
      ),
    );
  }

  placesAutoCompleteTextField() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Material(
      borderRadius: BorderRadius.circular(30.0),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: controller,
        googleAPIKey: "AIzaSyA3byIibe-X741Bw5rfEzOHZEKuWdHvCbw",

        boxDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(30.0), // Adjust the radius as needed
          // border: Border.all(color: Colors.black26), // Add border color
        ),

        inputDecoration: InputDecoration(
          hintText: "Alarm location",
          hintStyle: Theme.of(context).textTheme.bodyMedium,

          border: InputBorder.none,
          enabledBorder: InputBorder.none,

          contentPadding: EdgeInsets.symmetric(
            vertical: 8,  // 🔥 THIS centers vertically
            horizontal: 18,
          ),

          suffixIcon: Icon(
            Icons.search,
            size: 25,
            color: Colors.black,
          ),
        ),
        debounceTime: 400,
        countries: ["in", "fr"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) async {
          print("placeDetails" + prediction.lat.toString());
          print(
              "placeDetails - Lat: ${prediction.lat}, Lng: ${prediction.lng}");
          double lat = double.parse(prediction.lat!);
          double lng = double.parse(prediction.lng!);
          //
          // // Call _handleTap to add a marker at the selected location
          await _handleTap(LatLng(lat, lng));
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(
              LatLng(lat, lng),
            ));
          }
        },

        // itemClick: (Prediction prediction) async {
        //   print(prediction.lat);
        //   print(prediction.lng);
        //
        //  await _handleTap(LatLng(prediction.lat as double, prediction.lng as double));
        //   controller.text = prediction.description ?? "";
        //   controller.selection = TextSelection.fromPosition(
        //       TextPosition(offset: prediction.description?.length ?? 0));
        // },
        itemClick: (Prediction prediction) async {
          // Extract the latitude and longitude from the prediction

          print("enter");

          // Set the text field value to the prediction description
          controller.text = prediction.description ?? "";
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: prediction.description?.length ?? 0));
        },

        seperatedBuilder: Divider(),
       // containerHorizontalPadding: 10,

        // OPTIONAL// If you want to customize list view item builder
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.location_on),

                Expanded(child: Text("${prediction.description ?? ""}"))
              ],
            ),
          );
        },

        isCrossBtnShown: true,

        // default 600 ms ,
      ),
    );
  }

  _handleTap(LatLng point) async {
    _handletap = true;
    ByteData byteData = await rootBundle.load('assets/locationmark10.png');
    Uint8List imageData = byteData.buffer.asUint8List();
    // Create a BitmapDescriptor from the image data
    BitmapDescriptor customIcon = BitmapDescriptor.fromBytes(imageData);
    setState(() {
      _target = point;
      Marker? tap = _markers.isNotEmpty ? _markers.first : null;

      _markers.clear();
      if (tap != null) {
        _markers.add(tap);
      }
      // Convert the set to a list
      List<Marker> markerList = _markers.toList();
      // Load the custom icon image
      // Add a new marker with the custom icon
      markerList.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: InfoWindow(
          title: _appBarTitle,
        ),
        icon: customIcon,
      ));

      // Convert the list back to a set
      _markers = markerList.toSet();
    });

    // Perform reverse geocoding to get the address from coordinates
    List<Placemark> placemarks =
        await placemarkFromCoordinates(point.latitude, point.longitude);

    // Extract the location name from the placemark
    String name = placemarks.isEmpty
        ? 'Default'
        : [
            placemarks[0].name,
            placemarks[0].subLocality,
            placemarks[0].locality,
          ]
            .toList()
            .where((element) => element != null && element != '')
            .join(', ');
    String locationName = name;

    // Update the app bar title with the location name
    setState(() {
      _appBarTitle = locationName;
    });

    _showCustomBottomSheet(context);
  }
}

class MeterCalculatorWidget extends StatefulWidget {
  final Function(double) callback;

  const MeterCalculatorWidget({
    Key? key,
    required this.callback,
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

  Future<void> _loadRadiusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      meterRadius = prefs.getDouble('meterRadius') ?? 0.0;
      milesRadius = prefs.getDouble('milesRadius') ?? 0.0;
    });
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
      _radius = _imperial ? milesdefault : meterdefault;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [Row(
        children: [
          Text(
            'Radius',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          Spacer(), // ✅ pushes text to right automatically

          AutoSizeText(
            '${(_radius / (_imperial ? 1 : 1000)).toStringAsFixed(2)} ${_imperial ? 'miles' : 'Kilometers'}',
            style: TextStyle(fontSize: 14),
            maxLines: 1,
          ),
        ],
      ),
        Container(

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
              // widget.callback(_imperial ? (value * 1609.34):value);
              //  print("callback:"+widget.callback.toString());
            },
          ),
        ),
      ],
    );
  }
}

//0.05
//5.05
class ResponsiveHelper {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static double sp(BuildContext context, double mobile, double tablet) =>
      isTablet(context) ? tablet : mobile;
}