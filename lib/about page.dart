import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import 'drawer.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _AboutState extends State<About> {
  // final Uri toLaunch =
  //     Uri(scheme: 'https', host: 'www.cylog.org', path: 'headers/');
  final Uri playStoreUri = Uri(
    scheme: 'https',
    host: 'play.google.com',
    path: 'store/apps/details',
    queryParameters: {'id': 'com.inodesys.gps_alarm', 'hl': 'en'},
  );
  double radius = 0;

  void handleScreenChanged(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pop(); // Alarm List

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        break;
      case 1:
        Navigator.of(context).pop(); // Alarm List

        Navigator.of(context).pushNamedAndRemoveUntil(
            '/secondpage', (Route<dynamic> route) => false);
        break;
      case 2:
        Navigator.of(context).pop();

        Navigator.of(context).pushNamedAndRemoveUntil(
            '/thirdpage', (Route<dynamic> route) => false);
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
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/fouthpage', (Route<dynamic> route) => false);

        break;
      default:
        navigateToHomePage(context);
    }
  }

  updateradiusvalue(value) {
    setState(() {
      radius = value;
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

  @override
  void navigateToHomePage(BuildContext context) {
    Navigator.popUntil(
        context, ModalRoute.withName(Navigator.defaultRouteName));
  }

  int screenIndex = 5;
  Timer? _timer;
  bool _shouldVibrate = true;

  Future<void> startVibration() async {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
        Vibration.vibrate(duration: 500);
      });
    }
    // while (_shouldVibrate) {
    //     print("vibration is ringing");// Loop with stopping condition
    //     Vibration.vibrate(pattern: [500, 1000]); // Adjust pattern as needed
    //     await Future.delayed(Duration(milliseconds: 100)); // Adjust delay as needed
    //   }
  }

  Future<void> stopVibration() async {
    if (_timer != null) {
      _timer!.cancel();
    }
    // _shouldVibrate = false;
    // await Vibration.cancel();
  }

  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
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
      //       height: 32,
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
      //       padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
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
          "About",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text("GPS Alarm App ",
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(
                  height: 24,
                ),
                Text(
                  "A GPS Alarm app is designed to alert users when they reach a specific geographic location. This can be useful for various scenarios, such as:",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(
                  height: 16,
                ),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: "1. Commuting: Ensuring you wake up or get off at the right bus or train stop.\n\n",
                  ),
                  TextSpan(
                    text: "2. Traveling: Getting alerts when you are near tourist attractions or points of interest.\n\n",
                  ),
                  TextSpan(
                    text: "3. Daily Routines: Reminding you of tasks when you arrive at specific locations (e.g., grocery shopping when near a store).",
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),

                SizedBox(
                  height: 24,
                ),
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Padding(
                //       padding: const EdgeInsets.only(right: 150.0),
                //       child: Text("How It Works",
                //           style: Theme.of(context).textTheme.titleLarge),
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "1.Select a Location:",
                //       style: Theme.of(context).textTheme.titleMedium,
                //       textAlign: TextAlign.left,
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "1.Users can search for a location or drop a pin on a map to set the alarm point.",
                //       textAlign: TextAlign.left,
                //       style: Theme.of(context).textTheme.bodyMedium,
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "2.Set Alarm Parameters:",
                //       style: Theme.of(context).textTheme.titleMedium,
                //       textAlign: TextAlign.left,
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "1.Define the radius around the location where the alarm should trigger. \n                                                                                      2.Choose the notification type (sound, vibration, or both).",
                //       textAlign: TextAlign.left,
                //       style: Theme.of(context).textTheme.bodyMedium,
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "3.Background Monitoring:",
                //       style: Theme.of(context).textTheme.titleMedium,
                //       textAlign: TextAlign.left,
                //     ),
                //     SizedBox(
                //       height: 16,
                //     ),
                //     Text(
                //       "1.The app runs in the background, monitoring the device's location.\n                                                                                                   2.When the device enters the predefined radius, the alarm triggers.",
                //       textAlign: TextAlign.left,
                //       style: Theme.of(context).textTheme.bodyMedium,
                //     ),
                //     SizedBox(height: 16),
                //   ],
                // )

                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text("How It Works",
                //         style: Theme.of(context).textTheme.titleLarge),
                //   ],
                // ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 150.0),
                  child: Text(
                    "How It Works",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "1. Select a Location:",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 16),
                Text(
                  "Users can search for a location or drop a pin on a map to set the alarm point.",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  "2. Set Alarm Parameters:",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 16),
                Text(
                  "Define the radius around the location where the alarm should trigger.",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                Text(
                  "Choose the notification type (sound, vibration, or both).",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  "3. Background Monitoring:",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 16),
                Text(
                  "The app runs in the background, monitoring the device's location.",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                Text(
                  "When the device enters the predefined radius, the alarm triggers.",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
              ],
            ),




    ]
        ),
      ),
    ),
      ),
    );
  }
}
