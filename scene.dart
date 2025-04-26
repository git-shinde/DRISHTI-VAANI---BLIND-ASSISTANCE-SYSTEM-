import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  FlutterTts flutterTts = FlutterTts();
  String detectedScene = "Detecting...";
  bool isProcessing = false;
  bool isCameraInitialized = false;
  String _sceneDetectUrl = "";
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadSceneDetectUrl();
  }

  Future<void> _loadSceneDetectUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sceneDetectUrl = prefs.getString('scene_detect_url') ?? 'http://127.0.0.1:5001/scene_detect';
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
        await detectScene();
        isProcessing = false;
      }
    });
  }

  Future<void> detectScene() async {
    try {
      if (!isCameraInitialized || _controller == null || !_controller!.value.isInitialized) {
        return;
      }

      final XFile file = await _controller!.takePicture();
      File imageFile = File(file.path);

      var request = http.MultipartRequest('POST', Uri.parse(_sceneDetectUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      String scene = result["scene"] ?? "Unknown";
      List<dynamic> detectedObjects = result["detected_objects"] ?? [];

      if (mounted) {
        setState(() {
          detectedScene = scene;
        });
      }

      if (detectedObjects.isNotEmpty) {
        String objectsList = detectedObjects.join(", ");
        String speechText = "You are in a $scene with $objectsList";
        speak(speechText);
      }
    } catch (e) {
      print("Error detecting scene: $e");
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
      appBar: AppBar(title: Text("Live Scene Detection")),
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
              "Scene: $detectedScene",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
