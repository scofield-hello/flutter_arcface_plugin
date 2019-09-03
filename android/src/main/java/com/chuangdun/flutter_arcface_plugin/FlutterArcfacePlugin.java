package com.chuangdun.flutter_arcface_plugin;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.arcsoft.face.FaceEngine;
import com.google.common.util.concurrent.ThreadFactoryBuilder;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import org.json.JSONException;
import org.json.JSONObject;


/**
 * @author Nickey
 */
public class FlutterArcfacePlugin implements MethodCallHandler,
    PluginRegistry.ActivityResultListener {
  private static final String TAG = "FlutterArcfacePlugin";
  private static final int ACTION_REQUEST_PERMISSIONS = 0x001;
  private static final int ACTION_REQUEST_EXTRACT = 0x002;
  private static final int ACTION_REQUEST_RECOGNIZE = 0x003;

  private final static String METHOD_ACTIVE = "active";
  private final static String METHOD_EXTRACT = "extract";
  private final static String METHOD_RECOGNIZE = "recognize";

  private Result mResultSetter;

  private static final String[] NEEDED_PERMISSIONS =
      new String[]{
          Manifest.permission.CAMERA,
          Manifest.permission.READ_PHONE_STATE,
          Manifest.permission.WRITE_EXTERNAL_STORAGE
      };
  private static ThreadFactory threadFactory = new ThreadFactoryBuilder()
      .setNameFormat("arcface_pool_%d")
      .build();

  private ExecutorService threadPool = new ThreadPoolExecutor(
      1, 1, 0L, TimeUnit.MILLISECONDS,
      new LinkedBlockingQueue<Runnable>(), threadFactory);

  private Activity activity;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(),
        "flutter_arcface_plugin");
    final FlutterArcfacePlugin instance = new FlutterArcfacePlugin(registrar.activity());
    registrar.addActivityResultListener(instance);
    channel.setMethodCallHandler(instance);
  }

  private FlutterArcfacePlugin(Activity activity) {
    this.activity = activity;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (!checkPermissions()) {
      ActivityCompat.requestPermissions(activity, NEEDED_PERMISSIONS, ACTION_REQUEST_PERMISSIONS);
      result.error("请完成授权后再操作.", null, null);
      return;
    }
    mResultSetter = result;
    if (call.method.equals(METHOD_ACTIVE)) {
      String ak = call.argument("ak");
      String sk = call.argument("sk");
      Log.d(TAG, "onMethodCall: ak: " + ak);
      Log.d(TAG, "onMethodCall: sk: " + sk);
      Future<Integer> future = activeEngine(ak, sk);
      try {
        int activeCode = future.get();
        result.success(activeCode);
      } catch (Exception e) {
        result.error("激活失败.", null, null);
        Log.e(TAG, "激活任务执行失败", e);
      }
    } else if (call.method.equals(METHOD_EXTRACT)) {
      Intent intent = DetectActivity.extract(activity);
      activity.startActivityForResult(intent, ACTION_REQUEST_EXTRACT);
    } else if (call.method.equals(METHOD_RECOGNIZE)) {
      String srcFeatureData = call.argument("src_feature");
      double similarThreshold = call.argument("similar_threshold");
      float floatSimilarThreshold = Float.parseFloat(Double.toString(similarThreshold));
      Log.d(TAG, "onMethodCall: src_feature: " + srcFeatureData);
      Log.d(TAG, "onMethodCall: similar_threshold: " + similarThreshold);
      Intent intent = DetectActivity.recognize(activity, floatSimilarThreshold, srcFeatureData);
      activity.startActivityForResult(intent, ACTION_REQUEST_RECOGNIZE);
    } else {
      result.notImplemented();
      Log.e(TAG, "方法未实现:" + call.method);
    }
  }

  private Future<Integer> activeEngine(final String ak, final String sk) {
    return threadPool.submit(new Callable<Integer>() {
      @Override
      public Integer call() throws Exception {
        FaceEngine faceEngine = new FaceEngine();
        return faceEngine.activeOnline(activity, ak, sk);
      }
    });
  }

  private boolean checkPermissions() {
    boolean allGranted = true;
    for (String neededPermission : NEEDED_PERMISSIONS) {
      allGranted &= ContextCompat.checkSelfPermission(activity, neededPermission)
          == PackageManager.PERMISSION_GRANTED;
    }
    return allGranted;
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == ACTION_REQUEST_EXTRACT) {
      if (resultCode == Activity.RESULT_OK) {
        try {
          String feature = data.getStringExtra("feature");
          String imageUri = data.getStringExtra("image");
          JSONObject jsonObject = new JSONObject();
          jsonObject.putOpt("feature", feature);
          jsonObject.putOpt("image", imageUri);
          mResultSetter.success(jsonObject.toString(4));
        } catch (JSONException e) {
          mResultSetter.error("数据传递异常.", null, null);
        }
      } else {
        mResultSetter.error("人脸特征提取失败.", null, null);
      }
      return true;
    } else if (requestCode == ACTION_REQUEST_RECOGNIZE) {
      if (resultCode == Activity.RESULT_OK) {
        float similar = data.getFloatExtra("similar", 0.0f);
        mResultSetter.success(similar);
      } else {
        mResultSetter.error("人脸比对失败.", null, null);
      }
      return true;
    }
    return false;
  }
}