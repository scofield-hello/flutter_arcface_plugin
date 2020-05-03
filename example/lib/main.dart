import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_arcface_plugin/flutter_arcface_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _appId = "";
  final String _sdkKey ="";
  String feature;

  @override
  void initState() {
    super.initState();
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child:Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              FlatButton.icon(
                onPressed: _extraFeature,
                icon: Icon(Icons.fingerprint),
                label: Text("特征提取"),
              ),
              FlatButton.icon(
                onPressed: _recognize,
                icon: Icon(Icons.face),
                label: Text("人脸识别"),
              ),
            ],
          )
        ),
      ),
    );
  }

  void _extraFeature() async{
    try {
      var activeResult = await FlutterArcfacePlugin.active(_appId, _sdkKey);
      if (ArcFaceErrors.isActiveOk(activeResult)) {
        var featureResult = await FlutterArcfacePlugin.extract();
        feature = featureResult.feature;
        print("特征提取: ${featureResult.asJson()}");
      } else {
        print(ArcFaceErrors.errorMsg(activeResult));
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  void _recognize() async{
    try {
      var activeResult = await FlutterArcfacePlugin.active(_appId, _sdkKey);
      if (ArcFaceErrors.isActiveOk(activeResult)) {
        var compareResult = await FlutterArcfacePlugin.recognize(feature, 0.8);
        print("人脸比对: ${compareResult.asJson()}");
      } else {
        print(ArcFaceErrors.errorMsg(activeResult));
      }
    } on PlatformException catch (e) {
      print(e.message);
    }
  }
}