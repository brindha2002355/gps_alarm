import 'dart:math';

import 'package:audioplayers/audioplayers.dart'; // Add this line
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitiled/Homescreens/save_alarm_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Map screen page.dart';
import '../about page.dart';
import '../drawer.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMetricSystem = true;
  double radius = 0;
  double meterRadius = 0.1; // Initial value for meter radius
  double milesRadius = 0.1;
  GoogleMapController? mapController;
  LocationData? _currentLocation;
  bool _isCameraMoving = false;
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;

  bool _atleastOneoptionsSelected() {
    return _selectedOptions.isNotEmpty;
  }

  _navigateToAlarmspage() {
    if (_atleastOneoptionsSelected()) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => MyAlarmsPage()));
      return true;
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Attention"),
              content: Text('Please select at least one option to proceed.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
      return false;
    }
  }

  updateradiusvalue(value) {
    setState(() {
      radius = value;
    });
  }

  List<String> ringtones = [];
  bool listFileExists = true;
  String? _selectedUnit; // Variable to store the selected unit
  // Dropdown options
  List<String> _units = ['Metric system (m/km)', 'Imperial system (mi/ft)'];
  String? selectedRingtone;

  String? kSharedPrefVibrate = 'vibrateEnabled';
  String? kSharedPrefBoth = 'useBoth';
  Map<String, String> _optionMap = {
    'Alarms': 'alarms',
    'Vibrate': 'vibrate',
    'Alarms in Silent Mode': 'alarms in silent mode'
  };
  Set<String> _selectedOptions = {};

  DropdownButton<String> _buildRingtoneDropdown() {
    return DropdownButton<String>(
      value: selectedRingtone,
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
      items: ringtones
          .map((ringtone) => DropdownMenuItem<String>(
                value: ringtone,
                child: Text(ringtone.split('/').last),
              ))
          .toList(),
      onChanged: (String? value) async {
        if (value != null) {
          setState(() {
            selectedRingtone = value;
            // Save selected ringtone
          });
          await _saveSettings(); // ✅ CORRECT

          _playRingtone(value);

          print("SAVED RINGTONE: $value");
       //   _saveSettings(selectedRingtone!);
          // _saveSelectedRingtone(value);
    //      _playRingtone(selectedRingtone!);
          // await flutterLocalNotificationsPlugin
          //     .resolvePlatformSpecificImplementation<
          //     AndroidFlutterLocalNotificationsPlugin>()
          //     ?.deleteNotificationChannel("my_foreground");
        }
      },
      hint: Text("Select Ringtone",
          style: Theme.of(context).textTheme.bodyMedium),
      underline: Container(
        height: 2,
        color: Colors.transparent,
      ),
    );
  }

  String kSharedPrefOption = 'selected_option';

  Future<void> _loadRadiusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load meter radius (convert from kilometers if stored)
      meterRadius = prefs.getDouble('meterRadius')?.toDouble() ?? 100;
      meterRadius /= 1000; // Convert kilometers to meters if previously stored

      // Load miles radius
      milesRadius = prefs.getDouble('milesRadius') ?? 0.10;

      // Load unit system preference (default to metric)
      _isMetricSystem = prefs.getBool('unitSystem') ?? true;
    });
  }

  Future<void> _loadRingtones() async {
    try {
      if (listFileExists) {
        // Check if list.txt exists (optional)
        ringtones = await rootBundle.loadString('assets/list.txt').then(
              (data) => data.split(','),
            );
      } else {
        // Handle the case where list.txt is missing (optional)
        // You could list filenames directly or provide a default message
      }
    } on FlutterError catch (e) {
      // Handle error if list.txt is missing or inaccessible
      print("Error loading ringtones: $e");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedRingtone = prefs.getString('selectedRingtone') ?? "alarm6.mp3";
    });
  }

  Future<void> _saveRadiusData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('meterRadius', meterRadius * 1000); // Store in meters
    await prefs.setDouble('milesRadius', milesRadius);

    // Optionally save unit system preference
    await prefs.setBool(
        'unitSystem', _isMetricSystem); // Save current preference
  }

  // Future<void> _saveSelectedRingtone(String ringtone) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //
  //     await prefs.setString('selectedRingtone', ringtone);
  //     print('Selected ringtone saved: $ringtone');
  //   } catch (e) {
  //     print('Error saving selected ringtone: $e');
  //   }
  // }

  Future<void> handleScreenChanged(int index) async {
    switch (index) {
      case 0:
        if (_navigateToAlarmspage()) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MyAlarmsPage()),
            (Route<dynamic> route) => false,
          );
        }

        break;
      case 1:
        if (_navigateToAlarmspage()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        }

        break;
      case 2:
        Navigator.of(context).pop();
        break;
      case 3:
        final RenderBox box = context.findRenderObject() as RenderBox;
        Share.share(
          'Check out my awesome app! Download it from the app store: https://play.google.com/store/apps/details?id=com.inodesys.gps_alarm&hl=en',
          subject: 'Share this amazing app!',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
        break;
      case 4:
        _launchInBrowser(playStoreUri);
        break;
      case 5:
        if (_navigateToAlarmspage()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => About()),
          );
        }
        break;
    }
  }

  Future<void> _playRingtone(String ringtone) async {
    // Ensure assets/alarm_ringtones/ is the correct path
    final ringtonePath = '$ringtone';
    try {
      await _audioPlayer.play(AssetSource(ringtonePath));
      // await _audioPlayer.setSource(AssetSource(ringtonePath));
      // await _audioPlayer.resume(); // Start playing the ringtone
    } catch (e) {
      if (e is PlatformException) {
        print(
            'Audio playback error: ${e.message}'); // Log the entire error message
      } else {
        print('Unexpected error: $e');
      }
    }
  }

  Future<void> _saveAllSettings() async {
    await _saveRadiusData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSetSettings', true);
  }

  void _handleSettingsSet() async {
    _audioPlayer.stop();
    await _saveAllSettings();
    _navigateToAlarmspage();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop(); // Stop the audio player when the widget is disposed
  }

  String selectedOptionKey = 'selectedOption';
  String selectedRingtoneKey = 'selectedRingtone';
  String isSwitchedKey = 'isSwitched';

  // Function to store switch valueo
  void initState() {
    super.initState();
    // _selectedOptions.add(_optionMap['Alarms']!);
    _loadSelectedUnit();
    _loadRingtones();
    _loadRadiusData();
    _loadSettings();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
    _updateMarkerAndCamera();
  }

  Future<void> _getCurrentLocation() async {
    _currentLocation = await location.getLocation();
    _updateMarkerAndCamera();
    _showBottomSheetWithMap();
  }

  void _updateMarkerAndCamera() {
    if (_currentLocation != null) {
      final position =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 15)));
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: position,
            infoWindow: InfoWindow(title: 'Current Location'),
          ),
        );
      });
    }
  }


  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (selectedRingtone != null) {
      await prefs.setString('selectedRingtone', selectedRingtone!);
    }

    await prefs.setStringList('selectedOptions', _selectedOptions.toList());

    print("SAVED OPTIONS: $_selectedOptions");
    print("SAVED RINGTONE: $selectedRingtone");
  }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final selectedOptions = prefs.getStringList('selectedOptions') ??
          <String>['alarms'];
      _selectedOptions = selectedOptions.toSet();

      // Also reload ringtone here
      selectedRingtone = prefs.getString('selectedRingtone') ?? "alarm6.mp3";
    });
  }

  void _saveSelectedUnit(String newValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedUnit', newValue);
    setState(() {
      _selectedUnit = newValue;
    });
  }

  Future _loadSelectedUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedUnit = prefs.getString('selectedUnit');
      _imperial = (_selectedUnit == 'Imperial system (mi/ft)');
      radius = _imperial ? 1.24 : 2000;
    });
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  int screenIndex = 2;
  final Uri playStoreUri = Uri(
    scheme: 'https',
    host: 'play.google.com',
    path: 'store/apps/details',
    queryParameters: {'id': 'com.inodesys.gps_alarm', 'hl': 'en'},
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isSwitched = false;
  SharedPreferences? prefs;

  @override
  bool _imperial = false;

  void _setMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
    });
  }

  void _showBottomSheetWithMap() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 800,
          child: Stack(children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                zoom: 15,
                target: _currentLocation != null
                    ? LatLng(_currentLocation!.latitude!,
                        _currentLocation!.longitude!)
                    : LatLng(0, 0),
              ),
              onMapCreated: (GoogleMapController controller) {
                controller.animateCamera(
                    CameraUpdate.newCameraPosition(CameraPosition(
                  target: LatLng(_currentLocation!.latitude!,
                      _currentLocation!.longitude!),
                  zoom: 15,
                )));
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.cancel,
                  size: 36,
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      drawer:  AppDrawer( selectedIndex: screenIndex,
        onDestinationSelected: handleScreenChanged,
      ),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: InkWell(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Icon(
              Icons.menu,
              size: 25,
              color: Colors.black,
            )),
        centerTitle: true,
        title: Text(
          textAlign: TextAlign.center,
          "Settings",
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: height / 37.8,
              ),
              Text(
                'Units',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              DropdownButton<String>(
                value: _selectedUnit,
                onChanged: (newValue) {
                  setState(() {
                    _selectedUnit = newValue;
                  });
                  _loadSelectedUnit();
                  _saveSelectedUnit(newValue!);
                  _isMetricSystem = newValue == 'Metric system (m/km)';
                },
                hint: Text('Metric system (m/km)'),
                style: Theme.of(context).textTheme.bodyMedium,
                underline: Container(
                  height: height / 378,
                  color: Colors.transparent,
                ),
                icon: Icon(Icons.arrow_drop_down),
                isExpanded: true,
                items: _units.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
              ),
              Divider(),
              SizedBox(
                height: height / 37.8,
              ),
              Text(
                'Select a Ring Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Column(
              //   children: [
              //     ..._optionMap.keys.map((option) {
              //       if (option == 'Alarms in Silent Mode') {
              //         // Show "Alarms in Silent Mode" only if "Alarms" is selected
              //         return Visibility(
              //           visible:
              //           _selectedOptions.contains(_optionMap['Alarms']),
              //           child: CheckboxListTile(
              //             title: Text(option),
              //             value: _selectedOptions.contains(_optionMap[option]),
              //             onChanged: (bool? value) {
              //               setState(() {
              //                 if (value!) {
              //                   _selectedOptions.add(_optionMap[option]!);
              //                 } else {
              //                   _selectedOptions.remove(_optionMap[option]);
              //                 }
              //                 print(_selectedOptions);
              //                 _saveSettings(selectedRingtone!);
              //               });
              //             },
              //           ),
              //         );
              //       }
              //       else {
              //         return CheckboxListTile(
              //           title: Text(option),
              //           value: _selectedOptions.contains(_optionMap[option]),
              //           onChanged: (bool? value) {
              //             setState(() {
              //               if (value!) {
              //                 _selectedOptions.add(_optionMap[option]!);
              //               } else {
              //                 _selectedOptions.remove(_optionMap[option]);
              //                 if (option == 'Alarms') {
              //                   _selectedOptions.remove(
              //                       _optionMap['Alarms in Silent Mode']);
              //                 }
              //               }
              //               print(_selectedOptions);
              //               _saveSettings(selectedRingtone!);
              //             });
              //           },
              //         );
              //       }
              //     }).toList(),
              //     Visibility(
              //       visible: _selectedOptions.contains(_optionMap['Alarms']),
              //       child: Container(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Divider(),
              //             SizedBox(
              //               height: MediaQuery.of(context).size.height / 37.8,
              //             ),
              //             Text(
              //               'Alarm',
              //               style: Theme.of(context).textTheme.titleLarge,
              //             ),
              //             _buildRingtoneDropdown(),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ],
              // ),\
              // Column(
              //   children: [
              //     ...['Vibrate', 'Alarms'].map((option) {
              //       if (option == 'Vibrate') {
              //         return CheckboxListTile(
              //           title: Text(option),
              //           value: _selectedOptions.contains(_optionMap[option]),
              //           onChanged: (bool? value) async {
              //             setState(() {
              //               if (value!) {
              //                 _selectedOptions.add(_optionMap[option]!);
              //               } else {
              //                 _selectedOptions.remove(_optionMap[option]);
              //               }
              //
              //               // ✅ CORRECT
              //
              //             //  _playRingtone(value);
              //
              //               print("SAVED RINGTONE: $value");
              //           //    _saveSettings(selectedRingtone!);
              //             });
              //             print(_selectedOptions);
              //
              //             await _saveSettings();
              //           },
              //         );
              //       } else if (option == 'Alarms') {
              //         // return Column(
              //         //   children: [
              //         //     CheckboxListTile(
              //         //       title: Text(option),
              //         //       value:
              //         //           _selectedOptions.contains(_optionMap[option]),
              //         //       onChanged: (bool? value) async {
              //         //         setState(() {
              //         //           if (value!) {
              //         //             _selectedOptions.add(_optionMap[option]!);
              //         //           } else {
              //         //             _selectedOptions.remove(_optionMap[option]);
              //         //           }
              //         //         //  print(_selectedOptions);
              //         //          // _saveSettings(selectedRingtone!);
              //         //         });
              //         //         print(_selectedOptions);
              //         //
              //         //         await _saveSettings();
              //         //       },
              //         //
              //         //     ),
              //         //     Visibility(
              //         //       visible:
              //         //           _selectedOptions.contains(_optionMap[option]),
              //         //       child: Container(
              //         //         child: Column(
              //         //           crossAxisAlignment: CrossAxisAlignment.start,
              //         //           children: [
              //         //             SizedBox(
              //         //               height: MediaQuery.of(context).size.height /
              //         //                   37.8,
              //         //             ),
              //         //             Text(
              //         //               'Alarm',
              //         //               style:
              //         //                   Theme.of(context).textTheme.titleLarge,
              //         //             ),
              //         //             _buildRingtoneDropdown(),
              //         //           ],
              //         //         ),
              //         //       ),
              //         //     ),
              //         //   ],
              //         // );
              //       return   CheckboxListTile(
              //           title: Text('Alarms'),
              //           value: true,              // ✅ always checked
              //           onChanged: null,          // ❌ disabled (cannot uncheck)
              //           controlAffinity: ListTileControlAffinity.leading,
              //         );
              //       } else {
              //         return Container();
              //       }
              //     }).toList(),
              //   ],
              // ),
              Column(
                children: [
                  // Vibrate
                  CheckboxListTile(
                    title: Text('Vibrate'),
                    value: _selectedOptions.contains('vibrate'),
                    onChanged: (bool? value) async {
                      setState(() {
                        if (value!) {
                          _selectedOptions.add('vibrate');
                        } else {
                          _selectedOptions.remove('vibrate');
                        }
                      });
                      await _saveSettings();
                    },
                  ),

                  // Alarms (always ON but looks normal)
                  CheckboxListTile(
                    title: Text('Alarms'),
                    value: true,
                    onChanged: (bool? value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Alarms is always enabled and cannot be changed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }, // do nothing
                  ),
                ],
              ),
              Divider(),
              SizedBox(
                height: height / 37.8,
              ),
              Text(
                'Radius',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: height / 75.6,
              ),
              Container(
                child: Column(
                  children: [
                    // Visibility widget for the Meter slider
                    Visibility(
                      visible: _isMetricSystem,
                      // Show only if metric system is selected
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AutoSizeText(
                                maxFontSize: 12,
                                minFontSize: 10,
                                maxLines: 1,
                                'Radius in Meter',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            Spacer(),
                              AutoSizeText(
                              maxFontSize: 12,
                                minFontSize: 10,
                                maxLines: 1,
                                '${(meterRadius).toStringAsFixed(_imperial ? 2 : 2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text("km"),
                            ],
                          ),
                          Slider(
                            divisions: 10,
                            min: 0.1,
                            max: 3,
                            // Adjust max value according to your requirement
                            value: meterRadius,
                            onChanged: (double value) {
                              setState(() {
                                meterRadius =
                                    double.parse(value.toStringAsFixed(2));
                              });
                              _saveRadiusData();
                            },
                          ),
                        ],
                      ),
                    ),
                    // Visibility widget for the Miles slider
                    Visibility(
                      visible: !_isMetricSystem,
                      // Show only if imperial system is selected
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Radius in Miles',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(
                                width: width / 2.4,
                              ),
                              Text(
                                '${milesRadius.toStringAsFixed(_imperial ? 2 : 2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text("miles"),
                            ],
                          ),
                          Slider(
                            divisions: 10,
                            min: 0.10,
                            max: 2,
                            // Adjust max value according to your requirement
                            value: milesRadius,
                            onChanged: (double value) {
                              setState(() {
                                milesRadius =
                                    double.parse(value.toStringAsFixed(2));
                              });
                              _saveRadiusData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "The Minimum value must exceed 0.10",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(
                height: height / 75.6,
              ),
              Divider(),
              SizedBox(
                height: height / 75.6,
              ),
              Text(
                'To View a Current Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(
                height: height / 75.6,
              ),
              FilledButton(
                onPressed: () {
                  _getCurrentLocation;
                  _showBottomSheetWithMap();
                },
                child: Text("Current Location"),
              ),
              SizedBox(
                height: height / 75.6,
              ),
              Padding(
                padding: EdgeInsets.only(top: height / 15.12, left: width / 3),
                child: FilledButton(
                  onPressed: () {
                    //_savesettings(selectedRingtone!);
                    _handleSettingsSet();
                  },
                  child: Text("Set"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Method to retrieve the package name of the sound settings app

// Future<void> _pickRingtone() async {
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.audio,
//     allowCompression: true,
//   );
//
//   if (result != null) {
//     String? filePath = result.files.single.path;
//     if (filePath != null) {
//       // Use the selected ringtone file path
//       print('Selected ringtone: $filePath');
//       // You can save the file path or use it directly in your app
//     }
//   } else {
//     // User canceled the picker
//   }
// }
}
