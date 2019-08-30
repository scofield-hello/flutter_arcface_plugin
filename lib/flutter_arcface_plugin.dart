import 'dart:async';

import 'package:flutter/services.dart';

class FlutterArcfacePlugin {
  static const MethodChannel _channel = const MethodChannel('flutter_arcface_plugin');

  ///激活SDK.
  ///[ak]: APP KEY
  ///[sk]: SDK KEY
  static Future<int> active(String ak, String sk) async {
    assert(ak != null && ak.isNotEmpty);
    assert(sk != null && sk.isNotEmpty);
    final int activeCode = await _channel.invokeMethod('active', {'ak': ak, 'sk': sk});
    return activeCode;
  }
}
