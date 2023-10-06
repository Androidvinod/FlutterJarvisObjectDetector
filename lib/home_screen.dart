import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:jarvis_object_detector/main.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isWorking = false;
  String result = "";
  CameraController? cameraController;
  CameraImage? cameraImage;

  loadModel() async{
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt"
    );
  }

  initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController?.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController?.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  cameraImage = imageFromStream,
                  runModelOnStreamFrames(),
                }
            });
      });
    });
  }

  runModelOnStreamFrames() async{
    if(cameraImage != null){
      var recognization = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((e){
            return e.bytes;
          }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true
      );

      result = "";

      recognization?.forEach((response) {
          result += response["label"] + " " + (response["confidence"] as double).toStringAsFixed(2) + "\n\n";
      });

      setState(() {
        result;
      });

      isWorking = false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }

  @override
  void dispose() async{
    // TODO: implement dispose
    super.dispose();
    await Tflite.close();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/jarvis.jpg"))),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                        color: Colors.black,
                        height: 320,
                        width: 360,
                        child: Image.asset("assets/camera.jpg"),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          initCamera();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 35),
                          height: 270,
                          width: 360,
                          child: cameraImage == null
                              ? const SizedBox(
                                  height: 270,
                                  width: 360,
                                  child: Icon(
                                    Icons.photo_camera_front,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                )
                              : AspectRatio(
                                  aspectRatio:
                                      cameraController!.value.aspectRatio,
                                  child: CameraPreview(cameraController!),
                                ),
                        ),
                      ),
                    )
                  ],
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 50),
                    child: SingleChildScrollView(
                      child: Text(
                        result,
                        style: const TextStyle(
                          backgroundColor: Colors.black87,
                          color: Colors.white,
                          fontSize: 30
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
