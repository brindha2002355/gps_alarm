import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:alarmplayer/alarmplayer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitiled/Homescreens/settings.dart';
import 'package:untitiled/Track.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../Apiutils.dart';
import '../Map screen page.dart';
import '../about page.dart';
import '../adhelper.dart';
import '../drawer.dart';
import '../main.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class MyAlarmsPage extends StatefulWidget {
  const MyAlarmsPage({
    super.key,
  });

  @override
  _MyAlarmsPageState createState() => _MyAlarmsPageState();
}

class _MyAlarmsPageState extends State<MyAlarmsPage> {
  LatLng? currentLocation;
  double radius = 0;
  bool isFavorite = false;
  List<AlarmDetails> alarms = [];
  bool _imperial = false;
  StreamSubscription? bgServiceListener;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  InterstitialAd? _interstitialAd;

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

    return _imperial ? (distance / 1609) : (distance / 1000);
  }

  @override
  void dispose() {
    bgServiceListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _interstitialAd?.show();
    _loadSelectedUnit();
    loadData();

    bgServiceListener =
        FlutterBackgroundService().on('alarmPlayed').listen((event) {
      print('played');
      print(event);
      if (mounted) {
        var newAlarms = alarms.map((AlarmDetails alarm) {
          if (alarm.id == event?["alarmId"]) {
            alarm.isEnabled = false;
          }
          return alarm;
        }).toList();
        setState(() {
          alarms.clear();
          alarms.addAll(newAlarms);
          saveData();
        });
        print(alarms);
      } else {
        print('not mounted');
      }
    });
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

  Future<void> _loadSelectedUnit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedUnit = prefs.getString('selectedUnit');
    double meterdefault = prefs.getDouble('meterRadius') ?? 2000;
    double milesdefault = prefs.getDouble('milesRadius') ?? 1.04;
    print("metersdefault:" + meterdefault.toString());
    print("milesdefault:" + milesdefault.toString());
    print("selectedUnit:" + selectedUnit!);
    setState(() {
      _imperial = (selectedUnit == 'Imperial system (mi/ft)');
    });
  }

  Future<void> sendEmail(BuildContext context) async {
    final email = Email(
      body: 'GPSAlarm',
      subject: 'feedback',
      recipients: ['brindhakarthi02@gmail.com'],
    );
    try {
      await FlutterEmailSender.send(email);
      // Your email sending code using mailer or flutter_email_sender
    } on PlatformException catch (e) {
      if (e.code == 'not_available') {
        print('No email client found!');
        // Show a user-friendly message explaining the issue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No email client found on this device. Please configure a default email app.'),
          ),
        );
      } else {
        // Handle other potential errors
        print('Error sending email: ${e.message}');
      }
    }
  }

  void updateFavoriteStatus(int index, bool isFavorite) {
    setState(() {
      alarms[index].isFavourite = isFavorite;
      saveData(); // Save the updated list of alarms
    });
  }

  // Future<void> loadData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.reload();
  //   List<String>? alarmsJson = prefs.getStringList('alarms');
  //   if (alarmsJson != null) {
  //     setState(() {
  //       alarms = alarmsJson
  //           .map((json) => AlarmDetails.fromJson(jsonDecode(json)))
  //           .toList();
  //     });
  //   }
  //   double? storedLatitude = prefs.getDouble('current_latitude');
  //   double? storedLongitude = prefs.getDouble('current_longitude');
  //   setState(() {
  //     if (storedLatitude != null && storedLongitude != null) {
  //       currentLocation = LatLng(storedLatitude, storedLongitude);
  //       print('original location: ($storedLatitude, $storedLongitude)');
  //       // Marker? tap = _markers.length > 1 ? _markers.last : null;
  //     }
  //   });
  // }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    List<String>? alarmsJson = prefs.getStringList('alarms');
    if (alarmsJson != null) {
      setState(() {
        alarms = alarmsJson
            .map((json) => AlarmDetails.fromJson(jsonDecode(json)))
            .toList();
      });
      print('Alarms loaded: ${alarms.length}');
    } else {
      print('No alarms found');
    }

    double? storedLatitude = prefs.getDouble('current_latitude');
    double? storedLongitude = prefs.getDouble('current_longitude');
    setState(() {
      if (storedLatitude != null && storedLongitude != null) {
        currentLocation = LatLng(storedLatitude, storedLongitude);
        print('Original location: ($storedLatitude, $storedLongitude)');
      } else {
        print('No location found');
      }
    });
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> alarmsJson =
        alarms.map((alarm) => alarm.toJson()).toList();

    prefs.setStringList(
        'alarms', alarmsJson.map((json) => jsonEncode(json)).toList());

    //prefs.reload();
  }

  int screenIndex = 0;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void handleScreenChanged(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop();
        break;
      case 1:
        Navigator.of(context).pop();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => MyHomePage()));
        break;
      case 2:
        Navigator.of(context).pop();
        // Navigator.pushNamed(context, '/thirdpage');
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => Settings())); //Navigate to screen3
        break;
      case 3:
        Navigator.of(context).pop();
        final RenderBox box = context.findRenderObject() as RenderBox;
        Share.share(
          'Check out my awesome app! Download it from the app store: https://play.google.com/store/apps/details?id=com.inodesys.gps_alarm&hl=en',
          subject: 'Share this amazing app!',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
        break;
      case 4:
        Navigator.of(context).pop();
        _launchInBrowser(playStoreUri);
        break;
      case 5:
        Navigator.of(context).pop();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => About()));
        break;
    }
  }

  final Uri playStoreUri = Uri(
    scheme: 'https',
    host: 'play.google.com',
    path: 'store/apps/details',
    queryParameters: {'id': 'com.inodesys.gps_alarm', 'hl': 'en'},
  );
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return FutureBuilder(
      future: checkLocation(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return WillPopScope(
          onWillPop: () async {
            final shouldExit = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Exit App'),
                content: Text('Are you sure you want to exit?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    // Close the dialog, don't exit
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    // Close the dialog, exit the app
                    child: Text('Exit'),
                  ),
                ],
              ),
            );
            return shouldExit ?? false; // Default to not exiting the app
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              // backgroundColor: Color(0xffFFEF9A9A),
              title: Text("GPS Alarm"),
            ),
            drawer: AppDrawer( selectedIndex: screenIndex,
              onDestinationSelected: handleScreenChanged,
            ),
            // NavigationDrawer(
            //   onDestinationSelected: (int index) {
            //     handleScreenChanged(
            //         index); // Assuming you have a handleScreenChanged function
            //   },
            //   selectedIndex: screenIndex,
            //   children: <Widget>[
            //     SizedBox(
            //       height: height / 23.625,
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.alarm_on_outlined), // Adjust size as needed
            //       label: Text('Saved Alarms'),
            //       // Set selected based on screenIndex
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.alarm),
            //       label: Text('Set a Alarm'),
            //       // Set selected based on screenIndex
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.settings_outlined),
            //       label: Text('Settings'),
            //       // Set selected based on screenIndex
            //     ),
            //     Divider(),
            //     Padding(
            //       padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            //       child: Text(
            //         'Communicate', // Assuming this is the header
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.share_outlined),
            //       label: Text('Share'),
            //
            //       // Set selected based on screenIndex
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.rate_review_outlined),
            //       label: Text('Rate/Review'),
            //       // Set selected based on screenIndex
            //     ),
            //     Divider(),
            //     Padding(
            //       padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            //       child: Text(
            //         'App', // Assuming this is the header
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //     ),
            //     NavigationDrawerDestination(
            //       icon: Icon(Icons.error_outline_outlined),
            //       label: Text('About'),
            //       // Set selected based on screenIndex
            //     ),
            //   ],
            // ),
            body: Stack(
              children: [
                alarms.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Alarmplayer alarmplayer = Alarmplayer();
                            alarmplayer.stop();
                          },
                          child:
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateX(0.3)
                              ..rotateY(0.2),
                            child: Lottie.asset(
                              'assets/newlocationalarm.json',
                              width: 300,
                              height: 300,
                              delegates: LottieDelegates(
                                values: [
                                  ValueDelegate.color(
                                    ['**'],
                                    value: Color(0xffb22222),
                                  ),
                                ],
                              ),
                            ),
                          )

                        ),

                        SizedBox(height: 12),

                        Text(
                          "No Alarms",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "Create a new alarm",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
                    : Padding(
                        padding: EdgeInsets.only(
                            left: width / 45, right: width / 45, bottom: 48),
                        child: ListView.separated(
                          itemCount: alarms.length,
                          separatorBuilder: (context, index) {
                            return SizedBox(
                              height: height / 94.5,
                            );
                          },
                          itemBuilder: (context, index) {
                            return Card.filled(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${alarms[index].alarmName}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            overflow: TextOverflow
                                                .ellipsis, // Add this line
                                          ),
                                        ),
                                        Switch(
                                          // This bool value toggles the switch.
                                          value: alarms[index].isEnabled,
                                          onChanged: (value) async {
                                            setState(() {
                                              alarms[index].isEnabled = value;
                                            });
                                            await saveData();
                                            final service =
                                                FlutterBackgroundService();
                                            if (value) {
                                              if (!(await service
                                                  .isRunning())) {
                                                print(
                                                    'starting service from toggle');
                                                await service.startService();
                                              }
                                            } else {
                                              print('checking for stop');
                                              print(alarms.toString());
                                              if (alarms
                                                      .where((element) =>
                                                          element.isEnabled)
                                                      .isEmpty &&
                                                  await service.isRunning()) {
                                                print('preparing to stop');
                                                service.invoke('stopService');
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "${alarms[index].notes}",
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              Text(
                                                currentLocation != null
                                                    ? (calculateDistance(
                                                            LatLng(
                                                                currentLocation!
                                                                    .latitude,
                                                                currentLocation!
                                                                    .longitude),
                                                            LatLng(
                                                                alarms[index]
                                                                    .lat,
                                                                alarms[index]
                                                                    .lng))) // Divide by 1000 to convert meters to kilometers
                                                        .toStringAsFixed(
                                                            1) // Adjust the precision as needed
                                                    : "3 km",
                                                // Default value if currentLocation is null
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                              Text(
                                                _imperial ? "miles" : "Km",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // IconButton(
                                        //    onPressed: () {  final alarmToDelete = alarms[
                                        //    index]; // Store the alarm for later
                                        //
                                        //    // Show confirmation Snackbar
                                        //    ScaffoldMessenger.of(context).showSnackBar(
                                        //      SnackBar(
                                        //        content: Text(
                                        //            'Are you sure you want to delete "${alarmToDelete.alarmName}"?'),
                                        //        action: SnackBarAction(
                                        //          label: 'Delete',
                                        //          onPressed: () {
                                        //            setState(() {
                                        //              alarms.removeAt(index);
                                        //            });
                                        //            saveData();
                                        //          },
                                        //        ),
                                        //      ),
                                        //    );
                                        //    }, icon: Icon(Icons.delete),color: Theme.of(context).colorScheme.error,
                                        //     ),
                                        IconButton(
                                          onPressed: () {
                                            final alarmToDelete = alarms[
                                                index]; // Store the alarm for later

                                            // Show confirmation dialog
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Delete Alarm'),
                                                  content: Text(
                                                      'Are you sure you want to delete "${alarmToDelete.alarmName}"?'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        setState(() {
                                                          alarms
                                                              .removeAt(index);
                                                        });
                                                        saveData();
                                                        final service =
                                                            FlutterBackgroundService();
                                                        if (alarms
                                                                .where((element) =>
                                                                    element
                                                                        .isEnabled)
                                                                .isEmpty &&
                                                            await service
                                                                .isRunning()) {
                                                          print(
                                                              'preparing to stop');
                                                          service.invoke(
                                                              'stopService');
                                                        }
                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog
                                                      },
                                                      child: Text('Delete'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          icon: Icon(Icons.delete),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),

                                        IconButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                    builder: (context) => Track(
                                                          alarm: alarms[index],
                                                        )));
                                          },
                                          icon: Icon(Icons.edit),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),

                                        // Switch(
                                        //   value: alarms[index].isEnabled,
                                        //   onChanged: (value) {
                                        //     setState(() {
                                        //       alarms[index].isEnabled = value;
                                        //       saveData();
                                        //     });
                                        //   },
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                _bannerAd != null
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      )
                    : Container(
                        height: 50,
                        color: Colors.transparent,
                      )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(CupertinoIcons.plus),
              onPressed: () async {
                await _interstitialAd?.show();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MyHomePage()));
              },
            ),
          ),
        );
      },
    );
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
              //Text(_radius.toStringAsFixed(_imperial ? 2:0)+' ${_imperial ? 'miles' : 'meters'}'),
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
              // widget.callback(_imperial ? (value * 1609.34):value);
              //  print("callback:"+widget.callback.toString());
            },
          ),
        ),
      ],
    );
  }
}
