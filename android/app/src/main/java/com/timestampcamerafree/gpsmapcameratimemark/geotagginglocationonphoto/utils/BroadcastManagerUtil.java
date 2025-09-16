package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;

import android.content.Intent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.wifi.WifiManager;
import android.util.Log;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App;

public class BroadcastManagerUtil {
    private static final String LOCAL_MESSAGE_ACTION = "com.local.action.Message";
    private static final String LOCAL_MESSAGE = "message";

    private static final String LOCAL_TIME_STATUS_MESSAGE_ACTION = "com.local.action.time.status.Message";


    public static final String timeServiceError = "timeService:error";

    public static final String reloadLocation = "reloadLocation";

    public static final String locationError = "locationError";
    public static final String locationSucc = "locationSucc";
    private BroadcastManagerUtil() {
    }

    public static void sendLocalMessage(String message) {
        Log.d("tag","sendLocalMessage ${message}"+message);
        Intent intent = new Intent(LOCAL_MESSAGE_ACTION);
        intent.putExtra(LOCAL_MESSAGE, message);
        LocalBroadcastManager.getInstance(App.context).sendBroadcast(intent);
    }



    public static void registerLocalMessageReceiver(BroadcastReceiver receiver) {

        LocalBroadcastManager.getInstance(App.context)
                .registerReceiver(receiver, new IntentFilter(LOCAL_MESSAGE_ACTION));
    }

    public static void unregisterLocalMessageReceiver(BroadcastReceiver receiver) {
        LocalBroadcastManager.getInstance(App.context)
                .unregisterReceiver(receiver);
    }

    public static String getLocalMessage(Intent intent) {
        return intent.getStringExtra(LOCAL_MESSAGE);
    }
    public static String getLocalAction(Intent intent) {
        return LOCAL_MESSAGE_ACTION;
    }


    public static void registerNetWorkBroadcastReceiver(Context context, BroadcastReceiver netWorkReceiver) {
        IntentFilter filter = new IntentFilter();
        filter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION);
        filter.addAction(WifiManager.NETWORK_STATE_CHANGED_ACTION);
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        try {
            context.registerReceiver(netWorkReceiver, filter);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void unregisterNetWorkBroadcastReceiver(Context context, BroadcastReceiver netWorkReceiver) {
        try {
            context.unregisterReceiver(netWorkReceiver);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}