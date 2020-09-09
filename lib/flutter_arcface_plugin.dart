import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class ArcFaceErrors {
  static final _androidErrors = <int, String>{
    0: "成功",
    1: "错误原因不明",//deleted
    2: "无效的参数",
    3: "引擎不支持",
    4: "内存不足",
    5: "状态错误",
    6: "用户取消相关操作",
    7: "操作时间过期",
    8: "用户暂停操作",
    9: "缓冲上溢",
    10: "缓冲下溢",
    11: "存贮空间不足",
    12: "组件不存在",
    13: "全局数据不存在",
    28673: "无效的AppId",
    28674: "无效的SDKkey",
    28675: "AppId和SDKKey不匹配",
    28676: "SDKKey和使用的SDK不匹配",
    28677: "当前系统版本不支持人脸识别",
    28678: "人脸识别SDK已过期",
    73729: "无效的输入内存",
    73730: "无效的输入图像参数",
    73731: "无效的脸部信息",
    73732: "当前设备无GPU可用",
    73733: "待比较的两个人脸特征的版本不一致",
    81921: "人脸特征检测错误未知",
    81922: "人脸特征检测内存错误",
    81923: "人脸特征检测格式错误",
    81924: "人脸特征检测参数错误",
    81925: "人脸特征检测结果置信度低",
    86017: "Engine不支持的检测属性",
    86018: "需要检测的属性未初始化",
    86019: "待获取的属性未在process中处理过",
    86020: "PROCESS不支持的检测属性,例如FR,有自己独立的处理函数",
    86021: "无效的输入图像",
    86022: "无效的脸部信息",
    90113: "文件读写权限被拒绝,请对应用授权后重试",
    90114: "SDK已激活",
    90115: "SDK未激活",
    94209: "无法解析主机地址,请检查网络后重试",
    94210: "无法连接服务器,请检查网络后重试",
    94211: "网络连接超时,请检查网络后重试",
    94212: "网络未知错误,请检查网络后重试",
    131073: "激活文件不存在",
    131074: "包名不匹配",
    131075: "包签名不匹配",
    131076: "设备不匹配，请重新激活",
    131077: "当前设备时间不正确，请调整设备时间",
    131078: "激活数据被破坏,请删除激活文件，重新进行激活",
    131079: "激活文件与SDK版本不匹配,请重新激活",
    131080: "SDK签名校验错误",
    135169: "操作系统版本不支持",
    135170: "包授权已过期",
    135171: "detectFaceScaleVal不支持",
    135172: "激活文件与SDK基础信息不匹配",
    139265: "颜色空间不支持",
    139266: "图片宽高不支持，宽度需四字节对齐",
    139267: "检测模型不支持，使用当前支持的检测模型",
    139268: "文件版本号不匹配",
    143361: "请求数据格式错误",
    143362: "请校准设备时间和时区",
    143363: "APPID||SDKKEY||PACKAGEID存在格式错误",
    143364: "APPID、PACKAGEID组合不存在",
    143365: "APPID、PACKAGEID组合授权已过期",
    143366: "包签名验证不通过",
    143367: "非法请求,请稍候重试",
    143368: "服务端签名校验错误",
    143369: "服务端解密失败",
    143370: "短时间大量请求被禁止,30分钟之后重试",
    143371: "激活数据保存异常",
    143372: "服务端未知错误",
    143373: "有效期内授权次数已超出",
    147457: "READ_PHONE_STATE权限被拒绝",
    147458: "INTERNET权限被拒绝"
  };

  static final _iOSErrors = <int, String>{
    200: "成功",
    1: "错误原因不明",
    2: "无效的参数",
    3: "引擎不支持",
    4: "内存不足",
    5: "状态错误",
    6: "用户取消相关操作",
    7: "操作时间过期",
    8: "用户暂停操作",
    9: "缓冲上溢",
    10: "缓冲下溢",
    11: "存贮空间不足",
    12: "组件不存在",
    13: "全局数据不存在",
    28672: "FreeSDK通用错误类型",
    28673: "无效的App Id",
    28674: "无效的SDK key",
    28675: "AppId和SDKKey不匹配",
    28676: "SDKKey 和使用的SDK 不匹配",
    28677: "系统版本不被当前SDK所支持",
    28678: "SDK有效期过期",
    73728: "FaceRecognition错误类型",
    73729: "无效的输入内存",
    73730: "无效的输入图像参数",
    73731: "无效的脸部信息",
    73732: "当前设备无GPU可用",
    73733: "待比较的两个人脸特征的版本不一致",
    81920: "人脸特征检测错误类型",
    81921: "人脸特征检测错误未知",
    81922: "人脸特征检测内存错误",
    81923: "人脸特征检测格式错误",
    81924: "人脸特征检测参数错误",
    81925: "人脸特征检测结果置信度低",
    86016: "ArcFace扩展错误类型",
    86017: "Engine不支持的检测属性",
    86018: "需要检测是属性未初始化",
    86019: "待获取的属性未在process中处理过",
    86020: "PROCESS不支持的检测属性",
    86021: "无效的输入图像",
    86022: "无效的脸部信息",
    90112: "人脸比对基础错误类型",
    90113: "人脸比对SDK激活失败",
    90114: "人脸比对SDK已激活",
    90115: "人脸比对SDK未激活",
    90116: "detectFaceScaleVal不支持",
    90117: "SDK版本不匹配",
    90118: "设备不匹配",
    90119: "唯一标识不匹配",
    90120: "参数为空",
    90121: "SDK已过期",
    90122: "版本不支持",
    90123: "签名错误",
    90124: "数据库插入错误",
    90125: "唯一标识符校验失败",
    90126: "输入的颜色空间不支持",
    90127: "图片宽高不支持",
    94208: "网络错误类型,请检查网络后重试",
    94209: "服务器异常",
    94210: "网络请求超时,请检查网络后重试",
    94211: "不支持的URL",
    94212: "未能找到指定的服务器",
    94213: "服务器连接失败,请检查网络后重试",
    94214: "连接丢失,请检查网络后重试",
    94215: "连接中断,请检查网络后重试",
    94216: "操作无法完成",
    94217: "未知错误"
  };

  static String errorMsg(int error) {
    if (Platform.isAndroid) {
      try {
        return _androidErrors[error];
      } catch (e) {
        return "${_androidErrors[1]}:${error}";
      }
    } else if (Platform.isIOS) {
      try {
        return _iOSErrors[error];
      } catch (e) {
        return "${_iOSErrors[1]}:${error}";
      }
    } else {
      throw UnimplementedError("不支持的系统类型.");
    }
  }

  static bool isActiveOk(int error) {
    if (Platform.isAndroid) {
      return error == 0 || error == 90114;
    } else if (Platform.isIOS) {
      return error == 200 || error == 90114;
    } else {
      throw UnimplementedError("不支持的系统类型.");
    }
  }

  static bool isOperationOk(int error) {
    if (Platform.isAndroid) {
      return error == 0;
    } else if (Platform.isIOS) {
      return error == 200;
    } else {
      throw UnimplementedError("不支持的系统类型.");
    }
  }
}

class FeatureResult {
  final String feature;
  final String image;
  const FeatureResult(this.feature, this.image);
  static fromJson(Map<dynamic, dynamic> json) {
    return FeatureResult(json['feature'], json['image']);
  }

  Map<String, String> asJson() {
    return <String, String>{'feature': feature, 'image': image};
  }
}

class CompareResult {
  final String feature;
  final double similar;
  const CompareResult(this.feature, this.similar);
  static fromJson(Map<dynamic, dynamic> json) {
    return CompareResult(json['feature'], json['similar']);
  }

  Map<String, dynamic> asJson() {
    return <String, dynamic>{'feature': feature, 'similar': similar};
  }
}

class FlutterArcfacePlugin {
  static const MethodChannel _channel = const MethodChannel('flutter_arcface_plugin');

  ///判断设备是否支持人脸识别.
  ///返回[bool] true:支持; false:不支持
  static Future<bool> isSupport() async {
    final bool isSupport = await _channel.invokeMethod('isSupport');
    return isSupport;
  }

  ///激活SDK.
  ///[ak]: APP KEY
  ///[sk]: SDK KEY
  static Future<int> active(String appId, String sdkKey) async {
    assert(appId != null && appId.isNotEmpty);
    assert(sdkKey != null && sdkKey.isNotEmpty);
    final int activeCode = await _channel.invokeMethod('active', {'ak': appId, 'sk': sdkKey});
    return activeCode;
  }

  ///提取人脸特征.
  static Future<FeatureResult> extract(
      {bool useBackCamera = false, bool genImageFile = false}) async {
    assert(useBackCamera != null);
    assert(genImageFile != null);
    dynamic result = await _channel
        .invokeMethod('extract', {'useBackCamera': useBackCamera, "genImageFile": genImageFile});
    return FeatureResult.fromJson(result);
  }

  ///人脸识别，返回相识度[0~1.0].
  ///[srcFeatureData] 经过BASE64编码后的源人脸特征.
  ///[similarThreshold] 相似度阀值.
  static Future<CompareResult> recognize(String srcFeatureData, double similarThreshold) async {
    assert(srcFeatureData != null && srcFeatureData.isNotEmpty);
    assert(similarThreshold != null && similarThreshold > 0.0);
    dynamic result = await _channel.invokeMethod(
        'recognize', {'srcFeature': srcFeatureData, 'similarThreshold': similarThreshold});
    return CompareResult.fromJson(result);
  }
}
