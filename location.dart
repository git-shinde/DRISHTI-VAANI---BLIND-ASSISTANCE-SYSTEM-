import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SMSService {
   // Replace with actual recipient's number

  static Future<void> sendLocationSMS() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phone_number') ?? "9321828271";

    try {
      Position position = await _getCurrentLocation();
      String message = "My Current Location: \nhttps://maps.google.com/?q=${position.latitude},${position.longitude}";
      
      Uri smsUri = Uri.parse("sms:$phoneNumber?body=${Uri.encodeComponent(message)}");

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        print('Could not launch SMS app');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Location permission denied';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied';
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
