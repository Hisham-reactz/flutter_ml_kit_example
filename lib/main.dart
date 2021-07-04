import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google ML Kit example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Google ML Kit example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final imageLabeler = GoogleMlKit.vision.imageLabeler();
  final _picker = ImagePicker();
  CameraController? _controller;
  Directory? tempDir;
  String? tempPath;
  List? imageLabel;
  PickedFile? pickedFile;
  InputImage? inputImage;
  bool imgType = false;
  String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  @override
  void dispose() {
    _controller?.dispose();
    // imageCache!.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0XFFFF47474D),
      systemNavigationBarDividerColor: Color(0XFFFFE0BC1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    _controller = CameraController(
        CameraDescription(
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
            name: '0'),
        ResolutionPreset.max);
    _controller!.initialize().then((_) async {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  void getImgLabel(String? path) async {
    if (path == null) {
      setState(() {
        imgType = false;
      });
      pickedFile = await _picker.getImage(source: ImageSource.gallery);
      inputImage = InputImage.fromFilePath(pickedFile!.path);
    } else {
      setState(() {
        imgType = true;
      });
      inputImage = InputImage.fromFilePath(path);
    }
    final List<ImageLabel> labels =
        await imageLabeler.processImage(inputImage!);
    print(labels.first.label);
    setState(() {
      imageLabel = [labels.first.label, labels.first.confidence];
      tempPath = path == null ? pickedFile!.path : path;
    });
  }

  void takePicz() async {
    tempDir = await getTemporaryDirectory();
    String abc = getRandomString(5);
    tempPath = tempDir!.path + '/img$abc.jpeg';
    await _controller?.takePicture().then((value) => value.saveTo(tempPath!));

    getImgLabel(tempPath);
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
        home: Scaffold(
            body: Stack(children: <Widget>[
      Center(
          child: Transform.scale(
              scale: 2,
              child: AspectRatio(
                  aspectRatio: 1,
                  child: CameraPreview(
                    _controller!,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(tempPath != null ? 0.7 : 0.1),
                          shape: BoxShape.rectangle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(tempPath != null ? 1 : 0.5),
                                blurRadius: 5.0,
                                spreadRadius: 2.0,
                                offset: Offset.zero),
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(tempPath != null ? 1 : 0.5),
                                blurRadius: 5.0,
                                spreadRadius: 2.0,
                                offset: Offset.fromDirection(360.00, 400.00)),
                          ]),
                    ),
                  )))),
      Align(
          alignment: Alignment.bottomCenter,
          child: IconButton(
              onPressed: tempPath == null
                  ? takePicz
                  : () {
                      setState(() {
                        tempPath = null;
                        // imageLabel = null;
                        // pickedFile = null;
                        // inputImage = null;
                      });
                    },
              icon: Icon(
                tempPath == null ? Icons.camera : Icons.close,
                size: 35,
                color: Colors.white,
              ))),
      if (tempPath == null)
        Align(
            alignment: Alignment.bottomLeft,
            child: IconButton(
                onPressed: () => getImgLabel(null),
                icon: Icon(
                  Icons.photo_library,
                  size: 35,
                  color: Colors.white,
                ))),
      if (tempPath != null)
        Center(
            child: SizedBox(
          child: Image.file(
            imgType ? File(tempPath!) : File(pickedFile!.path),
            fit: BoxFit.contain,
          ),
        )),
      if (imageLabel != null)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
              padding: EdgeInsets.all(13),
              child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: 'Label : ${imageLabel![0]}',
                      style:
                          TextStyle(color: Colors.orangeAccent, fontSize: 25),
                      children: [
                        TextSpan(
                            text:
                                '\n Confidence : ${(imageLabel![1] * 100).toString().substring(0, 5)}%'),
                      ]))),
        )
    ])));
  }
}
