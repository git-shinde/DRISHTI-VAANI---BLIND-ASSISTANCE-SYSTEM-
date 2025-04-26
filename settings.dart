import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _detectUrlController = TextEditingController();
  final TextEditingController _sceneDetectUrlController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  
  String _serverUrl = "";
  String _detectUrl = "";
  String _sceneDetectUrl = "";
  String _phoneNumber = "";

  @override
  void initState() {
    super.initState();
    _loadUrls();
  }

  Future<void> _loadUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = prefs.getString('server_url') ?? 'http://127.0.0.1:5002/process_image';
      _detectUrl = prefs.getString('detect_url') ?? 'http://127.0.0.1:5000/detect';
      _sceneDetectUrl = prefs.getString('scene_detect_url') ?? 'http://127.0.0.1:5001/scene_detect';
      _phoneNumber = prefs.getString('phone_number') ?? '9321828271';

      _serverUrlController.text = _serverUrl;
      _detectUrlController.text = _detectUrl;
      _sceneDetectUrlController.text = _sceneDetectUrl;
      _phoneNumberController.text = _phoneNumber;
    });
  }

  Future<void> _saveUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrlController.text);
    await prefs.setString('detect_url', _detectUrlController.text);
    await prefs.setString('scene_detect_url', _sceneDetectUrlController.text);
    await prefs.setString('phone_number', _phoneNumberController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(labelText: 'Text Read URL',
                border: OutlineInputBorder(),),
            ),SizedBox(height: 20),

            TextField(
              controller: _detectUrlController,
              decoration: InputDecoration(
                labelText: 'Object Detection API URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Scene Detection API URL Input
            TextField(
              controller: _sceneDetectUrlController,
              decoration: InputDecoration(
                labelText: 'Scene Detection API URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveUrls,
              child: Text('Save SETTINGS'),
            ),
          ],
        ),
      ),
    );
  }
}
