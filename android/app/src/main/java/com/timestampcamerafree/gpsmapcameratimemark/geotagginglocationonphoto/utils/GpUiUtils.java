package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;


import android.annotation.SuppressLint;
import android.graphics.RectF;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.View;

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App;


import androidx.annotation.RequiresApi;
import androidx.annotation.StringRes;

public class GpUiUtils {
    private static final String TAG = "UIUtils";
    private static Handler uiHandler = new Handler(Looper.getMainLooper());

    public static final Boolean isMainThread()  {
        return Looper.getMainLooper().isCurrentThread();
    }
    public static void runOnUiThread(Runnable runnable) {
        uiHandler.post(runnable);
    }

    public static final String getString(@StringRes int stringRes) {
        return App.context.getString(stringRes);
    }
    public static final String  getLocalizedText(String resourceName) {
        try{
            @SuppressLint("DiscouragedApi") int resourceId = App.context.getResources().getIdentifier(resourceName, "string", App.context.getPackageName());
            String text = App.context.getResources().getString(resourceId);
            return text;
        }
        catch (Exception e){
            return resourceName;
        }
    }
    public static final String getString(@StringRes int stringRes, Object... formatArgs) {
        return App.context.getString(stringRes, formatArgs);
    }

    public static final String getString(@StringRes int stringRes, @StringRes int stringRes2) {
        String res2 = App.context.getString(stringRes2);
        return App.context.getString(stringRes, res2);
    }

    public static RectF getViewScreenLocation(View view) {
        int[] location = new int[2];
        view.getLocationOnScreen(location);
        return new RectF(location[0], location[1], location[0] + view.getWidth(), location[1] + view.getHeight());
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
    public static boolean isRtl() {
        return App.context.getResources().getConfiguration().getLayoutDirection() == View.LAYOUT_DIRECTION_RTL;
    }


    public static int dp2px(float dp) {
        return (int) (TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp, App.context.getResources().getDisplayMetrics()) + 0.5f);
    }



}
