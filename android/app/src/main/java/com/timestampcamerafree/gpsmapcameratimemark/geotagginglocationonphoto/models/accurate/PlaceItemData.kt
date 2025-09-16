package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate;

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

@GenerateNoArg
data class PlaceItemData(@SerializedName(value = "places", alternate = ["addressList"]) var places: ArrayList<PlaceItem>)