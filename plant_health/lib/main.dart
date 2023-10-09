import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(App());

const String plantHealthModel = "PlantHealthModel"; // Replace with your plant health analysis model name

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraReady = false;

  late Interpreter _interpreter;
  late List _recognitions;

  @override
  void initState() {
    super.initState();
    loadModel();

    // Initialize the camera
    _initializeCamera();
  }

  Future<void> loadModel() async {
    Tflite.close();
    try {
      String res = (await Tflite.loadModel(
        model: "assets/$plantHealthModel.tflite",
        labels: "assets/$plantHealthModel.txt",
      ))!;
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);

    await _controller.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) {
      return;
    }

    try {
      final XFile picture = await _controller.takePicture();

      // Perform plant health analysis on the captured image
      await analyzePlantHealth(picture);

      // Display the analysis results or take further actions as needed
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<void> analyzePlantHealth(XFile image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;

    // Run your plant health analysis model on the captured image
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2, // Adjust based on your model output
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _recognitions = recognitions!;
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Plant health analysis took ${endTime - startTime}ms");
  }

  @override
  void dispose() {
    _controller.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Health Analysis'),
      ),
      body: Center(
        child: _isCameraReady
            ? CameraPreview(_controller)
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take Picture',
        child: Icon(Icons.camera),
      ),
    );
  }
}
