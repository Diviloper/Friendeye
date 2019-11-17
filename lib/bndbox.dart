import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

class BndBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  final String model;
  final bool borders;
  final bool people;
  final bool close;

  BndBox(this.results, this.previewH, this.previewW, this.screenH, this.screenW, this.model,
      this.borders, this.people, this.close);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBoxes() {
      return results.map((re) {
        var _x = re["rect"]["x"];
        var _w = re["rect"]["w"];
        var _y = re["rect"]["y"];
        var _h = re["rect"]["h"];
        var scaleW, scaleH, x, y, w, h;

        if (screenH / screenW > previewH / previewW) {
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          var difW = (scaleW - screenW) / scaleW;
          x = (_x - difW / 2) * scaleW;
          w = _w * scaleW;
          if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
          y = _y * scaleH;
          h = _h * scaleH;
        } else {
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          var difH = (scaleH - screenH) / scaleH;
          x = _x * scaleW;
          w = _w * scaleW;
          y = (_y - difH / 2) * scaleH;
          h = _h * scaleH;
          if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
        }

        final isPerson = re["detectedClass"] == 'person';
        final detectedClass = isPerson ? 'Person' : 'Object';
        final color = getColor(re, isPerson);
        if (color == null || (isPerson && !people)) {
          return null;
        }

        return Positioned(
          left: math.max(0, x),
          top: math.max(0, y),
          width: w,
          height: h,
          child: Container(
            padding: EdgeInsets.only(top: 5.0, left: 5.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: 3.0,
              ),
            ),
            child: Text(
              detectedClass,
              style: TextStyle(
                color: color,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList()
        ..removeWhere((e) => e == null)
        ..addAll([
          Positioned(
            left: screenW / 4,
            top: 0,
            width: 2,
            height: screenH,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 3.0,
                ),
              ),
            ),
          ),
          Positioned(
            left: screenW * 3 / 4,
            top: 0,
            width: 2,
            height: screenH,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 3.0,
                ),
              ),
            ),
          ),
        ]);
    }

    List<Widget> _renderStrings() {
      double offset = -10;
      return results.map((re) {
        offset = offset + 14;
        return Positioned(
          left: 10,
          top: offset,
          width: screenW,
          height: screenH,
          child: Text(
            "${re["label"]} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              color: Color.fromRGBO(37, 213, 253, 1.0),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList();
    }

    List<Widget> _renderKeypoints() {
      var lists = <Widget>[];
      results.forEach((re) {
        var list = re["keypoints"].values.map<Widget>((k) {
          var _x = k["x"];
          var _y = k["y"];
          var scaleW, scaleH, x, y;

          if (screenH / screenW > previewH / previewW) {
            scaleW = screenH / previewH * previewW;
            scaleH = screenH;
            var difW = (scaleW - screenW) / scaleW;
            x = (_x - difW / 2) * scaleW;
            y = _y * scaleH;
          } else {
            scaleH = screenW / previewW * previewH;
            scaleW = screenW;
            var difH = (scaleH - screenH) / scaleH;
            x = _x * scaleW;
            y = (_y - difH / 2) * scaleH;
          }
          return Positioned(
            left: x - 6,
            top: y - 6,
            width: 100,
            height: 12,
            child: Container(
              child: Text(
                "● ${k["part"]}",
                style: TextStyle(
                  color: Color.fromRGBO(37, 213, 253, 1.0),
                  fontSize: 12.0,
                ),
              ),
            ),
          );
        }).toList();

        lists..addAll(list);
      });

      return lists;
    }

    final x = Stack(
      children: model == mobilenet
          ? _renderStrings()
          : model == posenet ? _renderKeypoints() : _renderBoxes(),
    );
    return x;
  }

  Color getColor(dynamic result, bool isPerson) {
    var _x = result["rect"]["x"];
    var _w = result["rect"]["w"];
    var _y = result["rect"]["y"];
    var _h = result["rect"]["h"];
    var scaleW, scaleH, x, y, w, h;
    scaleW = screenH / previewH * previewW;
    scaleH = screenH;
    var difW = (scaleW - screenW) / scaleW;
    x = (_x - difW / 2) * scaleW;
    w = _w * scaleW;
    if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
    y = _y * scaleH;
    h = _h * scaleH;
    final leftWidthBorder = screenW / 4;
    final rightWidthBorder = screenW * 3 / 4;
    final canCollision = (x + w > leftWidthBorder) && (x < rightWidthBorder);
    final criticalArea = (screenW / 2) * screenH;
    final objectArea = w * h;
    bool isBig = objectArea / criticalArea > 0.8;
    if ((x > leftWidthBorder) && (x + w < rightWidthBorder))
      isBig = objectArea / criticalArea > 0.3;
    if (!canCollision && !borders) return null;
    if (!isPerson && !isBig && close) return null;
    if (isPerson) {
      return canCollision ? Color.fromRGBO(0, 150, 200, 1.0) : Color.fromRGBO(0, 50, 100, 0.5);
    } else {
      return canCollision
          ? isBig ? Color.fromRGBO(200, 0, 0, 1.0) : Color.fromRGBO(200, 200, 0, 1.0)
          : Color.fromRGBO(50, 50, 0, 0.5);
    }
  }
}
