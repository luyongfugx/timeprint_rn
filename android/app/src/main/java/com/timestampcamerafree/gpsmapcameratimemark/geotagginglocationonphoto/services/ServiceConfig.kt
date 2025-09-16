package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.BaseLocationService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.GpLocationService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.officialLogo.GpOfficialLogoService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.officialLogo.IGpOfficialLogoService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time.GpNetWorkGpTimeService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time.IGpTimeService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version.GpVersionService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version.IGpVersionService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.GpAppleWeatherService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.IGpWeatherService

/**
 * 服务
 */
class ServiceConfig {
    companion object {
        private  var locationService: BaseLocationService? =null;
        private  var timeService: IGpTimeService? = null;
        private  var weatherService: IGpWeatherService? =null;
        public  var versionService: IGpVersionService? =null;
        private  var officialLogoService: IGpOfficialLogoService? =null;
        fun init() {
            locationService =  GpLocationService()
            timeService =  GpNetWorkGpTimeService()
            weatherService =  GpAppleWeatherService()
            versionService = GpVersionService();
            officialLogoService = GpOfficialLogoService()
        }

        fun getLocationService(): BaseLocationService {
            return locationService!!
        }

        fun getOfficialLogoService(): IGpOfficialLogoService {
            return officialLogoService!!
        }

        /**
         * 时间获取类
         *
         * @return
         */
        fun getGpTimeService(): IGpTimeService {
            return timeService!!
        }
        fun getGpWeatherService(): IGpWeatherService {
            return weatherService!!
        }
    }


}
