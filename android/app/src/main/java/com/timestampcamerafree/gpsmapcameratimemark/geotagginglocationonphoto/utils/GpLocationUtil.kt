package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate.GpCoordinateStyle
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.round
import kotlin.math.sin
import kotlin.math.sqrt

object GpLocationUtil {
    private val TAG: String = GpLocationUtil::class.java.simpleName

    private fun isOutOfChina(lat: Double, lng: Double): Boolean {
        if (lng < 72.004 || lng > 137.8347) {
            return true
        }
        if (lat < 0.8293 || lat > 55.8271) {
            return true
        }
        return false
    }

    var pi: Double = 3.1415926535897932384626
    var x_pi: Double = 3.14159265358979324 * 3000.0 / 180.0
    var a: Double = 6378245.0
    var ee: Double = 0.00669342162296594323

    fun transformLat(x: Double, y: Double): Double {
        var ret = (-100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x)))
        ret =ret +  (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret =ret +  (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret =ret +  (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    fun transformLon(x: Double, y: Double): Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + (0.1
                * sqrt(abs(x)))
        ret =ret + (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret =ret +  (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret =ret +  (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(
            x / 30.0
                    * pi
        )) * 2.0 / 3.0
        return ret
    }

    fun transform(lat: Double, lon: Double): DoubleArray {
        if (outOfChina(lat, lon)) {
            return doubleArrayOf(lat, lon)
        }
        var dLat = transformLat(lon - 105.0, lat - 35.0)
        var dLon = transformLon(lon - 105.0, lat - 35.0)
        val radLat = lat / 180.0 * pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        val sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)
        val mgLat = lat + dLat
        val mgLon = lon + dLon
        return doubleArrayOf(mgLat, mgLon)
    }

    fun outOfChina(lat: Double, lon: Double): Boolean {
        if (lon < 72.004 || lon > 137.8347) return true
        if (lat < 0.8293 || lat > 55.8271) return true
        return false
    }

    /**
     * 84 to 火星坐标系 (GCJ-02) World Geodetic System ==> Mars Geodetic System
     *
     * @param lat
     * @param lon
     * @return
     */
    fun gps84_To_Gcj02(lat: Double, lon: Double): DoubleArray {
        return doubleArrayOf(lat, lon)
        //        if (outOfChina(lat, lon)) {
//            return new double[]{lat,lon};
//        }
//        double dLat = transformLat(lon - 105.0, lat - 35.0);
//        double dLon = transformLon(lon - 105.0, lat - 35.0);
//        double radLat = lat / 180.0 * pi;
//        double magic = Math.sin(radLat);
//        magic = 1 - ee * magic * magic;
//        double sqrtMagic = Math.sqrt(magic);
//        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
//        dLon = (dLon * 180.0) / (a / sqrtMagic * Math.cos(radLat) * pi);
//        double mgLat = lat + dLat;
//        double mgLon = lon + dLon;
//        return new double[]{mgLat, mgLon};
    }

    /**
     * * 火星坐标系 (GCJ-02) to 84 * * @param lon * @param lat * @return
     */
    fun gcj02_To_Gps84(lat: Double, lon: Double): DoubleArray {
        val gps = transform(lat, lon)
        val lontitude = lon * 2 - gps[1]
        val latitude = lat * 2 - gps[0]
        return doubleArrayOf(latitude, lontitude)
    }

    /**
     * 火星坐标系 (GCJ-02) 与百度坐标系 (BD-09) 的转换算法 将 GCJ-02 坐标转换成 BD-09 坐标
     *
     * @param lat
     * @param lon
     */
    fun gcj02_To_Bd09(lat: Double, lon: Double): DoubleArray {
        val x = lon
        val y = lat
        val z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi)
        val theta = atan2(y, x) + 0.000003 * cos(x * x_pi)
        val tempLon = z * cos(theta) + 0.0065
        val tempLat = z * sin(theta) + 0.006
        val gps = doubleArrayOf(tempLat, tempLon)
        return gps
    }

    /**
     * * 火星坐标系 (GCJ-02) 与百度坐标系 (BD-09) 的转换算法 * * 将 BD-09 坐标转换成GCJ-02 坐标 * * @param
     * bd_lat * @param bd_lon * @return
     */
    fun bd09_To_Gcj02(lat: Double, lon: Double): DoubleArray {
        val x = lon - 0.0065
        val y = lat - 0.006
        val z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi)
        val theta = atan2(y, x) - 0.000003 * cos(x * x_pi)
        val tempLon = z * cos(theta)
        val tempLat = z * sin(theta)
        val gps = doubleArrayOf(tempLat, tempLon)
        return gps
    }

    /**将gps84转为bd09
     * @param lat
     * @param lon
     * @return
     */
    fun gps84_To_bd09(lat: Double, lon: Double): DoubleArray {
        val gcj02 = gps84_To_Gcj02(lat, lon)
        val bd09 = gcj02_To_Bd09(gcj02[0], gcj02[1])
        return bd09
    }

    fun bd09_To_gps84(lat: Double, lon: Double): DoubleArray {
        val gcj02 = bd09_To_Gcj02(lat, lon)
        val gps84 = gcj02_To_Gps84(gcj02[0], gcj02[1])
        //保留小数点后六位
        gps84[0] = retain6(gps84[0])
        gps84[1] = retain6(gps84[1])
        return gps84
    }

    /**保留小数点后六位
     * @param num
     * @return
     */
    private fun retain6(num: Double): Double {
        val result = String.format("%.6f", num)
        return result.toDouble()
    }

    //    假设当前经纬度为（a,b)，误差设为300m，误差范围（a±x，b±y）
    //    y= 300/(111*10^3) = 2.7*10^-3
    //    x= 300/(111*10^3*cosb) = (2.7*10^-3)/cosb
    fun getLatLng(lat: Double, lng: Double): DoubleArray {
        val factor = 111 * 10 xor 3
        val x = 200 / (factor * cos(lng))
        val y = (200 / (factor)).toDouble()
        return doubleArrayOf(x, y)
    }

    /**
     * 根据用户的起点和终点经纬度计算两点间距离，此距离为相对较短的距离，单位米。
     * @param latLngStart 起点的坐标
     * @param latLngEnd   终点的坐标
     * @return
     */
    fun calculateLineDistance(latLngStart: DoubleArray?, latLngEnd: DoubleArray?): Double {
        require(!((latLngStart == null) || (latLngEnd == null))) { "非法坐标值，不能为null" }
        val d1 = 0.01745329251994329
        var d2 = latLngStart[1]
        var d3 = latLngStart[0]
        var d4 = latLngEnd[1] //end.longitude;
        var d5 = latLngEnd[0] //end.latitude;
        d2 *= d1
        d3 *= d1
        d4 *= d1
        d5 *= d1
        val d6 = sin(d2)
        val d7 = sin(d3)
        val d8 = cos(d2)
        val d9 = cos(d3)
        val d10 = sin(d4)
        val d11 = sin(d5)
        val d12 = cos(d4)
        val d13 = cos(d5)
        val arrayOfDouble1 = DoubleArray(3)
        val arrayOfDouble2 = DoubleArray(3)
        arrayOfDouble1[0] = (d9 * d8)
        arrayOfDouble1[1] = (d9 * d6)
        arrayOfDouble1[2] = d7
        arrayOfDouble2[0] = (d13 * d12)
        arrayOfDouble2[1] = (d13 * d10)
        arrayOfDouble2[2] = d11
        val d14 =
            sqrt((arrayOfDouble1[0] - arrayOfDouble2[0]) * (arrayOfDouble1[0] - arrayOfDouble2[0]) + (arrayOfDouble1[1] - arrayOfDouble2[1]) * (arrayOfDouble1[1] - arrayOfDouble2[1]) + (arrayOfDouble1[2] - arrayOfDouble2[2]) * (arrayOfDouble1[2] - arrayOfDouble2[2]))

        return (asin(d14 / 2.0) * 12742001.579854401)
    }

    //获取经纬度 度角分
//    fun getLatLngWithDetailDegree(latLng: Array<String>?): String {
//        if (latLng == null || latLng.size < 2) {
//            return AppConstants.BLANK_STRING
//        }
//        val d1: Double
//        val d2: Double
//        try {
//            d1 = latLng[0].toDouble()
//            d2 = latLng[1].toDouble()
//        } catch (e: NumberFormatException) {
//            return AppConstants.BLANK_STRING
//        }
//
//        val earthLatLng = doubleArrayOf(d1, d2)
//
//        var lat = convertLatLng(earthLatLng[0], 2)
//        lat =
//            lat + if (d1 > 0) App.context.getString(R.string.direction_north_no) else App.context.getString(
//                R.string.direction_south_no
//            )
//        var lng = convertLatLng(earthLatLng[1], 2)
//        lng =
//            lng + if (d2 > 0) App.context.getString(R.string.direction_east_no) else App.context.getString(
//                R.string.direction_west_no
//            )
//
//        if (d1 == 0.0 || d1 == Double.MIN_VALUE) {
//            lat = "--°"
//        }
//        if (d2 == 0.0 || d2 == Double.MIN_VALUE) {
//            lng = "--°"
//        }
//
//        return "$lat, $lng"
//    }

    //获取经纬度 度角分
//    fun getLatLngWithChineseDetailDegree(latLng: Array<String>?): String {
//        if (latLng == null || latLng.size < 2) {
//            return AppConstants.BLANK_STRING
//        }
//        var latTemp = 0.0
//        var lngTemp = 0.0
//        try {
//            latTemp = latLng[0].toDouble()
//            lngTemp = latLng[1].toDouble()
//        } catch (e: NumberFormatException) {
//        }
//        val earthLatLng = doubleArrayOf(latTemp, lngTemp)
//        var latChinese = if (latTemp > 0) "北纬" else "南纬"
//        var lngChinese = if (lngTemp > 0) "东经" else "西经"
//        var lat = convertLatLng(earthLatLng[0], 1)
//        var lng = convertLatLng(earthLatLng[1], 1)
//
//        //不确定是不是要改这个经纬度，先注释
//        if (latTemp == 0.0 || latTemp == Double.MIN_VALUE) {
//            latChinese = ""
//            lat = "--°"
//        }
//        if (lngTemp == 0.0 || lngTemp == Double.MIN_VALUE) {
//            lngChinese = ""
//            lng = "--°"
//        }
//
//        return "$latChinese$lat,$lngChinese$lng"
//    }

    private fun convertLatLng(latLng: Double, index: Int): String {
        val latA1 = latLng.toInt()
        val latB2 = ((latLng - latA1) * 60).toInt()
        val latC3 = round(((latLng - latA1 - latB2 / 60) * 3600)) as Int
        val latA = abs(latA1.toDouble()).toInt()
        val latB = abs(latB2.toDouble()).toInt()
        val latC = abs(latC3.toDouble()).toInt()
        if (index == 0) {
            return "$latA°"
        } else if (index == 1) {
            return latA.toString() + "°" + (latB.toString() + "\'")
        }
        return latA.toString() + "°" + (latB.toString() + "\'") + latC.toString() + "\'\'"
    }


    fun formatLatLng(latitude: Double, longitude: Double): MutableMap<Int, String> {
        val formats = mutableMapOf<Int, String>()

        // 格式1：简易度数格式 (两位小数)
        formats[GpCoordinateStyle.DegreeSimple.style] = "%.2f°%s,%.2f°%s".format(
            abs(latitude), if (latitude >= 0) "N" else "S",
            abs(longitude), if (longitude >= 0) "E" else "W"
        )

        // 格式2：精确度数格式 (六位小数)

        formats[ GpCoordinateStyle.DegreePrecise.style] = "%.6f°%s,%.6f°%s".format(
            abs(latitude), if (latitude >= 0) "N" else "S",
            abs(longitude), if (longitude >= 0) "E" else "W"
        )

        // 格式3：度分秒格式
        formats[ GpCoordinateStyle.Dms.style] = formatDMS(latitude, longitude)

        // 格式4：度小数分格式
        formats[ GpCoordinateStyle.DegreeDecimalMinute.style] = formatDM(latitude, longitude, 2)

        // 格式5：纯小数格式
        formats[GpCoordinateStyle.Decimal.style] = "%.6f,%.6f".format(latitude, longitude)

        return formats
    }

    fun formatDMS(latitude: Double, longitude: Double): String {
        val latDir = if (latitude >= 0) "N" else "S"
        val lonDir = if (longitude >= 0) "E" else "W"

        val latDegrees = floor(abs(latitude)).toInt()
        val latMinutes = floor((abs(latitude) - latDegrees) * 60).toInt()
        val latSeconds = (((abs(latitude) - latDegrees) * 60) - latMinutes) * 60

        val lonDegrees = floor(abs(longitude)).toInt()
        val lonMinutes = floor((abs(longitude) - lonDegrees) * 60).toInt()
        val lonSeconds = (((abs(longitude) - lonDegrees) * 60) - lonMinutes) * 60

        return "$latDegrees°$latMinutes'%.0f\"$latDir,$lonDegrees°$lonMinutes'%.0f\"$lonDir".format(latSeconds, lonSeconds)
    }

    fun formatDM(latitude: Double, longitude: Double, decimalPlaces: Int): String {
        val latDir = if (latitude >= 0) "N" else "S"
        val lonDir = if (longitude >= 0) "E" else "W"

        val latDegrees = floor(abs(latitude)).toInt()
        val latMinutes = (abs(latitude) - latDegrees) * 60

        val lonDegrees = floor(abs(longitude)).toInt()
        val lonMinutes = (abs(longitude) - lonDegrees) * 60

        return "${latDir}${latDegrees}°%.${decimalPlaces}f',${lonDir}${lonDegrees}°%.${decimalPlaces}f'".format(latMinutes, lonMinutes)
    }

    var df: DecimalFormat = DecimalFormat("0.000000", DecimalFormatSymbols(Locale.US))
//    fun convertLatLngToWgsWithUnit(latLng: Array<String>?, withUnit: Boolean): Array<String?>? {
//        if (latLng == null || latLng.size < 2) {
//            return null
//        }
//        val earthLatLng = doubleArrayOf(latLng[0].toDouble(), latLng[1].toDouble())
//        //        if (isLocationCordGcj(Double.parseDouble(latLng[0]), Double.parseDouble(latLng[1]))) {
////            //国内 火星坐标
////            earthLatLng = gcj02_To_Gps84(Double.parseDouble(latLng[0]), Double.parseDouble(latLng[1]));
////
////        } else {
////            //国外 84坐标
////        }
//        latLng[0] = earthLatLng[0].toString()
//        latLng[1] = earthLatLng[1].toString()
//
//        val latLngTemp = arrayOfNulls<String>(2)
//        try {
//            val lat = latLng[0].toDouble()
//            val lng = latLng[1].toDouble()
//            var unit: String? = null
//            if (withUnit) {
//                unit =
//                    if (lat > 0) App.context.getString(R.string.direction_north) else App.context.getString(
//                        R.string.direction_south
//                    )
//                latLngTemp[0] = df.format(abs(lat)).toString() + unit
//                unit =
//                    if (lng > 0) App.context.getString(R.string.direction_east) else App.context.getString(
//                        R.string.direction_west
//                    )
//                latLngTemp[1] = df.format(abs(lng)).toString() + unit
//                if (lat == 0.0 || lat == Double.MIN_VALUE) {
//                    latLngTemp[0] = "--°"
//                }
//                if (lng == 0.0 || lng == Double.MIN_VALUE) {
//                    latLngTemp[1] = "--°"
//                }
//                //                if (latLngTemp[0].equals(".000000°N") && latLngTemp[1].equals(".000000°E")) {
////                    latLngTemp[0] = "--°";
////                    latLngTemp[1] = "--°";
////                }
//            } else {
//                latLngTemp[0] = df.format(lat).toString()
//                latLngTemp[1] = df.format(lng).toString()
//
//                if (lat == 0.0 || lat == Double.MIN_VALUE) {
//                    latLngTemp[0] = "--°"
//                }
//                if (lng == 0.0 || lng == Double.MIN_VALUE) {
//                    latLngTemp[1] = "--°"
//                }
//            }
//        } catch (e: Exception) {
//            Log.e(TAG, e.message!!)
//            latLngTemp[0] = "--°"
//            latLngTemp[1] = "--°"
//        }
//        return latLngTemp
//    }

//    val doubleLatLng: DoubleArray
//        get() {
//            val latLng = convertLatLngToWgsWithUnit(
//                ExifBuilderFactory.INSTANCE.getExifBuilder().getNailaleInfo().getLatAndLng(), false
//            )
//            var lat = 0.00
//            var lng = 0.00
//            val doubleLatLng = doubleArrayOf(lat, lng)
//            if (latLng != null && latLng.size > 1) {
//                try {
//                    lat = latLng[0]!!.toDouble()
//                    lng = latLng[1]!!.toDouble()
//                    doubleLatLng[0] = lat
//                    doubleLatLng[1] = lng
//                } catch (e: Exception) {
//                }
//            }
//            return doubleLatLng
//        }

//
//    val currentLatLng: DoubleArray
//        get() {
//            val latLng: Array<String> = Prefs.getLocationLatLng()
//            var lat = 0.0
//            var lng = 0.0
//
//            if (latLng != null && latLng.size > 1) {
//                try {
//                    lat = latLng[0].toDouble()
//                    lng = latLng[1].toDouble()
//                } catch (e: Exception) {
//                    Log.d(TAG, "", e)
//                }
//            }
//
//            return doubleArrayOf(lat, lng)
//        }
}
