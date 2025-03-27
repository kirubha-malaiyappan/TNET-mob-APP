import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:login_page/line_page.dart';
import 'package:login_page/res/styles/app_styles.dart';
import 'package:login_page/res/styles/media.dart';
import 'package:login_page/providers/auth_provider.dart';
import 'package:login_page/providers/location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  final String email;

  const LocationPage({super.key, required this.email});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  void initState() {
    super.initState();
    // Fetch locations when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).fetchLocations();
    });
  }

  @override
  void dispose() {
    // Reset location provider state when navigating away
    Provider.of<LocationProvider>(context, listen: false).reset();
    super.dispose();
  }

  String extractUsername(String email) {
    return email.split('@')[0];
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear login data
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Selection'),
        backgroundColor: AppStyles.secondBaseColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              _logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(top: size.height * 0.1, left: 20, right: 20),
        children: [
          Column(
            children: [
              Container(
                height: size.height * 0.15,
                width: size.width * 0.3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppMedia.user_icon),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Text(
                "Hi ${extractUsername(widget.email)}!",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Archivo',
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          if (locationProvider.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                locationProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Location Dropdown (Chennai)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppStyles.basecolor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: locationProvider.isLoadingLocations
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : DropdownButton<String>(
                    value: locationProvider.selectedLocation,
                    hint: Text(
                      'Choose Location',
                      style: TextStyle(color: AppStyles.textColor),
                    ),
                    dropdownColor: AppStyles.dropdownColor,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: locationProvider.locations
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: AppStyles.textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      locationProvider.setSelectedLocation(newValue);
                    },
                  ),
          ),
          const SizedBox(height: 20),
          // Shop Floor Dropdown (Styled like the Location dropdown)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppStyles.basecolor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: locationProvider.isLoadingShopFloors
                ? Center(
                    child: CircularProgressIndicator(color: AppStyles.textColor))
                : DropdownButton<String>(
                    value: locationProvider.selectedShopFloor,
                    hint: Text(
                      'Select Shop Floor',
                      style: TextStyle(color: AppStyles.textColor),
                    ),
                    dropdownColor: AppStyles.dropdownColor,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: locationProvider.shopFloors
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: AppStyles.textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: locationProvider.selectedLocation == null
                        ? null
                        : (String? newValue) {
                            locationProvider.setSelectedShopFloor(newValue);
                          },
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.secondBaseColor,
              foregroundColor: AppStyles.basecolor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: locationProvider.canProceed
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LinesPage(
                          factoryName: locationProvider.selectedLocation!,  
                          shopFloorName: locationProvider.selectedShopFloor!,  
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }
}



