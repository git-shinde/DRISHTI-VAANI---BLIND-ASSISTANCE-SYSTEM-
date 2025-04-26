import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';
import 'voice.dart'; // Import your voice program

class VoiceButtonHandler extends StatefulWidget {
  final BuildContext parentContext;

  const VoiceButtonHandler({super.key, required this.parentContext});

  @override
  _VoiceButtonHandlerState createState() => _VoiceButtonHandlerState();
}

class _VoiceButtonHandlerState extends State<VoiceButtonHandler> {
  late VolumeController _volumeController;
  double previousVolume = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize VolumeController using the appropriate constructor
    _volumeController = VolumeController.instance; // Ensure this is the correct usage

    // Get initial volume level
    _volumeController.getVolume().then((volume) {
      setState(() {
        previousVolume = volume;
      });
    });

    // Listen for volume changes
    _volumeController.addListener((volume) {
      if (volume > previousVolume) {
        // Detect volume up press
        _triggerVoiceListening();
      }
      setState(() {
        previousVolume = volume; // Update previous volume
      });
    });

    // Optionally hide the system volume UI
    VolumeController.instance.showSystemUI = false;
  }

  @override
  void dispose() {
    // Remove the volume listener
    _volumeController.removeListener();
    super.dispose();
  }

  void _triggerVoiceListening() {
    // Call the voice helper function from your VoiceHelper class
    VoiceHelper.startListening(widget.parentContext);
  }

  @override
  Widget build(BuildContext context) {
    // This widget does not render any visible UI
    return const SizedBox.shrink();
  }
}
