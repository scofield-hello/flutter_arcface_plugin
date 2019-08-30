package com.chuangdun.flutter_arcface_plugin;

import android.content.pm.PackageManager;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

/** @author Nick */
public abstract class BaseActivity extends AppCompatActivity {

  protected boolean checkPermissions(String[] neededPermissions) {
    if (neededPermissions == null || neededPermissions.length == 0) {
      return true;
    }
    boolean allGranted = true;
    for (String neededPermission : neededPermissions) {
      allGranted &= ContextCompat.checkSelfPermission(this.getApplicationContext(), neededPermission)
              == PackageManager.PERMISSION_GRANTED;
    }
    return allGranted;
  }

  void showMessage(final String message) {
    runOnUiThread(
        new Runnable() {
          @Override
          public void run() {
            Toast.makeText(BaseActivity.this, message, Toast.LENGTH_SHORT).show();
          }
        });
  }
}
