package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;

import android.content.Context;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App;
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R;
public class GpToastUtil {
    private static Toast toastWithoutLimit;


    public static void showToastWithoutLimit(String msg) {
        showToastWithoutLimit(msg, Toast.LENGTH_SHORT);
    }

    public static void showToastWithoutLimit(String msg, int duration) {
        if (GpUiUtils.isMainThread()) {
            showToastWithoutLimitInternal(msg, duration);
        } else {
            GpUiUtils.runOnUiThread(() -> showToastWithoutLimitInternal(msg, duration));
        }
    }

    private static void showToastWithoutLimitInternal(String msg, int duration) {
        try {
            if (TextUtils.isEmpty(msg)) {
                return;
            }
            if (toastWithoutLimit != null) {
                toastWithoutLimit.cancel();
            }
            toastWithoutLimit = new Toast(App.context);
            LayoutInflater inflate = (LayoutInflater)
                    App.context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            View v = inflate.inflate(R.layout.layout_toast, null);
            TextView tvMsg = v.findViewById(R.id.tv_alter_message);
            tvMsg.setText(msg);
            toastWithoutLimit.setGravity(Gravity.CENTER, 0, 0);
            if (v.getParent() != null) {
                ((WindowManager) v.getContext().getSystemService(Context.WINDOW_SERVICE)).removeViewImmediate(v);
            }
            toastWithoutLimit.setView(v);
            toastWithoutLimit.setDuration(duration);
            toastWithoutLimit.show();
        }catch (Throwable t){
            toastWithoutLimit = null;
            t.printStackTrace();
        }
    }


}
