package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time;

import android.content.Context;

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.IService;


public interface IGpTimeService extends IService {
    interface Callback{
        void onCurrentTime(long t);
        void onError(Exception e);
        void onComplete();
    }
    void start(Context context,Callback callback, Double lat,  Double lon);
    void refresh(Context context, Double lat,  Double lon);
    void stop();
}
