package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import android.net.Uri

sealed class MultiShareMediaItem {
    data class DateHeader(val date: String, var isAllSelected: Boolean = false) : MultiShareMediaItem()
    data class Photo(val uri: Uri, val date: String, var isSelected: Boolean = false) : MultiShareMediaItem()
}
