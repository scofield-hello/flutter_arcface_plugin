package com.chuangdun.flutter.plugin.arcface.model;

import com.arcsoft.face.ErrorInfo;
import com.arcsoft.face.FaceEngine;
import com.arcsoft.face.FaceFeature;
import com.arcsoft.face.FaceInfo;
import com.google.common.base.Preconditions;
import com.google.common.base.Verify;
import java.util.concurrent.Callable;

/**
 * 人脸特征提取异步任务
 *
 * @author Nick
 */
public class FaceFeatureTask implements Callable<FaceFeatureTask.FaceFeatureTaskResult> {

  private FaceEngine faceEngine;

  private FaceInfo faceInfo;

  private int format;

  private int height;

  private byte[] nv21Data;

  private int width;

  public FaceFeatureTask(FaceEngine faceEngine, byte[] nv21Data, int width, int height, int format,
    FaceInfo faceInfo) {
    this.width = width;
    this.height = height;
    this.format = format;
    this.faceInfo = faceInfo;
    this.nv21Data = nv21Data;
    this.faceEngine = faceEngine;
  }


  @Override
  public FaceFeatureTaskResult call() throws Exception {
    Preconditions.checkNotNull(faceInfo);
    Preconditions.checkNotNull(nv21Data);
    Preconditions.checkNotNull(faceEngine);
    FaceFeature faceFeature = new FaceFeature();
    int code = faceEngine.extractFaceFeature(nv21Data, width, height,
      format, faceInfo, faceFeature);
    Verify.verify(code == ErrorInfo.MOK, "人脸特征提取失败，错误码：%s", code);
    return new FaceFeatureTaskResult(nv21Data, faceFeature);
  }

  public static class FaceFeatureTaskResult{

    private final  byte[] nv21Data;
    private final FaceFeature faceFeature;

    public FaceFeatureTaskResult(byte[] nv21Data, FaceFeature faceFeature){
      this.nv21Data = nv21Data;
      this.faceFeature = faceFeature;
    }

    public byte[] getNv21Data() {
      return nv21Data;
    }

    public FaceFeature getFaceFeature() {
      return faceFeature;
    }
  }
}
