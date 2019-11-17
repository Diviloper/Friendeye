import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import 'bndbox.dart';
import 'camera.dart';
import 'models.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";
  bool _borders = true;
  bool _people = true;
  bool _close = false;

  @override
  void initState() {
    super.initState();
  }

  loadModel() async {
    String res;
    switch (_model) {
      case yolo:
        res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
        break;

      case mobilenet:
        res = await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite", labels: "assets/mobilenet_v1_1.0_224.txt");
        break;

      case posenet:
        res = await Tflite.loadModel(model: "assets/posenet_mv1_075_float_from_checkpoints.tflite");
        break;

      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite", labels: "assets/ssd_mobilenet.txt");
    }
    print(res);
  }

  onSelect(model) {
    setState(() {
      _model = model;
    });
    loadModel();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: _model == ""
          ? AppBar(
              title: Text('FriendEye'),
            )
          : null,
      body: _model == ""
          ? Center(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: FlatButton(
                      onPressed: () => onSelect(ssd),
                      child: Text('Tap to start detecting'),
                    ),
                  ),
                  Center(
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                          value: _borders,
                          onChanged: (bool newValue) => setState(() {
                            _borders = newValue;
                          }),
                        ),
                        Text('Show border objects detection'),
                      ],
                    ),
                  ),
                  Center(
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                          value: _people,
                          onChanged: (bool newValue) => setState(() {
                            _people = newValue;
                          }),
                        ),
                        Text('Show detected people'),
                      ],
                    ),
                  ),
                  Center(
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                          value: _close,
                          onChanged: (bool newValue) => setState(() {
                            _close = newValue;
                          }),
                        ),
                        Text('Show only close objects'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : WillPopScope(
              child: Stack(
                children: [
                  Camera(
                    widget.cameras,
                    _model,
                    setRecognitions,
                  ),
                  BndBox(
                      _recognitions == null ? [] : _recognitions,
                      math.max(_imageHeight, _imageWidth),
                      math.min(_imageHeight, _imageWidth),
                      screen.height,
                      screen.width,
                      _model,
                      _borders,
                      _people,
                      _close),
                ],
              ),
              onWillPop: () async {
                setState(() {
                  _model = '';
                });
                return false;
              }),
    );
  }
}
