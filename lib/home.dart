import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// import 'package:tflite/tflite.dart';
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";
  late File selectedImage;
  String base64Image = "";
  var countPred = 0;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  void loadCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    // cameraController = CameraController(cameras[0], ResolutionPreset.medium, imageFormatGroup: ImageFormatGroup.yuv420);
    await cameraController!.initialize();
    cameraController!.startImageStream((imageStream) {
      setState(() {
        cameraImage = imageStream;
      });
      runModel();
    });
  }

  void runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        threshold: 0.1,
        asynch: true,
      );

      for (var element in predictions!) {
        if (countPred == 30) {
          // await cameraController!.setFlashMode(FlashMode.off);
          // final img = await cameraController!.takePicture();

          // await cameraController!.setFlashMode(FlashMode.off);
          // final XFile capturedImage = await cameraController!.takePicture();

          // // Convert XFile to Image
          // final File imageFile = File(capturedImage.path);
          // final img.Image image = img.decodeImage(await imageFile.readAsBytes());

          // double imageSharpness = calculateImageSharpness(image);
          var we = checkImageQuality();
          print("check this");
          print(we);
          if (element['label'] != '2 none') {
            if (!isSending) {
              isSending = true;
              // var bytesList = cameraImage!.planes.map((plane) => plane.bytes).toList();
              // Uint8List combinedBytes = Uint8List.fromList(
              //     bytesList.expand((bytes) => bytes).toList(),
              // );
              // var img = await convertYUVToJPEG(combinedBytes, cameraImage!.width,cameraImage!.height );
              var ss = await captureImage();
              setState(() {
                output = element['label'];
                // base64Image=convertImageToBase64(cameraImage!);
                base64Image = ss;
              });
              // print(base64Image);
              _sendPostRequest();
            }
          } else if (element['label'] == '2 none') {
            setState(() {
              output = element['label'];
              base64Image = "no face";
            });
          }
          countPred = 0;
        } else {
          countPred += 1;
        }
      }
    }
  }

Future<String> captureImage() async {
  if (cameraController!.value.isInitialized) {
    try {
      // Capture the image

      await cameraController!.setFlashMode(FlashMode.off);

      final image = await cameraController!.takePicture();
            // Convert the image to Base64
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      return base64Image;

    } catch (e) {
      // Handle any errors that occur during image capture
      print('Error capturing image: $e');
    }
  }
  return 'wrong';
}

Future<bool> checkImageQuality() async {
  String base64Image = await captureImage();
  
  if (base64Image == 'wrong') {
    // Image capture failed
    return false;
  }
  
  // Convert the base64 image back to bytes
  List<int> imageBytes = base64Decode(base64Image);
  
  // Decode the image using the `decodeImage` function from the `image` package
  img.Image capturedImage = img.decodeImage(imageBytes)!;
  
  // Calculate the image sharpness
  double sharpness = calculateImageSharpness(capturedImage);
  
  // Define a threshold value to determine if the image is clear or not
  double sharpnessThreshold = 100.0; // Adjust this value according to your needs
  
  // Check if the sharpness value is above the threshold
  bool isClear = sharpness > sharpnessThreshold;
  
  return isClear;
}


double calculateImageSharpness(img.Image image) {
  img.Image grayscaleImage = img.copyResize(image, width: 500, height: 500);
  grayscaleImage = img.grayscale(grayscaleImage);
  img.Image edgesImage = img.sobel(grayscaleImage);

  double sum = 0;
  int count = 0;

  for (int x = 0; x < edgesImage.width; x++) {
    for (int y = 0; y < edgesImage.height; y++) {
      final pixel = edgesImage.getPixel(x, y);
      sum += img.getRed(pixel);
      count++;
    }
  }

  double mean = sum / count;

  double variance = 0;
  for (int x = 0; x < edgesImage.width; x++) {
    for (int y = 0; y < edgesImage.height; y++) {
      final pixel = edgesImage.getPixel(x, y);
      double intensity = img.getRed(pixel).toDouble();
      variance += ((intensity - mean) * (intensity - mean));
    }
  }

  variance /= count;

  return variance;
}



  Future<void> _sendPostRequest() async {
    // final imageBytes = await cameraImage!.planes[0].bytes;
    // final base64Image = base64Encode(imageBytes);

    const url =
        'https://aef2-190-93-37-86.ngrok-free.app/js_public/walker_callback/82cdbffa-bb03-42b6-a553-b775961eabc3/4d5a8a7d-7d2e-4def-adc5-404de7a0de45?key=3a7fdc0069733f5e12e16f668f5da103';
    final headers = {
      'Authorization':
          'token 95613b486641cf02ca1fd4aa94c8d5955f4d1a51afa9ff30ed7372ed740c8ade',
      'Content-Type': 'application/json'
    };
    final body = jsonEncode({
      'name': 'interact',
      'ctx': {
        'image_data': base64Image,
        'expression': output,
      },
      '_req_ctx': {},
      'snt': 'urn:uuid:fc4bdf0f-ccb6-4f86-bdb6-1787f379fdf5',
    });
    print("sent request");
    // final Uri apiUrl = Uri.parse('https://shopping-app-default.firebaseio.com/products.json');

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      // var response = await http.get(apiUrl, headers: headers, body: body );
      isSending = false;
      // print('Response: ${response.body}');
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  @override
  void dispose() {
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Emotion Detection App")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(output,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
          if (base64Image.isNotEmpty)
            SelectableText(base64Image), // Display base64Image if not empty
        ],
      ),
    );
  }
}

// final test64 = "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";
