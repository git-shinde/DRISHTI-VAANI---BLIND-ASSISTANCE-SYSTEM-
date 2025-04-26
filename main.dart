import 'package:app/scene.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'voice.dart'; // Import the new VoiceHelper class
import 'object.dart';
import 'read.dart';
import 'location.dart';
import 'call.dart';
import 'volume_btn.dart';
import 'settings.dart';

void main() {
  runApp(const BlindAssistanceApp());
}

class BlindAssistanceApp extends StatelessWidget {
  const BlindAssistanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blind Assistance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(252, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(240, 1, 145, 241),
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: AlignmentDirectional(0, 0),
          child: Text(
            'BLIND ASSISTANCE APP',
            style: TextStyle(
              fontFamily: 'Noto Serif',
              color: Colors.white,
              fontSize: 23,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: false,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color.fromARGB(255, 0, 0, 0)), // 3-line menu icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: AlignmentDirectional(0, -1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/ICON.png',
                width: 377.1,
                height: 115,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeatureButton(
  context,
  'DETECT OBJECT',
  () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ObjectDetectionScreen()),
      );
    }, 
  
),
                    _buildFeatureButton(
  context,
  'DETECT SCENE',
  () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  },
),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeatureButton(
                      context,
                      'READ TEXT',
                      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LiveTextDetectionScreen()),
        );
      },
                    ),
                    _buildFeatureButton(
                      context,
                      'SPEED DIAL',
                      CallService.makePhoneCall,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeatureButton(
                      context,
                      'LOCATE ME',
                      () async {
            await SMSService.sendLocationSMS(); // ✅ Directly send location
          },
                    ),
                    _buildFeatureButton(
                      context,
                      'ACTIVATE VOICE',
                      () => VoiceHelper.startListening(context), // Call voice function directly
                    ),
                    VoiceButtonHandler(parentContext: context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.44,
      height: 160,
      decoration: BoxDecoration(
        color: const Color.fromARGB(150, 1, 145, 241),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Color.fromARGB(62, 20, 26, 27),
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(239, 0, 9, 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(16),
                elevation: 0,
              ),
              child: SizedBox(
                width: 130,
                height: 100,
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      color: Color.fromARGB(255, 231, 231, 231),
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Send the location message **AFTER** the screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SMSService.sendLocationSMS();
      Navigator.pop(context); // Automatically go back after sending the message
    });

    return Scaffold(
      appBar: AppBar(title: Text("Sending Location...")),
      body: Center(child: Text("Your location is being shared...")),
    );
  }
}
