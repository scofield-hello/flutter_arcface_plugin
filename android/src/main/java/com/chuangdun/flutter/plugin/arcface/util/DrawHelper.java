package com.chuangdun.flutter.plugin.arcface.util;


import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.hardware.Camera;
import com.chuangdun.flutter.plugin.arcface.widget.FaceRectView;
import java.util.List;

/**
 * 绘制人脸框帮助类，用于在{@link com.chuangdun.flutter.plugin.arcface.widget.FaceRectView}上绘制矩形
 */
public class DrawHelper {
  private static final int FACE_CENTER_MAX_GAP = 50;
  private int previewWidth, previewHeight, canvasWidth, canvasHeight, cameraDisplayOrientation, cameraId;
  private boolean isMirror;
  private boolean mirrorHorizontal = false, mirrorVertical = false;

  /**
   * 创建一个绘制辅助类对象，并且设置绘制相关的参数
   *
   * @param previewWidth 预览宽度
   * @param previewHeight 预览高度
   * @param canvasWidth 绘制控件的宽度
   * @param canvasHeight 绘制控件的高度
   * @param cameraDisplayOrientation 旋转角度
   * @param cameraId 相机ID
   * @param isMirror 是否水平镜像显示（若相机是镜像显示的，设为true，用于纠正）
   * @param mirrorHorizontal 为兼容部分设备使用，水平再次镜像
   * @param mirrorVertical 为兼容部分设备使用，垂直再次镜像
   */
  public DrawHelper(int previewWidth, int previewHeight, int canvasWidth,
      int canvasHeight, int cameraDisplayOrientation, int cameraId,
      boolean isMirror, boolean mirrorHorizontal, boolean mirrorVertical) {
    this.previewWidth = previewWidth;
    this.previewHeight = previewHeight;
    this.canvasWidth = canvasWidth;
    this.canvasHeight = canvasHeight;
    this.cameraDisplayOrientation = cameraDisplayOrientation;
    this.cameraId = cameraId;
    this.isMirror = isMirror;
    this.mirrorHorizontal = mirrorHorizontal;
    this.mirrorVertical = mirrorVertical;
  }

  public static void drawFaceRect(Canvas canvas, Rect rect, int color, int faceRectThickness) {
    if (canvas == null || rect == null) {
      return;
    }
    Paint paint = new Paint();
    paint.setStyle(Paint.Style.STROKE);
    paint.setStrokeWidth(faceRectThickness);
    paint.setColor(color);
    Path mPath = new Path();
    //左上
    mPath.moveTo(rect.left, rect.top + rect.height() / 4);
    mPath.lineTo(rect.left, rect.top);
    mPath.lineTo(rect.left + rect.width() / 4, rect.top);
    //右上
    mPath.moveTo(rect.right - rect.width() / 4, rect.top);
    mPath.lineTo(rect.right, rect.top);
    mPath.lineTo(rect.right, rect.top + rect.height() / 4);
    //右下
    mPath.moveTo(rect.right, rect.bottom - rect.height() / 4);
    mPath.lineTo(rect.right, rect.bottom);
    mPath.lineTo(rect.right - rect.width() / 4, rect.bottom);
    //左下
    mPath.moveTo(rect.left + rect.width() / 4, rect.bottom);
    mPath.lineTo(rect.left, rect.bottom);
    mPath.lineTo(rect.left, rect.bottom - rect.height() / 4);
    canvas.drawPath(mPath, paint);
  }

  public void draw(FaceRectView faceRectView, Rect faceRect) {
    if (faceRectView == null || faceRect == null) {
      return;
    }
    faceRectView.clearFaceInfo();
    Rect adjustRect = adjustRect(faceRect);
    faceRectView.addFaceInfo(adjustRect);
  }

  public void draw(FaceRectView faceRectView, List<Rect> faceRectList) {
    if (faceRectView == null) {
      return;
    }
    faceRectView.clearFaceInfo();
    if (faceRectList == null || faceRectList.size() == 0) {
      return;
    }
    faceRectView.addFaceInfo(faceRectList);
  }


  /**
   * 判断人脸框是否在FaceRectView中间位置.
   * 人脸中心点如果距离视图中心点偏差小于{@link DrawHelper#FACE_CENTER_MAX_GAP}则表明是居中的.
   * @param faceRectView 人脸预览视图
   * @param faceRect 人脸Rect
   * @return 居中返回true，反之返回false
   */
  public boolean isFaceCentered(FaceRectView faceRectView, Rect faceRect) {
    if (faceRectView == null || faceRect == null) {
      return false;
    }
    Rect adjustedRect = adjustRect(faceRect);
    int adjustedRectCenterX = adjustedRect.left + (adjustedRect.width() / 2);
    int adjustedRectCenterY = adjustedRect.top + (adjustedRect.height() / 2);
    int viewCenterX = faceRectView.getWidth() / 2;
    int viewCenterY = faceRectView.getHeight() / 2;
    return (Math.abs(viewCenterX - adjustedRectCenterX) <= FACE_CENTER_MAX_GAP)
        && (Math.abs(viewCenterY - adjustedRectCenterY) <= FACE_CENTER_MAX_GAP);
  }

  /**
   * 调整人脸框用来绘制
   *
   * @param ftRect FT人脸框
   * @return 调整后的需要被绘制到View上的rect
   */
  public Rect adjustRect(Rect ftRect) {
    int previewWidth = this.previewWidth;
    int previewHeight = this.previewHeight;
    int canvasWidth = this.canvasWidth;
    int canvasHeight = this.canvasHeight;
    int cameraDisplayOrientation = this.cameraDisplayOrientation;
    int cameraId = this.cameraId;
    boolean isMirror = this.isMirror;
    boolean mirrorHorizontal = this.mirrorHorizontal;
    boolean mirrorVertical = this.mirrorVertical;

    if (ftRect == null) {
      return null;
    }

    Rect rect = new Rect(ftRect);
    float horizontalRatio;
    float verticalRatio;
    if (cameraDisplayOrientation % 180 == 0) {
      horizontalRatio = (float) canvasWidth / (float) previewWidth;
      verticalRatio = (float) canvasHeight / (float) previewHeight;
    } else {
      horizontalRatio = (float) canvasHeight / (float) previewWidth;
      verticalRatio = (float) canvasWidth / (float) previewHeight;
    }
    rect.left *= horizontalRatio;
    rect.right *= horizontalRatio;
    rect.top *= verticalRatio;
    rect.bottom *= verticalRatio;

    Rect newRect = new Rect();
    switch (cameraDisplayOrientation) {
      case 0:
        if (cameraId == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          newRect.left = canvasWidth - rect.right;
          newRect.right = canvasWidth - rect.left;
        } else {
          newRect.left = rect.left;
          newRect.right = rect.right;
        }
        newRect.top = rect.top;
        newRect.bottom = rect.bottom;
        break;
      case 90:
        newRect.right = canvasWidth - rect.top;
        newRect.left = canvasWidth - rect.bottom;
        if (cameraId == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          newRect.top = canvasHeight - rect.right;
          newRect.bottom = canvasHeight - rect.left;
        } else {
          newRect.top = rect.left;
          newRect.bottom = rect.right;
        }
        break;
      case 180:
        newRect.top = canvasHeight - rect.bottom;
        newRect.bottom = canvasHeight - rect.top;
        if (cameraId == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          newRect.left = rect.left;
          newRect.right = rect.right;
        } else {
          newRect.left = canvasWidth - rect.right;
          newRect.right = canvasWidth - rect.left;
        }
        break;
      case 270:
        newRect.left = rect.top;
        newRect.right = rect.bottom;
        if (cameraId == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          newRect.top = rect.left;
          newRect.bottom = rect.right;
        } else {
          newRect.top = canvasHeight - rect.right;
          newRect.bottom = canvasHeight - rect.left;
        }
        break;
      default:
        break;
    }

    /**
     * isMirror mirrorHorizontal finalIsMirrorHorizontal
     * true         true                false
     * false        false               false
     * true         false               true
     * false        true                true
     *
     * XOR
     */
    if (isMirror ^ mirrorHorizontal) {
      int left = newRect.left;
      int right = newRect.right;
      newRect.left = canvasWidth - right;
      newRect.right = canvasWidth - left;
    }
    if (mirrorVertical) {
      int top = newRect.top;
      int bottom = newRect.bottom;
      newRect.top = canvasHeight - bottom;
      newRect.bottom = canvasHeight - top;
    }
    return newRect;
  }

  public int getPreviewWidth() {
    return previewWidth;
  }

  public void setPreviewWidth(int previewWidth) {
    this.previewWidth = previewWidth;
  }

  public int getPreviewHeight() {
    return previewHeight;
  }

  public void setPreviewHeight(int previewHeight) {
    this.previewHeight = previewHeight;
  }

  public int getCanvasWidth() {
    return canvasWidth;
  }

  public void setCanvasWidth(int canvasWidth) {
    this.canvasWidth = canvasWidth;
  }

  public int getCanvasHeight() {
    return canvasHeight;
  }

  public void setCanvasHeight(int canvasHeight) {
    this.canvasHeight = canvasHeight;
  }

  public int getCameraDisplayOrientation() {
    return cameraDisplayOrientation;
  }

  public void setCameraDisplayOrientation(int cameraDisplayOrientation) {
    this.cameraDisplayOrientation = cameraDisplayOrientation;
  }

  public int getCameraId() {
    return cameraId;
  }

  public void setCameraId(int cameraId) {
    this.cameraId = cameraId;
  }

  public boolean isMirror() {
    return isMirror;
  }

  public void setMirror(boolean mirror) {
    isMirror = mirror;
  }

  public boolean isMirrorHorizontal() {
    return mirrorHorizontal;
  }

  public void setMirrorHorizontal(boolean mirrorHorizontal) {
    this.mirrorHorizontal = mirrorHorizontal;
  }

  public boolean isMirrorVertical() {
    return mirrorVertical;
  }

  public void setMirrorVertical(boolean mirrorVertical) {
    this.mirrorVertical = mirrorVertical;
  }
}