package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter;

public interface SupportMoreListener {
    int BOTTOM_LOADING = 1;
    int LOAD_ERROR = 2;
    int BOTTOM_END = 3;

    boolean canLoadMore();
    void loadMore();
}
