package com.chuangdun.flutter.plugin.arcface;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.util.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.google.common.util.concurrent.ThreadFactoryBuilder;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * @author Nickey
 */
public class FlutterArcfacePlugin
    implements MethodCallHandler, PluginRegistry.ActivityResultListener {

  private static final String TAG = "FlutterArcfacePlugin";
  private static final int ACTION_REQUEST_PERMISSIONS = 0x001;
  private static final int ACTION_REQUEST_EXTRACT = 0x002;
  private static final int ACTION_REQUEST_RECOGNIZE = 0x003;

  private static final String METHOD_IS_SUPPORT = "isSupport";
  private static final String METHOD_ACTIVE = "active";
  private static final String METHOD_EXTRACT = "extract";
  private static final String METHOD_RECOGNIZE = "recognize";
  private static final String[] NEEDED_PERMISSIONS =
      new String[]{
          Manifest.permission.CAMERA,
          Manifest.permission.READ_PHONE_STATE,
          Manifest.permission.WRITE_EXTERNAL_STORAGE
      };
  private static ThreadFactory threadFactory =
      new ThreadFactoryBuilder().setNameFormat("arcface_pool_%d").build();
  private Result mResultSetter;
  private ExecutorService threadPool =
      new ThreadPoolExecutor(
          1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>(), threadFactory);

  private Activity activity;

  private FlutterArcfacePlugin(Activity activity) {
    this.activity = activity;
  }

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel =
        new MethodChannel(registrar.messenger(), "flutter_arcface_plugin");
    final FlutterArcfacePlugin instance = new FlutterArcfacePlugin(registrar.activity());
    registrar.addActivityResultListener(instance);
    channel.setMethodCallHandler(instance);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals(METHOD_IS_SUPPORT)) {
      result.success(VERSION.SDK_INT >= VERSION_CODES.KITKAT && VERSION.SDK_INT <= VERSION_CODES.R);
      return;
    }
    if (!checkPermissions()) {
      ActivityCompat.requestPermissions(activity, NEEDED_PERMISSIONS, ACTION_REQUEST_PERMISSIONS);
      result.error("PERMISSION_DENIED.", "请在授予应用必要的权限后重试.", null);
      return;
    }
    mResultSetter = result;
    if (call.method.equals(METHOD_ACTIVE)) {
      String ak = call.argument("ak");
      String sk = call.argument("sk");
      Future<Integer> future = activeEngine(ak, sk);
      try {
        int activeCode = future.get();
        result.success(activeCode);
      } catch (Exception e) {
        result.error("PLUGIN_ERROR", "人脸引擎激活出错.", null);
        Log.e(TAG, "激活任务执行失败", e);
      }
    } else if (call.method.equals(METHOD_EXTRACT)) {
      boolean useBackCamera = call.hasArgument("useBackCamera") ?
          call.<Boolean>argument("useBackCamera") : false;
      boolean genImageFile = call.hasArgument("genImageFile") ?
          call.<Boolean>argument("genImageFile") : false;
      Intent intent = DetectActivity.extract(activity, useBackCamera, genImageFile);
      activity.startActivityForResult(intent, ACTION_REQUEST_EXTRACT);
    } else if (call.method.equals(METHOD_RECOGNIZE)) {
      String srcFeatureData = call.argument("srcFeature");
      boolean useBackCamera = call.hasArgument("useBackCamera") ?
          call.<Boolean>argument("useBackCamera") : false;
      double similarThreshold = call.<Double>argument("similarThreshold");
      float floatSimilarThreshold = Float.parseFloat(Double.toString(similarThreshold));
      Intent intent = DetectActivity.recognize(activity, useBackCamera, floatSimilarThreshold, srcFeatureData);
      activity.startActivityForResult(intent, ACTION_REQUEST_RECOGNIZE);
    } else {
      result.notImplemented();
      Log.e(TAG, "方法未实现:" + call.method);
    }
  }

  private Future<Integer> activeEngine(final String ak, final String sk) {
    return threadPool.submit(
        new Callable<Integer>() {
          @Override
          public Integer call() throws Exception {
            int combinedMask =
                FaceEngine.ASF_FACE_DETECT
                    | FaceEngine.ASF_LIVENESS
                    | FaceEngine.ASF_FACE_RECOGNITION
                    | FaceEngine.ASF_FACE3DANGLE;
            FaceEngine faceEngine = new FaceEngine();
            int afCode = faceEngine
                .init(activity, DetectMode.ASF_DETECT_MODE_VIDEO,
                    DetectFaceOrientPriority.ASF_OP_270_ONLY,
                    16, 20, combinedMask);
            if (afCode == ErrorInfo.MOK) {
              faceEngine.unInit();
              return ErrorInfo.MOK;
            } else {
              return FaceEngine.activeOnline(activity, ak, sk);
            }
          }
        });
  }

  private boolean checkPermissions() {
    boolean allGranted = true;
    for (String neededPermission : NEEDED_PERMISSIONS) {
      allGranted &=
          ContextCompat.checkSelfPermission(activity, neededPermission)
              == PackageManager.PERMISSION_GRANTED;
    }
    return allGranted;
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    try {
      if (requestCode == ACTION_REQUEST_EXTRACT) {
        switch (resultCode) {
          case Activity.RESULT_FIRST_USER:
            String error = data.getStringExtra("error");
            mResultSetter.error("PLUGIN_ERROR", error, null);
            return true;
          case Activity.RESULT_CANCELED:
            mResultSetter.error("PLUGIN_ERROR", "用户已取消操作.", null);
            return true;
          case Activity.RESULT_OK:
            String feature = data.getStringExtra("feature");
            String imageUri = data.getStringExtra("image");
            Map<String, String> featureResult = new HashMap<>(2);
            featureResult.put("feature", feature);
            featureResult.put("image", imageUri);
            mResultSetter.success(featureResult);
            return true;
          default:
            mResultSetter.error("PLUGIN_ERROR", "无效的错误码.", null);
            return true;
        }
      } else if (requestCode == ACTION_REQUEST_RECOGNIZE) {
        switch (resultCode) {
          case Activity.RESULT_FIRST_USER:
            String error = data.getStringExtra("error");
            mResultSetter.error("PLUGIN_ERROR", error, null);
            return true;
          case Activity.RESULT_CANCELED:
            mResultSetter.error("PLUGIN_ERROR", "用户已取消操作.", null);
            return true;
          case Activity.RESULT_OK:
            float similar = data.getFloatExtra("similar", 0.0f);
            String feature = data.getStringExtra("feature");
            Map<String, Object> compareResult = new HashMap<>(2);
            compareResult.put("feature", feature);
            compareResult.put("similar", similar);
            mResultSetter.success(compareResult);
            return true;
          default:
            mResultSetter.error("PLUGIN_ERROR", "无效的错误码.", null);
            return true;
        }
      }
    } catch (Exception e) {
      Log.e(TAG, "onActivityResult: ", e);
    }
    return true;
  }
}
