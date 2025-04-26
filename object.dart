import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  FlutterTts flutterTts = FlutterTts();
  String detectedObjectsText = "Detecting..."; // This will now show detected objects
  bool isProcessing = false;
  bool isCameraInitialized = false;
  String _detectUrl = "";
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadDetectUrl();
  }

  Future<void> _loadDetectUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _detectUrl = prefs.getString('scene_detect_url') ?? 'http://127.0.0.1:5001/detect';
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("No camera available");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }

      startLiveDetection();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void startLiveDetection() {
    _detectionTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!isProcessing && isCameraInitialized && _controller != null && _controller!.value.isInitialized) {
        isProcessing = true;
        await detectObjects(); // Now detects objects
        isProcessing = false;
      }
    });
  }

  Future<void> detectObjects() async {
    try {
      if (!isCameraInitialized || _controller == null || !_controller!.value.isInitialized) {
        return;
      }

      final XFile file = await _controller!.takePicture();
      File imageFile = File(file.path);

      var request = http.MultipartRequest('POST', Uri.parse(_detectUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      List<dynamic> detectedObjects = result["detected_objects"] ?? [];

      if (mounted) {
        setState(() {
          detectedObjectsText = detectedObjects.isNotEmpty
              ? "Detected: ${detectedObjects.join(', ')}"
              : "No objects detected";
        });
      }

      if (detectedObjects.isNotEmpty) {
        String objectsList = detectedObjects.join(", ");
        String speechText = "Detected $objectsList";
        speak(speechText);
      }
    } catch (e) {
      print("Error detecting objects: $e");
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.9);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _detectionTimer?.cancel(); // Stop the timer when widget is disposed
    _controller?.dispose(); // Dispose the camera controller
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Object Detection")),
      body: Column(
        children: [
          Expanded(
            child: isCameraInitialized
                ? CameraPreview(_controller!)
                : Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black,
            child: Text(
              detectedObjectsText,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
