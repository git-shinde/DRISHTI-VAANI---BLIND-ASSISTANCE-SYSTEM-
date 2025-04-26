import 'dart:async';
import 'package:app/call.dart';
import 'package:app/main.dart';
import 'package:app/object.dart';
import 'package:app/read.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';

import 'scene.dart'; // Import Camera package
//import 'main.dart'; // Import main.dart to access ObjectDetectionScreen

class VoiceHelper {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static final FlutterTts _tts = FlutterTts();
  static Timer? _timeoutTimer; // Timer to track silence timeout

  static Future<void> startListening(BuildContext context) async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          _timeoutTimer?.cancel(); // Reset timer if user speaks
          String command = result.recognizedWords.toLowerCase().trim();
          if (command.isNotEmpty) {
            _handleVoiceCommand(command, context);
          }
        },
        onSoundLevelChange: (level) {
          if (level < 0.2) {
            _startSilenceTimer(context); // Start silence timer if no sound detected
          } else {
            _timeoutTimer?.cancel(); // Cancel timer if sound is detected
          }
        },
      );
    } else {
      print("Speech recognition not available");
    }
  }

  static void _handleVoiceCommand(String command, BuildContext context) async {
    if (command.contains('object')) {
      final cameras = await availableCameras(); // Fetch available cameras
      _speakAndExecute(context, 'Opening Object Detection', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObjectDetectionScreen(),
          ),
        );
      });
    } else if (command.contains('scene')) {
      final cameras = await availableCameras(); // Fetch available cameras
      _speakAndExecute(context, 'Opening Scene Detection', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(),
          ),
        );
      });
    } else if (command.contains('text')) {
      _speakAndExecute(context, 'Opening Text Reader', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTextDetectionScreen(),
          ),
        ); // Replace with actual navigation
      });
    } else if (command.contains('dial')) {
      _speakAndExecute(context, 'Opening Speed Dial', () {
        CallService.makePhoneCall(); // Replace with actual navigation
      });
    } else if (command.contains('location') || command.contains('locate')) {
      _speakAndExecute(context, 'Sending Location', () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationScreen(),
          ),
        );  // Replace with actual location logic
      });
    } else {
      _startSilenceTimer(context); // Start the silence timer if the command is unrecognized
    }
  }

  static void _speakAndExecute(BuildContext context, String message, Function action) async {
    _timeoutTimer?.cancel(); // Cancel timeout as valid command is detected
    await _speak(message);
    action(); // Execute the corresponding navigation or function
  }

  static Future<void> _speak(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.speak(message);
  }

  static void _startSilenceTimer(BuildContext context) {
    _timeoutTimer?.cancel(); // Reset previous timer if any
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      _speak("Sorry, I did not understand.");
    });
  }
}
