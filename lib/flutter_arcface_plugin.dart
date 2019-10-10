import 'dart:async';

import 'package:flutter/services.dart';

class ArcFaceErrors {
  static final _errors = <int, String>{
    0: "成功",
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
    28673: "无效的AppId",
    28674: "无效的SDKkey",
    28675: "AppId和SDKKey不匹配",
    28676: "SDKKey和使用的SDK不匹配",
    28677: "当前系统版本不支持人脸识别",
    73729: "无效的输入内存",
    73730: "无效的输入图像参数",
    73731: "无效的脸部信息",
    73733: "待比较的两个人脸特征的版本不一致",
    81921: "人脸特征检测错误未知",
    81922: "人脸特征检测内存错误",
    81923: "人脸特征检测格式错误",
    81924: "人脸特征检测参数错误",
    81925: "人脸特征检测结果置信度低",
    86017: "Engine不支持的检测属性",
    86018: "需要检测的属性未初始化",
    86019: "待获取的属性未在process中处理过",
    86020: "PROCESS不支持的检测属性，例如FR，有自己独立的处理函数",
    86021: "无效的输入图像",
    86022: "无效的脸部信息",
    90113: "SDK激活失败，请打开读写权限",
    90114: "SDK已激活",
    90115: "SDK未激活",
    90116: "detectFaceScaleVal不支持",
    90117: "激活文件与SDK类型不匹配，请确认使用的sdk",
    90118: "设备不匹配",
    90119: "请在清除应用数据后重试",
    90120: "参数为空",
    90121: "活体已过期",
    90122: "SDK版本不支持",
    90123: "签名错误",
    90124: "激活信息保存异常",
    90125: "唯一标识符校验失败",
    90126: "颜色空间不支持",
    90127: "图片宽高不支持，宽度需四字节对齐",
    90128: "READ_PHONE_STATE权限被拒绝",
    90129: "激活数据被破坏,请删除激活文件后重新进行激活",
    90130: "服务端未知错误",
    90131: "网络访问权限被拒绝",
    90132: "激活文件与SDK版本不匹配,请重新激活",
    90133: "设备信息太少，不足以生成设备指纹",
    90134: "客户端时间设置有误,请校准后再试",
    90135: "数据校验异常",
    90136: "传入的AppId和AppKey与使用的SDK版本不一致",
    90137: "短时间大量请求会被禁止请求,30分钟之后解封",
    90138: "激活文件不存在",
    90139: "IMAGE模式下不支持全角度(ASF_OP_0_HIGHER_EXT)检测",
    94209: "无法解析主机地址",
    94210: "无法连接服务器",
    94211: "网络连接超时",
    94212: "网络未知错误"
  };

  static String errorMsg(int error) {
    try {
      return _errors[error];
    } catch (e) {
      return _errors[1];
    }
  }

  static bool isActiveOk(int error) {
    return error == 0 || error == 90114;
  }

  static bool isOperationOk(int error) {
    return error == 0;
  }
}

class FlutterArcfacePlugin {
  static const MethodChannel _channel = const MethodChannel('flutter_arcface_plugin');

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
  static Future<dynamic> extract() async {
    final dynamic result = await _channel.invokeMethod('extract');
    return result;
  }

  ///人脸识别，返回相识度[0~1.0].
  ///[srcFeatureData] 经过BASE64编码后的源人脸特征.
  ///[similarThreshold] 相似度阀值.
  static Future<double> recognize(String srcFeatureData, double similarThreshold) async {
    assert(srcFeatureData != null && srcFeatureData.isNotEmpty);
    assert(similarThreshold != null && similarThreshold > 0.0);
    final double similar = await _channel.invokeMethod(
        'recognize', {'src_feature': srcFeatureData, 'similar_threshold': similarThreshold});
    return similar;
  }
}
