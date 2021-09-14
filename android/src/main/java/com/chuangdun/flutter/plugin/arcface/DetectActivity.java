package com.chuangdun.flutter.plugin.arcface;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.ImageFormat;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.hardware.Camera;
import android.hardware.Camera.CameraInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.TextureView;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.AppCompatImageButton;
import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.Face3DAngle;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.arcsoft.face.FaceSimilar;
import com.arcsoft.face.LivenessInfo;
import com.arcsoft.face.LivenessParam;
import com.arcsoft.face.VersionInfo;
import com.arcsoft.face.enums.DetectFaceOrientPriority;
import com.arcsoft.face.enums.DetectMode;
import com.chuangdun.flutter.plugin.arcface.model.FaceFeatureTask;
import com.chuangdun.flutter.plugin.arcface.model.FaceFeatureTask.FaceFeatureTaskResult;
import com.chuangdun.flutter.plugin.arcface.util.DrawHelper;
import com.chuangdun.flutter.plugin.arcface.util.camera.CameraHelper;
import com.chuangdun.flutter.plugin.arcface.util.camera.CameraListener;
import com.chuangdun.flutter.plugin.arcface.widget.FaceRectView;
import com.google.common.base.Function;
import com.google.common.base.Preconditions;
import com.google.common.base.Strings;
import com.google.common.base.Verify;
import com.google.common.base.VerifyException;
import com.google.common.collect.Lists;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFutureTask;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.common.util.concurrent.ThreadFactoryBuilder;
import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * @author Nick
 */
public class DetectActivity extends AppCompatActivity
    implements ViewTreeObserver.OnGlobalLayoutListener, OnClickListener {

  public static final String ACTION_RECOGNIZE_FACE = "recognize";
  public static final String ACTION_EXTRACT_FEATURE = "extract";
  public static final String EXTRA_GEN_IMAGE_FILE = "gen_image_file";
  public static final String EXTRA_ACTION = "action";
  public static final String EXTRA_USE_BACK_CAMERA = "use_back_camera";
  public static final String EXTRA_SRC_FEATURE = "src_feature";
  public static final String EXTRA_SIMILAR_THRESHOLD = "similar_threshold";
  private static final String TAG = "DetectActivity";
  private static final int EXTRACT_FEATURE = 0;
  private static final int COMPARE_FACE = 1;
  private static final int COMPARE_FAILED = 2;
  private static final int DEFAULT_PREVIEW_WIDTH = 320;
  private static final int DEFAULT_PREVIEW_HEIGHT = 240;
  private static ThreadFactory threadFactory = new ThreadFactoryBuilder().setNameFormat("arcface_pool_%d").build();
  private String action;

  private int afCode = -1;

  private CameraHelper cameraHelper;

  private DrawHelper drawHelper;

  private FaceEngine faceEngine;

  private FaceRectView faceRectView;
  private Handler handler;

  private HandlerThread handlerThread;

  private LinkedBlockingQueue<FaceFeatureTask> mBlockingQueue = new LinkedBlockingQueue<>(1);

  private Camera.Size previewSize;

  private TextureView previewView;

  private float similarThreshold;

  private String srcFeatureData;
  private boolean useBackCamera;
  private boolean genImageFile;

  private ExecutorService threadPool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS,
      new LinkedBlockingQueue<Runnable>(), threadFactory);

  private ListeningExecutorService service = MoreExecutors.listeningDecorator(threadPool);

  /**
   * 文本提示控件
   */
  private TextView tipView;

  public static Intent extract(Context context, boolean useBackCamera, boolean genImageFile) {
    Intent intent = new Intent(context, DetectActivity.class);
    intent.putExtra(EXTRA_ACTION, ACTION_EXTRACT_FEATURE);
    intent.putExtra(EXTRA_USE_BACK_CAMERA, useBackCamera);
    intent.putExtra(EXTRA_GEN_IMAGE_FILE, genImageFile);
    return intent;
  }

  public static Intent recognize(Context context, boolean useBackCamera, float similarThreshold,
      String srcFeatureData) {
    Intent intent = new Intent(context, DetectActivity.class);
    intent.putExtra(EXTRA_ACTION, ACTION_RECOGNIZE_FACE);
    intent.putExtra(EXTRA_USE_BACK_CAMERA, useBackCamera);
    intent.putExtra(EXTRA_SIMILAR_THRESHOLD, similarThreshold);
    intent.putExtra(EXTRA_SRC_FEATURE, srcFeatureData);
    return intent;
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_detect);
    try {
      initExtraParams(savedInstanceState);
    } catch (VerifyException e) {
      showMessage(e.getMessage());
      Intent errorResult = new Intent();
      errorResult.putExtra("error", "参数传递错误.");
      setResult(RESULT_FIRST_USER, errorResult);
      finish();
      return;
    }
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      WindowManager.LayoutParams attributes = getWindow().getAttributes();
      attributes.systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION;
      getWindow().setAttributes(attributes);
    }
    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LOCKED);
    handlerThread = new HandlerThread("handler-thread");
    handlerThread.start();
    handler = new Handler(handlerThread.getLooper()) {
      @Override
      public void handleMessage(final Message msg) {
        super.handleMessage(msg);
        switch (msg.what) {
          case EXTRACT_FEATURE:
            extractFaceFeature();
            break;
          case COMPARE_FACE:
            FaceFeature dest = (FaceFeature) msg.obj;
            byte[] srcData = Base64.decode(srcFeatureData, Base64.DEFAULT);
            FaceFeature src = new FaceFeature(srcData);
            compareFace(src, dest);
            break;
          case COMPARE_FAILED:
            runOnUiThread(new Runnable() {
              @Override
              public void run() {
                tipView.setText(R.string.compare_face_failed);
                handler.sendEmptyMessage(EXTRACT_FEATURE);
              }
            });
            break;
          default:
            break;
        }
      }
    };
    tipView = findViewById(R.id.tv_tip);
    previewView = findViewById(R.id.texture_preview);
    faceRectView = findViewById(R.id.face_rect_view);
    AppCompatImageButton navBackButton = findViewById(R.id.btn_back);
    previewView.getViewTreeObserver().addOnGlobalLayoutListener(this);
    navBackButton.setOnClickListener(this);
  }

  @Override
  protected void onSaveInstanceState(final Bundle outState) {
    outState.putString(EXTRA_ACTION, action);
    outState.putBoolean(EXTRA_USE_BACK_CAMERA, useBackCamera);
    outState.putString(EXTRA_SRC_FEATURE, srcFeatureData);
    outState.putFloat(EXTRA_SIMILAR_THRESHOLD, similarThreshold);
    outState.putBoolean(EXTRA_GEN_IMAGE_FILE, genImageFile);
    super.onSaveInstanceState(outState);
  }

  @Override
  protected void onDestroy() {
    handlerThread.quit();
    if (cameraHelper != null) {
      cameraHelper.release();
      cameraHelper = null;
    }
    unInitEngine();
    super.onDestroy();
  }

  /**
   * 在{@link #previewView}第一次布局完成后，去除该监听，并且进行引擎和相机的初始化
   */
  @Override
  public void onGlobalLayout() {
    previewView.getViewTreeObserver().removeOnGlobalLayoutListener(this);
    initEngine();
    initCamera();
  }

  private void compareFace(final FaceFeature src, final FaceFeature dest) {
    ListenableFutureTask<FaceSimilar> futureTask = ListenableFutureTask.create(new Callable<FaceSimilar>() {
      @Override
      public FaceSimilar call() throws Exception {
        Preconditions.checkNotNull(src);
        Preconditions.checkNotNull(dest);
        Preconditions.checkNotNull(faceEngine);
        FaceSimilar faceSimilar = new FaceSimilar();
        int code = faceEngine.compareFaceFeature(src, dest, faceSimilar);
        Verify.verify(code == ErrorInfo.MOK, "人脸比对失败，错误码：%s", code);
        return faceSimilar;
      }
    });
    service.submit(futureTask);
    Futures.addCallback(futureTask, new FutureCallback<FaceSimilar>() {
      @Override
      public void onFailure(@NonNull final Throwable t) {
        Log.e(TAG, String.format("人脸比对--失败，线程: %s", Thread.currentThread().getName()), t);
        handler.sendEmptyMessage(COMPARE_FAILED);
      }

      @Override
      public void onSuccess(@NonNull final FaceSimilar similar) {
        Log.i(TAG, String.format("人脸比对--成功，得分： %f", similar.getScore()));
        if (similar.getScore() < similarThreshold) {
          handler.sendEmptyMessage(COMPARE_FAILED);
        } else {
          String featureData = Base64.encodeToString(dest.getFeatureData(), Base64.DEFAULT);
          Intent data = new Intent();
          data.putExtra("similar", similar.getScore());
          data.putExtra("feature", featureData);
          setResult(RESULT_OK, data);
          finish();
        }
      }
    }, service);
  }

  private void extractFaceFeature() {
    try {
      mBlockingQueue.clear();
      FaceFeatureTask featureTask = mBlockingQueue.take();
      ListenableFutureTask<FaceFeatureTaskResult> futureTask = ListenableFutureTask.create(featureTask);
      service.submit(futureTask);
      Futures.addCallback(futureTask, new FutureCallback<FaceFeatureTaskResult>() {
        @Override
        public void onFailure(@NonNull final Throwable t) {
          Log.e(TAG, String.format("人脸特征提取--失败，线程: %s", Thread.currentThread().getName()), t);
          handler.sendEmptyMessage(EXTRACT_FEATURE);
        }

        @Override
        public void onSuccess(@NonNull final FaceFeatureTaskResult taskResult) {
          String featureData = Base64.encodeToString(taskResult.getFaceFeature().getFeatureData(), Base64.DEFAULT);
          Log.d(TAG, String.format("人脸特征提取成功: %s", featureData));
          if (srcFeatureData == null) {
            try {
              String jpegUri = null;
              if (genImageFile) {
                String newJpeg = saveNv21ToJpeg(taskResult.getNv21Data(), previewSize.width, previewSize.height);
                File file = new File(newJpeg);
                jpegUri = file.toURI().toString();
              }
              Intent data = new Intent();
              data.putExtra("feature", featureData);
              data.putExtra("image", jpegUri);
              setResult(RESULT_OK, data);
              finish();
            } catch (Exception e) {
              Log.e(TAG, "图片数据处理失败", e);
              handler.sendEmptyMessage(EXTRACT_FEATURE);
            }
          } else {
            Message message = new Message();
            message.what = COMPARE_FACE;
            message.obj = taskResult.getFaceFeature();
            handler.sendMessage(message);
          }
        }
      }, service);
    } catch (InterruptedException e) {
      Log.e(TAG, "extractFaceFeature: 特征提取异常", e);
      handler.sendEmptyMessage(EXTRACT_FEATURE);
    }
  }

  private String saveNv21ToJpeg(byte[] nv21Data, int width, int height) throws Exception {
    byte[] yuvData = useBackCamera ? nv21Rotate90(nv21Data, width, height) : nv21Rotate270(nv21Data, width, height);
    String filename = Strings.lenientFormat("IMG_face_%s.jpg", System.currentTimeMillis());
    Log.d(TAG, "saveNv21ToJpeg, filename: " + filename);
    File publicDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
    if (!publicDirectory.exists()) {
      Verify.verify(publicDirectory.mkdirs(), "目录创建失败，dir:" + publicDirectory.getAbsolutePath());
    }
    File jpeg = new File(publicDirectory, filename);
    if (jpeg.exists()) {
      Verify.verify(jpeg.delete(), "重名文件删除失败，filename:" + jpeg.getAbsolutePath());
    }
    Verify.verify(jpeg.createNewFile(), "文件保存失败，filename:" + jpeg.getAbsolutePath());
    // 将宽高互换
    YuvImage image = new YuvImage(yuvData, ImageFormat.NV21, height, width, null);
    FileOutputStream fileOutputStream = new FileOutputStream(jpeg);
    // 将NV21格式图片，以质量80压缩成Jpeg，并得到JPEG数据流
    image.compressToJpeg(new Rect(0, 0, image.getWidth(), image.getHeight()), 80, fileOutputStream);
    fileOutputStream.flush();
    fileOutputStream.close();
    return jpeg.getAbsolutePath();
  }

  /**
   * 此处为顺时针旋转旋转90度
   *
   * @param data        旋转前的数据
   * @param imageWidth  旋转前数据的宽
   * @param imageHeight 旋转前数据的高
   * @return 旋转后的数据
   */
  private byte[] nv21Rotate90(byte[] data, int imageWidth, int imageHeight) {
    byte[] yuvData = new byte[imageWidth * imageHeight * 3 / 2];
    int i = 0;
    for (int x = 0; x < imageWidth; x++) {
      for (int y = imageHeight - 1; y >= 0; y--) {
        yuvData[i] = data[y * imageWidth + x];
        i++;
      }
    }
    i = imageWidth * imageHeight * 3 / 2 - 1;
    for (int x = imageWidth - 1; x > 0; x = x - 2) {
      for (int y = 0; y < imageHeight / 2; y++) {
        yuvData[i] = data[(imageWidth * imageHeight) + (y * imageWidth) + x];
        i--;
        yuvData[i] = data[(imageWidth * imageHeight) + (y * imageWidth) + (x - 1)];
        i--;
      }
    }
    return yuvData;
  }

  private byte[] nv21Rotate270(byte[] nv21Data, int imageWidth, int imageHeight) {
    byte[] yuvData = new byte[imageWidth * imageHeight * 3 / 2];
    int i = 0;
    for (int x = imageWidth - 1; x >= 0; x--) {
      for (int y = 0; y < imageHeight; y++) {
        yuvData[i] = nv21Data[y * imageWidth + x];
        i++;
      }
    }
    i = imageWidth * imageHeight;
    for (int x = imageWidth - 1; x > 0; x = x - 2) {
      for (int y = 0; y < imageHeight / 2; y++) {
        yuvData[i] = nv21Data[(imageWidth * imageHeight) + (y * imageWidth) + (x - 1)];
        i++;
        yuvData[i] = nv21Data[(imageWidth * imageHeight) + (y * imageWidth) + x];
        i++;
      }
    }
    return yuvData;
  }

  private void initCamera() {
    DisplayMetrics metrics = new DisplayMetrics();
    getWindowManager().getDefaultDisplay().getMetrics(metrics);
    CameraListener cameraListener = new CameraListener() {
      @Override
      public void onCameraClosed() {
        Log.i(TAG, "onCameraClosed: ");
      }

      @Override
      public void onCameraConfigurationChanged(int cameraId, int displayOrientation) {
        if (drawHelper != null) {
          drawHelper.setCameraDisplayOrientation(displayOrientation);
        }
        Log.i(TAG, "onCameraConfigurationChanged: " + cameraId + "  " + displayOrientation);
      }

      @Override
      public void onCameraError(Exception e) {
        Log.i(TAG, "onCameraError: " + e.getMessage());
      }

      @Override
      public void onCameraOpened(Camera camera, int cameraId, int displayOrientation, boolean isMirror) {
        previewSize = camera.getParameters().getPreviewSize();
        drawHelper = new DrawHelper(previewSize.width, previewSize.height, previewView.getWidth(),
            previewView.getHeight(), displayOrientation, cameraId, isMirror, false, false);
        handler.sendEmptyMessage(0);
      }

      @Override
      public void onPreview(byte[] nv21, Camera camera) {
        if (faceRectView != null) {
          faceRectView.clearFaceInfo();
        }
        List<FaceInfo> faceInfoList = new ArrayList<FaceInfo>();
        int code = faceEngine.detectFaces(nv21, previewSize.width, previewSize.height, FaceEngine.CP_PAF_NV21,
            faceInfoList);
        if (code != ErrorInfo.MOK) {
          return;
        }
        if (faceInfoList.size() == 0) {
          tipView.setText(R.string.face_not_detected);
          return;
        }
        if (faceInfoList.size() > 1) {
          tipView.setText(R.string.detect_many_face_tips);
          if (faceRectView != null && drawHelper != null) {
            drawHelper.draw(faceRectView, Lists.transform(faceInfoList, new Function<FaceInfo, Rect>() {
              @Override
              public Rect apply(FaceInfo input) {
                return drawHelper.adjustRect(input.getRect());
              }
            }));
          }
          return;
        }
        if (faceRectView != null && drawHelper != null) {
          drawHelper.draw(faceRectView, faceInfoList.get(0).getRect());
        }
        if (!drawHelper.isFaceCentered(faceRectView, faceInfoList.get(0).getRect())) {
          tipView.setText(R.string.please_adjust_face);
          return;
        }
        code = faceEngine.process(nv21, previewSize.width, previewSize.height, FaceEngine.CP_PAF_NV21, faceInfoList,
            FaceEngine.ASF_FACE3DANGLE | FaceEngine.ASF_LIVENESS);
        if (code != ErrorInfo.MOK) {
          return;
        }
        if (useBackCamera) {
          List<Face3DAngle> angles = new ArrayList<>(1);
          code = faceEngine.getFace3DAngle(angles);
          if (code != ErrorInfo.MOK || angles.isEmpty()) {
            return;
          }
          Face3DAngle angle = angles.get(0);
          // Log.d(TAG, "onPreview: angle pitch:"+ angle.getPitch());
          // Log.d(TAG, "onPreview: angle roll:"+ angle.getRoll());
          // Log.d(TAG, "onPreview: angle yaw:"+ angle.getYaw());
          boolean rightPitch = angle.getPitch() >= -10.0f && angle.getPitch() <= 10.0f;
          boolean rightRoll = angle.getRoll() >= -110.0f && angle.getRoll() <= -70.0f;
          boolean rightYaw = angle.getYaw() >= -20.0f && angle.getYaw() <= 20.0f;
          if (angle.getStatus() != 0 || !rightPitch || !rightRoll || !rightYaw) {
            tipView.setText(R.string.adjust_face_angle);
            return;
          }
        }
        List<LivenessInfo> livenessInfoList = new ArrayList<LivenessInfo>();
        int livenessCode = faceEngine.getLiveness(livenessInfoList);
        if (livenessCode != ErrorInfo.MOK && livenessInfoList.isEmpty()) {
          return;
        }
        if (livenessInfoList.get(0).getLiveness() != LivenessInfo.ALIVE) {
          tipView.setText(R.string.please_blink);
          return;
        } else {
          tipView.setText(R.string.please_hold);
        }
        FaceFeatureTask task = new FaceFeatureTask(faceEngine, nv21, previewSize.width, previewSize.height,
            FaceEngine.CP_PAF_NV21, faceInfoList.get(0));
        mBlockingQueue.offer(task);
      }
    };
    cameraHelper = new CameraHelper.Builder()
        .previewViewSize(new Point(previewView.getMeasuredWidth(), previewView.getMeasuredHeight()))
        .previewSize(new Point(DEFAULT_PREVIEW_WIDTH, DEFAULT_PREVIEW_HEIGHT))
        .rotation(getWindowManager().getDefaultDisplay().getRotation())
        .specificCameraId(useBackCamera ? CameraInfo.CAMERA_FACING_BACK : Camera.CameraInfo.CAMERA_FACING_FRONT)
        .isMirror(false).previewOn(previewView).cameraListener(cameraListener).build();
    cameraHelper.init();
    cameraHelper.start();
  }

  private void initEngine() {
    DetectFaceOrientPriority orientPriority = useBackCamera ? DetectFaceOrientPriority.ASF_OP_90_ONLY
        : DetectFaceOrientPriority.ASF_OP_270_ONLY;
    int combinedMask = FaceEngine.ASF_FACE_DETECT | FaceEngine.ASF_LIVENESS | FaceEngine.ASF_FACE_RECOGNITION
        | FaceEngine.ASF_FACE3DANGLE;
    faceEngine = new FaceEngine();
    afCode = faceEngine.init(this, DetectMode.ASF_DETECT_MODE_VIDEO, orientPriority, 16, 20, combinedMask);
    faceEngine.setLivenessParam(new LivenessParam(0.5f));
    VersionInfo versionInfo = new VersionInfo();
    FaceEngine.getVersion(versionInfo);
    Log.i(TAG, "initEngine:  init: " + afCode + "  version:" + versionInfo);
    if (afCode != ErrorInfo.MOK) {
      showMessage(getString(R.string.init_failed, afCode));
      Intent errorResult = new Intent();
      errorResult.putExtra("error", "人脸识别引擎初始化失败:" + afCode);
      setResult(RESULT_FIRST_USER, errorResult);
      finish();
    }
  }

  private void initExtraParams(Bundle savedInstanceState) {
    if (savedInstanceState == null) {
      savedInstanceState = getIntent().getExtras();
    }
    Verify.verifyNotNull(savedInstanceState, "参数传递有误.");
    action = savedInstanceState.getString(EXTRA_ACTION, ACTION_EXTRACT_FEATURE);
    useBackCamera = savedInstanceState.getBoolean(EXTRA_USE_BACK_CAMERA, false);
    genImageFile = savedInstanceState.getBoolean(EXTRA_GEN_IMAGE_FILE, false);
    Verify.verify(ACTION_EXTRACT_FEATURE.equals(action) || ACTION_RECOGNIZE_FACE.equals(action), "参数传递有误.");
    if (ACTION_RECOGNIZE_FACE.equals(action)) {
      srcFeatureData = savedInstanceState.getString(EXTRA_SRC_FEATURE);
      similarThreshold = savedInstanceState.getFloat(EXTRA_SIMILAR_THRESHOLD, 0.8F);
      Verify.verify(similarThreshold > 0.0F, "参数传递有误.");
      Verify.verify(!Strings.isNullOrEmpty(srcFeatureData), "参数传递有误.");
    }
  }

  private void unInitEngine() {
    if (afCode == 0) {
      afCode = faceEngine.unInit();
      Log.i(TAG, "unInitEngine: " + afCode);
    }
  }

  @Override
  public void onClick(View v) {
    if (v.getId() == R.id.btn_back) {
      if (!service.isTerminated()) {
        service.shutdownNow();
      }
      setResult(RESULT_CANCELED);
      finish();
    }
  }

  void showMessage(final String message) {
    runOnUiThread(new Runnable() {
      @Override
      public void run() {
        Toast.makeText(DetectActivity.this, message, Toast.LENGTH_SHORT).show();
      }
    });
  }

  @Override
  public void onBackPressed() {
    Log.w(TAG, "按下返回键");
  }
}
