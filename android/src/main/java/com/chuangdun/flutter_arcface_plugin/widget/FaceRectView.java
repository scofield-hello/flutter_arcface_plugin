package com.chuangdun.flutter_arcface_plugin.widget;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Paint.Style;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.View;
import androidx.annotation.Nullable;
import com.chuangdun.flutter_arcface_plugin.R;
import com.chuangdun.flutter_arcface_plugin.util.DrawHelper;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
/**
 * @author Nick
 */
public class FaceRectView extends View {
  private Bitmap bitmap;
  private Paint mPreviewPaint;
  private int borderWidth = 20;
  private CopyOnWriteArrayList<Rect> faceRectList = new CopyOnWriteArrayList<Rect>();
  public FaceRectView(Context context) {
    this(context, null);
  }

  public FaceRectView(Context context, @Nullable AttributeSet attrs) {
    super(context, attrs);
    mPreviewPaint = new Paint();
    mPreviewPaint.setAntiAlias(true);
    mPreviewPaint.setStrokeWidth(20.0f);
    mPreviewPaint.setStyle(Style.STROKE);
    int borderColor = Color.argb(255,28,196,112);
    mPreviewPaint.setColor(borderColor);
    bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.preview);
  }

  public void addFaceInfo(Rect faceInfo) {
    faceRectList.add(faceInfo);
    postInvalidate();
  }

  public void addFaceInfo(List<Rect> faceInfoList) {
    faceRectList.addAll(faceInfoList);
    postInvalidate();
  }

  public void clearFaceInfo() {
    faceRectList.clear();
    postInvalidate();
  }

  @Override
  protected void onDraw(Canvas canvas) {
    super.onDraw(canvas);
    int width = getWidth();
    int height = getHeight();
    int radius = (Math.min(width, height) - borderWidth)/2;
    int centerX = width/2;
    int centerY = height/2;
    canvas.drawBitmap(bitmap, 0,0, mPreviewPaint);
    canvas.drawCircle(centerX, centerY, radius, mPreviewPaint);
    if (faceRectList != null && faceRectList.size() > 0) {
      for (int i = 0; i < faceRectList.size(); i++) {
        DrawHelper.drawFaceRect(canvas, faceRectList.get(i), Color.YELLOW, 5);
      }
    }
  }
}
