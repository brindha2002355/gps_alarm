import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AppDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return NavigationDrawer(
      backgroundColor: Colors.white,
      onDestinationSelected: onDestinationSelected,
      selectedIndex: selectedIndex,
      children: [
        // ── Header ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, height * 0.06, 20, 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: isTablet ? 26 : 22,
                child: Icon(
                  Icons.alarm,
                  color: Colors.white,
                  size: isTablet ? 26 : 22,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'GPS Alarm',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 18 : 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Location-based alerts',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // ── Section: Main ────────────────────────────────────
        _sectionLabel('MAIN', context),

        NavigationDrawerDestination(
          icon: Icon(Icons.alarm_on_outlined),
          label: Text('Saved alarms'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.alarm),
          label: Text('Set an alarm'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Settings'),
        ),

        _divider(),

        // ── Section: Communicate ─────────────────────────────
        _sectionLabel('COMMUNICATE', context),

        NavigationDrawerDestination(
          icon: Icon(Icons.share_outlined),
          label: Text('Share'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.star_outline_rounded),
          label: Text('Rate / review'),
        ),

        _divider(),

        // ── Section: App ─────────────────────────────────────
        _sectionLabel('APP', context),

        NavigationDrawerDestination(
          icon: Icon(Icons.info_outline_rounded),
          label: Text('About'),
        ),

        // ── Footer ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'GPS Alarm v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(indent: 16, endIndent: 16, thickness: 0.5);
  }
}