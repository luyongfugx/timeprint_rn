package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.officialLogo

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.OfficialLogoConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.IService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version.IGpVersionService.Callback

/**
 * 获取官方水印服务
 *
 */
interface IGpOfficialLogoService : IService {
    interface Callback {
        fun onCurrentOfficialLogo(logoConfig: OfficialLogoConfig)
        fun onError(e:Exception)
        fun onComplete()
    }
    fun start(context: Context?, callback: Callback?)
}