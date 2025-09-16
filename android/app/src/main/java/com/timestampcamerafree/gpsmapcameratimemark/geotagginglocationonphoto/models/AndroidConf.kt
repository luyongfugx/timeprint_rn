package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

//{"appVer":"2.4.5","force":true}

/**
 * android 阿波罗，当前版本，是否强制刷新
 *
 * @property appVer
 * @property force
 */
@GenerateNoArg
data class AndroidConf (
//    @IdRes val buttonViewId: Int,
//    @DrawableRes val imageDrawableResId: Int,
    @SerializedName("appVer") val appVer: String,
    @SerializedName("force") val force: Boolean
)