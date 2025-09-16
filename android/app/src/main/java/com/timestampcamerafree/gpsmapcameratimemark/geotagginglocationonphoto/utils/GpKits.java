package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;



import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Point;
import android.graphics.Rect;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Environment;
import android.os.StatFs;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.text.format.Formatter;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.Display;
import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;


import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

public class GpKits {



    public static Context mContext;
    private static final String TAG = "Kits";
    private static String deviceIdentifier = "";

    public static class Device {
        public static int screenWidth = 0;
        private static String androidId = "";
        private static int densityDpi = -1;
        private static float density = -1.0f;
        private static final List<String> mInvalidAndroidId = new ArrayList<String>() {
            {

            }
        };

        public static long getAvailableMemory() {
            return readMemInfo("MemAvailable");
        }

        private static long readMemInfo(String key) {
            BufferedReader reader = null;
            try {
                reader = new BufferedReader(new FileReader("/proc/meminfo"));
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.startsWith(key)) {
                        String[] parts = line.split("\\s+");
                        return Long.parseLong(parts[1]);  // 返回 kB 为单位的值
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (reader != null) {
                    try {
                        reader.close();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
            return 0;
        }

        public static String getAndroidId(Context context) {
            if (TextUtils.isEmpty(androidId)) {
                androidId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
                if (!isValidAndroidId(androidId)) {
                    androidId = "";
                }
            }

            return androidId;
        }

        private static boolean isValidAndroidId(String androidId) {
            return !TextUtils.isEmpty(androidId) && !mInvalidAndroidId.contains(androidId);
        }

        // 暗色模式
        public static boolean isDarkMode(Resources resources){
            return (resources.getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
        }
        // 字体大小
        public static float getFontScale(Resources resources){
            return resources.getConfiguration().fontScale;
        }
        // 显示大小
        public static float getDisplayScale(Resources resources){
            float scale = 1.0f;
            if (Build.VERSION.SDK_INT >= 24)
                scale = ((float)resources.getConfiguration().densityDpi) / DisplayMetrics.DENSITY_DEVICE_STABLE;
            return scale;
        }

        @SuppressLint("NewApi")
        public static boolean checkDeviceHasNavigationBar(Context activity) {

            //通过判断设备是否有返回键、菜单键(不是虚拟键,是手机屏幕外的按键)来确定是否有navigation bar
            boolean hasMenuKey = ViewConfiguration.get(activity)
                    .hasPermanentMenuKey();
            boolean hasBackKey = KeyCharacterMap
                    .deviceHasKey(KeyEvent.KEYCODE_BACK);

            if (!hasMenuKey && !hasBackKey) {
                // 做任何你需要做的,这个设备有一个导航栏
                return true;
            }
            return false;
        }

        /**
         * 获取屏幕宽度
         *
         * @param context
         * @return
         */
        public static int getScreenWidth(Context context) {
            if (screenWidth == 0) {
                DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
                screenWidth = displayMetrics.widthPixels;
            }

            return screenWidth;
        }

        public static DisplayMetrics getDisplayMetrics(FragmentActivity context) {
            DisplayMetrics dm = new DisplayMetrics();
            context.getWindowManager().getDefaultDisplay().getMetrics(dm);
            return dm;
        }

        /**
         * @param context 整个屏幕
         * @return
         */
        public static int getScreenRealHeight(Activity context) {
            Display display = context.getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getRealSize(size);
            int screen_height = size.y;
            return screen_height;
        }

        /**
         * @param activity
         * @return
         */
        public static int getWindowVisibleDisplayHeight(Activity activity) {
            Rect rectangle = new Rect();
            activity.getWindow().getDecorView().getWindowVisibleDisplayFrame(rectangle);
            return rectangle.height();
        }

        /**
         * 获取屏幕高度
         *
         * @param context
         * @return
         */
        public static int getScreenHeight(Context context) {
            DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
            return displayMetrics.heightPixels;
        }


        private static final int PORTRAIT = 0;
        private static final int LANDSCAPE = 1;
        @NonNull
        private volatile static Point[] mRealSizes = new Point[2];

        public static int getScreenRealHeight(@Nullable Context context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
                return getScreenHeight(context);
            }

            int orientation = context != null
                    ? context.getResources().getConfiguration().orientation
                    : context.getResources().getConfiguration().orientation;
            orientation = orientation == Configuration.ORIENTATION_PORTRAIT ? PORTRAIT : LANDSCAPE;

            if (mRealSizes[orientation] == null) {
                WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
                if (windowManager == null) {
                    return getScreenHeight(context);
                }
                Display display = windowManager.getDefaultDisplay();
                Point point = new Point();
                display.getRealSize(point);
                mRealSizes[orientation] = point;
            }
            return mRealSizes[orientation].y;
        }

        /**
         * 获取屏幕高度
         *
         * @param activity
         * @return
         */
        public static int getDisplayScreenHeight(Activity activity) {
            WindowManager windowManager = activity.getWindowManager();
            Display d = windowManager.getDefaultDisplay();
            DisplayMetrics displayMetrics = new DisplayMetrics();
            d.getMetrics(displayMetrics);
            return displayMetrics.heightPixels;
        }

        public static int getNavigationBarHeight(Context context){
            int resourceId = 0;
            int rid = context.getResources().getIdentifier("config_showNavigationBar", "bool", "android");
            if (rid!=0){
                resourceId = context.getResources().getIdentifier("navigation_bar_height", "dimen", "android");
                return context.getResources().getDimensionPixelSize(resourceId);
            }else{
                return 0;
            }
        }

        public static int getDensityDpi(Context context) {
            if (densityDpi <= 0) {
                try {
                    DisplayMetrics dm = context.getResources().getDisplayMetrics();
                    densityDpi = dm.densityDpi;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            return densityDpi;
        }
        public static float getDensity(Context context) {
            if (density <= 0) {
                try {
                    DisplayMetrics dm = context.getResources().getDisplayMetrics();
                    density = dm.density;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            return density;
        }

        public static int getStatusBarHeight(Context context){
            int resourceId = 0;
            resourceId = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
            if (resourceId != 0) {
                return context.getResources().getDimensionPixelSize(resourceId);
            } else {
                return 0;
            }
        }

        public static String getOsVersion() {
            return Build.VERSION.RELEASE;
        }

        public static String getBrand() {
            return Build.BRAND;
        }

        public static String getManufacturer() {
            return Build.MANUFACTURER;
        }

        public static String getModel() {
            return Build.MODEL;
        }

        public static String getDeviceName(Context context) {
            return Settings.Global.getString(context.getContentResolver(), Settings.Global.DEVICE_NAME);
        }

        /**
         * return deviceId(IMEI) or the unique android id
         *
         * @param context
         * @return
         */
        @SuppressLint("MissingPermission")
        public static String getDeviceIMEI(Context context) {
            return getDeviceIMEI(context, true);
        }

        @SuppressLint("MissingPermission")
        public static String getDeviceIMEI(Context context, boolean useAndroidIdReplace) {
            Log.d(TAG,"getDeviceIMEI");
            if (!TextUtils.isEmpty(deviceIdentifier)) {
                return deviceIdentifier;
            }
            String deviceUniqueIdentifier = null;
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);

            int permissionCheck = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE);

            if (permissionCheck == PackageManager.PERMISSION_GRANTED && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {//READ_PHONE_STATE获得后读取设备信息，解决未授权崩溃
                if (null != tm) {
                    deviceUniqueIdentifier = tm.getDeviceId();
                }
            }

            if (TextUtils.isEmpty(deviceUniqueIdentifier)) {
                if (useAndroidIdReplace) {
                    deviceUniqueIdentifier = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
                } else {
                    deviceUniqueIdentifier = "";
                }
            }
            return deviceUniqueIdentifier;
        }

        /**
         * @param fileName
         * @return in MB
         */
        public static long leftMemorySize(String fileName) {
            try {
                File folder = new File(fileName);
                if (folder == null) {
                    throw new IllegalArgumentException(); // so that we fall onto the backup
                }
                StatFs statFs = new StatFs(folder.getAbsolutePath());
                long blocks = statFs.getAvailableBlocksLong();
                long size = statFs.getBlockSizeLong();
                Log.d(TAG, "leftMemorySize: blocks =" + blocks + " size ="+size);
                return (blocks * size) / (1024*1024);
            } catch (IllegalArgumentException e) {
                Log.d(TAG, "leftMemorySize: e=" + e.toString());
                return -1;
            }
        }

        public static boolean less100MemorySize(String fileName) {
            try {
                File folder = new File(fileName);
                if (folder == null) {
                    return true;
                }
                StatFs statFs = new StatFs(folder.getAbsolutePath());
                long blocks = statFs.getAvailableBlocksLong();
                long size = statFs.getBlockSizeLong();
                Log.d(TAG, "leftMemorySize: blocks =" + blocks + " size ="+size);
                return (blocks * size) <100*1024*1024;
            } catch (IllegalArgumentException e) {
                return true;
            }
        }


        public static long readSDCardSpace() {
            long sdCardSize = 0;
            String state = Environment.getExternalStorageState();
            if (Environment.MEDIA_MOUNTED.equals(state)) {
                File sdcardDir = Environment.getExternalStorageDirectory();
                StatFs sf = new StatFs(sdcardDir.getPath());
                long blockSize = sf.getBlockSizeLong();
                long availCount = sf.getAvailableBlocksLong();
                sdCardSize = availCount * blockSize / 1048576;
            }
            return sdCardSize;
        }

        public static long readSystemSpace() {
            File root = Environment.getRootDirectory();
            StatFs sf = new StatFs(root.getPath());
            long blockSize = sf.getBlockSizeLong();
            long availCount = sf.getAvailableBlocksLong();
            long systemSpaceSize = availCount * blockSize / 1048576;
            return systemSpaceSize;
        }

        /**
         * file length
         *
         * @param file 文件
         * @return in MB
         */
        public static long getLogFileSize(File file) {
            long size = 0;
            if (file != null && file.exists()) {
                size = file.length() / 1048576;
            }
            return size;
        }

        public static String getSDCardSpace(Context context) {
            String sdCardSize = "";
            String state = Environment.getExternalStorageState();
            if (Environment.MEDIA_MOUNTED.equals(state)) {
                File sdcardDir = Environment.getExternalStorageDirectory();
                StatFs sf = new StatFs(sdcardDir.getPath());
                long blockSize = sf.getBlockSizeLong();
                long availCount = sf.getAvailableBlocksLong();
                sdCardSize = Formatter.formatFileSize(context,availCount * blockSize);
            }
            return sdCardSize;
        }

        /**
         *   获取android当前可用运行内存大小
         *
         */
        public static String getAvailMemory(Context context) {
            ActivityManager am = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
            ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
            am.getMemoryInfo(mi);
            // mi.availMem; 当前系统的可用内存
            return Formatter.formatFileSize(context, mi.availMem);// 将获取的内存大小规格化
        }
        /**
         *   获取android总运行内存大小
         *
         */
        public static String getTotalMemory(Context context) {
            String str1 = "/proc/meminfo";// 系统内存信息文件
            String str2;
            String[] arrayOfString;
            long initial_memory = 0;
            try {
                FileReader localFileReader = new FileReader(str1);
                BufferedReader localBufferedReader = new BufferedReader(localFileReader, 8192);
                str2 = localBufferedReader.readLine();// 读取meminfo第一行，系统总内存大小
                arrayOfString = str2.split("\\s+");
                for (String num : arrayOfString) {
                    Log.i(str2, num + "\t");
                }
                // 获得系统总内存，单位是KB
                int i = Integer.valueOf(arrayOfString[1]).intValue();
                //int值乘以1024转换为long类型
                initial_memory = new Long((long) i * 1024);
                localBufferedReader.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            return Formatter.formatFileSize(context, initial_memory);// Byte转换为KB或者MB，内存大小规格化
        }

        public static long getAvailMemoryInBytes(Context context) {
            ActivityManager am = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
            ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
            am.getMemoryInfo(mi);
            // mi.availMem; 当前系统的可用内存
            return mi.availMem;
        }

        //获取当前电量
        public static float getBatteryPercentage(Context context) {
            try{
                IntentFilter ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
                Intent batteryStatus = context.registerReceiver(null, ifilter);

                int level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
                int scale = batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1);

                float batteryPct = level / (float)scale;
                return batteryPct * 100;
            } catch (Exception e) {
                e.printStackTrace();
            }
            return -1f;
        }

    }

    public static class KeyBoard {

        public static void showSoftInput(Context context, View view) {
            try {
                if (context == null || view == null){
                    return;
                }
                InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
                if (imm != null) {
                    imm.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT);
                }
            }catch (Throwable t){
                t.printStackTrace();
            }

        }

        /**
         * 隐藏软键盘
         *
         * @param context
         * @param view
         */
        public static void hideSoftInput(Context context, View view) {
            if (context == null || view == null){
                return;
            }
            InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.hideSoftInputFromWindow(view.getWindowToken(), InputMethodManager.HIDE_NOT_ALWAYS);
            }
        }

        /**
         * 获取软键盘状态
         *
         * @param context
         * @return
         */
        public static boolean isShowSoftInput(Context context) {
            InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
            return imm != null && imm.isActive();
        }
        public static boolean isKeyboardShowed(View view) {
            if (view == null) {
                return false;
            }
            try {
                InputMethodManager inputManager = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
                return inputManager.isActive(view);
            } catch (Exception e) {
            }
            return false;
        }
    }

    public static class Dimens {
        public static float dpToPx(Context context, float dp) {
            return dp * context.getResources().getDisplayMetrics().density;
        }

        public static float pxToDp(Context context, float px) {
            return px / context.getResources().getDisplayMetrics().density;
        }

        public static int pxToDp(Context context, int px) {
            return (int) (px / context.getResources().getDisplayMetrics().density);
        }

        public static int dpToPxInt(Context context, float dp) {
            return (int) (dpToPx(context, dp) + 0.5f);
        }

        public static int pxToDpCeilInt(Context context, float px) {
            return (int) (pxToDp(context, px) + 0.5f);
        }

        public static int dp2px(Context context, float dpValue) {
            return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dpValue, context.getResources().getDisplayMetrics());
        }

        public static int sp2px(Context context, int spValue) {
            return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, spValue, context.getResources().getDisplayMetrics());
        }
    }


}
