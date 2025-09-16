package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit;

import android.util.Log;

import androidx.lifecycle.ViewModel;

import io.reactivex.rxjava3.disposables.CompositeDisposable;


public abstract class GpLocationViewModel extends ViewModel {

    //定位连续3次超过限制距离就认为定位可靠
//    private int getValidLocationTimes;
//    private static final int GET_LOCATION_MAX_TIMES = 2;
    private boolean forceRefreshLoc = false;//地址界面主动刷新地址

    private String largeposition="";
    private static final String TAG = "GpLocationViewModel";
    private final CompositeDisposable compositeDisposable = new CompositeDisposable();

    public GpLocationViewModel(){

    }

    public void onStop(){
        compositeDisposable.dispose();
    }

    public void onUiStart() {
//        TodayApplication.getApplicationModel().registerBaiduLocation(mLocationListener);

        //  地点刷新
//        Disposable locationDisposable = Services.as(ILocationService2.class).observeLocationInfo(RefreshStrategy.Companion.getDefaultStrategy(), LocationObserverType.WATERMARK_EDIT,null).subscribe(locationInfo -> {
//            // 获取locationInfo
//            Log.i(TAG, "on location info change,locationInfo:" + locationInfo.toString());
//            if (locationInfo.locationIsLegal() && locationInfo.getStatus() == LocationInfo.STATUS_REQUEST_PLACE_SUCCESS) { // 只响应地点刷新成功
//                TodayApplication.getApplicationModel().setLocation_type(4);
//                setLocation(locationInfo);
//            }
//
//        }, throwable -> {
//            Log.e(TAG, "on location error", throwable);
//        });
//        compositeDisposable.add(locationDisposable);
//        //状态变化 TODO 状态刷新策略
//        Disposable stateDisposable = Services.as(ILocationService2.class)
//                .observeState(RefreshStrategy.Companion.getDefaultStrategy(),null)
//                .observeOn(AndroidSchedulers.mainThread())
//                .subscribe(state -> {
//                    //TODO 状态变化
//                    Xlog.INSTANCE.i(TAG, "location state changed " + state.getName());
//                    if (state == State.REQUEST_LOCATION) {
//                    } else if (state == State.GOT_LOCATION) {
//                    } else if (state == State.LOCATION_FAILED) {
//                        TodayApplication.getApplicationModel().setLocation_type(3);
//                        TodayApplication.getApplicationModel().location_message = "location_failed";
//                    } else if (state == State.REQUEST_PLACE) {
//                    } else if (state == State.GOT_PLACE) {
//                    } else if (state == State.GET_PLACE_FAILED) {
//                    }
//                }, throwable -> {
//                });
//        compositeDisposable.add(stateDisposable);
//        Disposable suggestionDisposable = Services.as(ILocationService2.class)
//                .getSuggestion()
//                .observeOn(AndroidSchedulers.mainThread())
//                .subscribe(suggestion -> {
//                    // 提升精度的建议
//                    Log.i(TAG, "location suggestion " + suggestion);
//                    switch (suggestion) {
//                        case OPEN_GPS_IMPROVE_ACCURACY: //TODO 让用户打开gps
//                            break;
//                        case OPEN_WIFI_IMPROVE_ACCURACY:// 让用户打开wifi
//                            ToastKit.showToast(getStringByResId(R.string.loc_weak_open_wifi));
//                            break;
//                        case CHECK_NETWORK:             // 让用户检查网络
//                            ToastKit.showToast(getStringByResId(R.string.baidu_loc_error_3));
//                            break;
//                        case REQUEST_PERMISSION:        //TODO 没有权限
//                            ToastKit.showToast(getStringByResId(R.string.i_location_error_remind));
//                            break;
//                        case OPEN_LOCATION_SERVICE:     // 让用户打开定位服务
//                            ToastKit.showToast(getStringByResId(R.string.i_location_error_remind));
//                            break;
//                    }
//                });
//        compositeDisposable.add(suggestionDisposable);
    }


    @Override
    protected void onCleared() {
        super.onCleared();
        Log.i(TAG,"onClear");
        compositeDisposable.dispose();
    }

    public boolean isForceRefreshLoc() {
        return forceRefreshLoc;
    }

    public void setForceRefreshLoc(boolean forceRefreshLoc) {
        this.forceRefreshLoc = forceRefreshLoc;
    }
}
