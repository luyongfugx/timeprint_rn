package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

@GenerateNoArg
data class PlaceRefresh(@SerializedName("distanceResume") var distanceResume: Int = 10,
                        @SerializedName("distanceNotMove") var distanceNotMove: Int = 10,
                        @SerializedName("intervalMove") var intervalMove: Int = 10)