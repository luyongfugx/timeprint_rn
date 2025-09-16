package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPLanguageManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateCommpent
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPID9DateStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.WatermarkTimeItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.lang.GpLanguageType


import java.text.SimpleDateFormat
import java.util.*
import java.util.Calendar.*

object GpDateFormat {
    private const val TAG = "GpDateFormat"
    private const val YEAR = 0
    private const val MONTH = 1
    private const val DAY = 2
    private const val HOUR = 3
    private const val MINUTE = 4
    private const val SECOND = 5
    private const val MILLISECOND = 6

    private val calendar = getInstance(Locale.getDefault())
    private val tmpCalendar = getInstance(Locale.getDefault())
    private var beijingTimeZone: TimeZone = TimeZone.getTimeZone("GMT+08")
    private var bangkokTimeZone = TimeZone.getTimeZone("Asia/Bangkok")
    private var thLocale =Locale.forLanguageTag("th")

    var isChina = false
    var is12HourFormat = false
    // HH:MM
    fun toHHMM(timestamp: Long, timeZoneId: String): String {
        val timeSlice =getTimeSlice(timestamp, timeZoneId)
        return "${padTwoZeroToStart(timeSlice[HOUR])}:${padTwoZeroToStart(timeSlice[MINUTE])}"
    }
    fun setTimeZone(zoneId: String) {
        if (!isChina) {
            if (calendar.timeZone.id != zoneId) {
                calendar.timeZone = TimeZone.getTimeZone(zoneId)
            }
        }
    }
    private fun setTimezone() {

//        if (isChina) {
//            calendar.timeZone = beijingTimeZone
//        }
    }

    /**
     * 获取ampm 时区 星期 三个字符串组成的字符
     *
     * @param millis
     * @param timeItem
     * @return
     */
    fun toAmPmTimeZoneWeek(millis: Long, timeItem: WatermarkTimeItem): String{
        var result = "";
        var week = toFullWeekText(millis)
        var timeZone = GpTimeManager.getGlobalTimeZoneAbbreviation()
        var date = Date(millis)
        val isTh = deviceLocalIsTh()
        val com = dateCommpent(date, is12Hours = timeItem.is12Hour, isUseBuddhist = isTh, dateStyle = timeItem.style)
        if (!timeItem.is12Hour){
            result = "${result}${com.ampm} "
        }
        if (timeItem.showTimeZone){
            result = "${result}$timeZone "
        }
        if (timeItem.showWeek){
            result = "${result}$week "
        }

        return result
    }
    fun toFullWeekText(millis: Long): String {
        val calendar = getInstance()
        calendar.timeInMillis = millis
        val dayOfWeek = calendar.get(DAY_OF_WEEK)
        return when (dayOfWeek) {
            SUNDAY -> GpUiUtils.getString(R.string.k_date_sun)
            MONDAY -> GpUiUtils.getString(R.string.k_date_mon)
            TUESDAY -> GpUiUtils.getString(R.string.k_date_tues)
            WEDNESDAY -> GpUiUtils.getString(R.string.k_date_wed)
            THURSDAY -> GpUiUtils.getString(R.string.k_date_thur)
            FRIDAY -> GpUiUtils.getString(R.string.k_date_fri)
            SATURDAY -> GpUiUtils.getString(R.string.k_date_sat)
//            SATURDAY -> GpUiUtils.getLocalizedText("k_date_sat")
//            SUNDAY -> GpUiUtils.getLocalizedText("k_date_sun")
//            MONDAY -> GpUiUtils.getLocalizedText("k_date_mon")
//            TUESDAY -> GpUiUtils.getLocalizedText("k_date_tues")
//            WEDNESDAY -> GpUiUtils.getLocalizedText("k_date_wed")
//            THURSDAY -> GpUiUtils.getLocalizedText("k_date_thur")
//            FRIDAY -> GpUiUtils.getLocalizedText("k_date_fri")
//            SATURDAY -> GpUiUtils.getLocalizedText("k_date_sat")
            else -> ""
        }
    }
    //格式 HH:mm
    fun toHHmm(timestamp: Long,is12Hours: Boolean = false, isShowWeek:  Boolean = false, isShowTimezone:   Boolean = false, style: GPDateStyle): String {

        val com = dateCommpent(Date(timestamp), is12Hours, false, style)
        return "${com.hh?.let { padTwoZeroToStart(it) }}:${com.mm?.let { padTwoZeroToStart(it) }}"
    }
    // HH:MM

//    fun toDMY(timestamp: Long,is12Hours: Boolean = false, isShowWeek:  Boolean = false, isShowTimezone:   Boolean = false, style: GPDateStyle): String {
//        val com = dateCommpent(Date(timestamp), is12Hours, false, style)
//        val year = com.year
//        val month = com.month
//        val day = com.day
//        if (style == GPDateStyle.dayMonthYear) {
//            // "dd/MM/yyyy HH:mm" or  "dd/MM/yyyy HH:mm:ss"
//            val result = "$day/$month/$year"
//        } else {
//            // MM/dd/yyyy HH:mm  or MM/dd/yyyy HH:mm:ss
//            val result = "$month/$day/$year"
//
//        }
//
////
//// return "${com.hh}:${com.mm}"
//    }
    fun toYYYYMMDDDotHHmm24Hour(timestamp: Long): String {
        val timeSlice = getTimeSlice(timestamp, false)

        return "${timeSlice[YEAR]}.${padTwoZeroToStart(timeSlice[MONTH])}.${padTwoZeroToStart(timeSlice[DAY])}" +
                " ${padTwoZeroToStart(timeSlice[HOUR])}:${padTwoZeroToStart(timeSlice[MINUTE])}"
    }
    public fun getNowTimeSlice():IntArray{
       return  getTimeSlice(System.currentTimeMillis())
    }
    private   fun getTimeSlice(timestamp: Long): IntArray {
        setTimezone()
        calendar.timeInMillis = timestamp
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day= calendar.get(DAY_OF_MONTH)
        var tempHour = calendar.get(Calendar.HOUR)
        if (tempHour == 0) tempHour =tempHour+ 12
        val hour = if (is12HourFormat) tempHour else calendar.get(HOUR_OF_DAY)
        val minute = calendar.get(Calendar.MINUTE)
        val second = calendar.get(Calendar.SECOND)
        val millisecond = calendar.get(Calendar.MILLISECOND)
        return intArrayOf(year, month, day, hour, minute, second, millisecond)
    }

    private fun getTimeSlice(timestamp: Long, is12Hour: Boolean): IntArray {
        setTimezone()
        calendar.timeInMillis = timestamp
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day= calendar.get(DAY_OF_MONTH)
        val hour = calendar.get(if (is12Hour) Calendar.HOUR else HOUR_OF_DAY)
        val minute = calendar.get(Calendar.MINUTE)
        val second = calendar.get(Calendar.SECOND)
        val millisecond = calendar.get(Calendar.MILLISECOND)

        return intArrayOf(year, month, day, hour, minute, second, millisecond)
    }

    private fun getTimeSlice(timestamp: Long, timeZoneId: String): IntArray {
        try {
            tmpCalendar.timeZone = TimeZone.getTimeZone(timeZoneId)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        tmpCalendar.timeInMillis = timestamp
        val year = tmpCalendar.get(Calendar.YEAR)
        val month = tmpCalendar.get(Calendar.MONTH) + 1
        val day= tmpCalendar.get(DAY_OF_MONTH)
        val hour = tmpCalendar.get(if (is12HourFormat) Calendar.HOUR else HOUR_OF_DAY)
        val minute = tmpCalendar.get(Calendar.MINUTE)
        val second = tmpCalendar.get(Calendar.SECOND)
        val millisecond = tmpCalendar.get(Calendar.MILLISECOND)

        return intArrayOf(year, month, day, hour, minute, second, millisecond)
    }

    private fun padTwoZeroToStart(intValue: String): String {
        if (intValue.length == 1) {
            return "0$intValue"
        }
        return intValue
    }
    private fun padTwoZeroToStart(intValue: Int): String {
        return if (intValue > 9) intValue.toString()
        else intValue.padStart(2, '0')
    }

    private fun padThreeZeroToStart(intValue: Int): String {
        return if (intValue > 99) intValue.toString() else intValue.padStart(3, '0')
    }

    fun Int.padStart(length: Int, pad: Char): String {
        return toString().padStart(length, pad)
    }
    /**
     * 是不是泰国
     *
     * @return
     */
    fun deviceLocalIsTh(): Boolean {
        val language = Locale.getDefault().language
        if (language.lowercase() == "th") {
            return true
         }
        else {
            return false
        }
    }

    /**
     * 获取语言
     *
     * @return
     */
    fun getDeviceLanguage(): String {
        return Locale.getDefault().language
    }

    /**
     * 获取国家
     *
     * @return
     */
    fun getDeviceCountry(): String {
        return Locale.getDefault().country
    }

    /**
     * 获取本地化的日期格式
     *
     * @param date
     * @param style
     * @param is12Hours
     * @param isShowWeek
     * @param isShowTimezone
     * @param baseID
     * @param needSecond
     * @param onlyYearMonthDay
     * @return
     */
    fun localizedDateString(date: Date, style: GPDateStyle, is12Hours: Boolean?, isShowWeek: Boolean?, isShowTimezone: Boolean?,  needSecond: Boolean = false, onlyYearMonthDay: Boolean = false): String {
        val isTh = deviceLocalIsTh()
        return when (style) {
            GPDateStyle.yearMonthDateSpecialCountry -> localDateString(date, isShowWeek = isShowWeek ?: false, is12Hours = is12Hours, isShowTimeZone = isShowTimezone, isUseBuddhist = isTh, dateStyle = style, needSecond = needSecond, onlyYearMonthDay = onlyYearMonthDay)
            GPDateStyle.dayMonthYear, GPDateStyle.monthDayYear -> {

                val com = dateCommpent(date, is12Hours = is12Hours, isUseBuddhist = isTh, dateStyle = style)

                val year = com.year
                val month = com.month
                val day = com.day
                val week = com.week
                val hh = com.hh
                val mm = com.mm
                val ss = com.ss
                val ampm = com.ampm
                val timezone = GpTimeManager.getGlobalTimeZoneAbbreviation();
                val hhmm = "$hh:$mm${if (is12Hours == true) " $ampm" else ""}${if (isShowTimezone == true) " $timezone" else ""}"
                val hhmmss = "$hh:$mm:$ss${if (is12Hours == true) " $ampm" else ""}${if (isShowTimezone == true) " $timezone" else ""}"
                val weekString = if (isShowWeek == true) "$week, " else ""
                if (style == GPDateStyle.dayMonthYear) {
                    // "dd/MM/yyyy HH:mm" or  "dd/MM/yyyy HH:mm:ss"
                    val result = "$weekString$day/$month/$year"
                    if (onlyYearMonthDay) {
                        return result
                    }
                    "$result ${if (needSecond) hhmmss else hhmm}"
                } else {
                    // MM/dd/yyyy HH:mm  or MM/dd/yyyy HH:mm:ss
                    val result = "$weekString$month/$day/$year"
                    if (onlyYearMonthDay) {
                        return result
                    }
                    "$result ${if (needSecond) hhmmss else hhmm}"
                }
            }
        }
    }


    private  fun localDateString(date: Date, isShowWeek: Boolean, is12Hours: Boolean?, isShowTimeZone: Boolean?, isUseBuddhist: Boolean, dateStyle: GPDateStyle,needSecond:Boolean = false,onlyYearMonthDay:Boolean = false) : String {

        val com = dateCommpent(date,  is12Hours,  isUseBuddhist, dateStyle)

        var year = com.year
        var month = com.month
        var shortMonth = com.shortMonth
        var day = com.day
        var week = com.week
        var hh = com.hh
        var mm = com.mm
        var ss = com.ss
        var ampm = com.ampm
        var timezone: String =  GpTimeManager.getGlobalTimeZoneAbbreviation().toString()

        var hhmm = "$hh:$mm ${if(is12Hours == true) { " $ampm"} else ""} ${if(isShowTimeZone == true ) { " $timezone"} else ""}";
        var hhmmss  = "$hh:$mm:$ss ${if(is12Hours == true) { " $ampm"} else ""} ${if(isShowTimeZone == true ) { " $timezone"} else ""}";


//        var localYear = GpUiUtils.getLocalizedText("i_date_year")
//        var localMonth = GpUiUtils.getLocalizedText("i_date_month")
//        var localDay = GpUiUtils.getLocalizedText("i_date_day")

        var localYear = GpUiUtils.getString(R.string.i_date_year)
        var localMonth = GpUiUtils.getString(R.string.i_date_month)
        var localDay = GpUiUtils.getString(R.string.i_date_day)
        if (localYear == "i_date_year") {
            localYear = "年"
        }

        if (localMonth == "i_date_month") {
            localMonth = "月"
        }

        if (localDay == "i_date_day") {
            localDay = "日"
        }

        var languageType = GPLanguageManager.localLanguageType()

        when (languageType) {
            //中文
            GpLanguageType.simplifiedChinese, GpLanguageType.traditionalChinese, GpLanguageType.hanguoyu, GpLanguageType.riyu -> {
                var result = "${year}${localYear}${month}${localMonth}${day}${localDay}${
                    if (isShowWeek) {
                        ", ${week}"
                    } else {
                        ""
                    }
                }"
                //只显示年月日
                if (onlyYearMonthDay) {
                    return "${year}${localYear}${month}${localMonth}${day}${localDay}"
                }
                return "${result} ${if (needSecond) hhmmss else hhmm}"
            }
            //英文
            GpLanguageType.en_Ph,GpLanguageType.en_US,GpLanguageType.en_My, GpLanguageType.en_other -> {
                var result = "${if (isShowWeek) "${week}, " else ""}${shortMonth} ${day}, ${year}"
                //只显示年月日
                if (onlyYearMonthDay) {
                    return "${shortMonth} ${day}, ${year}"
                }
                return "${result} ${if (needSecond) hhmmss else hhmm}"
            }
          //  case .yinniyu, .xibanyayu, .yindiyu, .taiyu, .malaiyu, .putaoyayu, .eyu, .amuhalayu, .fayu, .tuerqiyu, .yidaliyu, .siwaxiliyu: do {

            GpLanguageType.yindiyu, GpLanguageType.xibanyayu, GpLanguageType.yindiyu, GpLanguageType.taiyu, GpLanguageType.malaiyu, GpLanguageType.putaoyayu,
            GpLanguageType.eyu, GpLanguageType.amuhalayu, GpLanguageType.fayu, GpLanguageType.tuerqiyu, GpLanguageType.yidaliyu, GpLanguageType.siwaxiliyu -> {
                var result = "${if (isShowWeek) "${week}, " else ""}${shortMonth} ${day}, ${year}"
                //只显示年月日
                if (onlyYearMonthDay) {
                    return "$shortMonth ${day}, ${year}"
                }
                return "${result} ${if (needSecond) hhmmss else hhmm}"
            }

            GpLanguageType.yuenanyu -> {
                var weekDescr = if (isShowWeek) "${week}, " else ""
                var result = "${weekDescr}${day} ${shortMonth}, ${year}"
                //只显示年月日
                if (onlyYearMonthDay) {
                    return "$day ${shortMonth}, ${year}"
                }
                return "$result ${if (needSecond) hhmmss else hhmm}"
            }
            //不处理
            GpLanguageType.mengjialayu -> {
            }
            GpLanguageType.deyu -> {
                var result = "${if (isShowWeek) "${week}. " else ""}${day} .${shortMonth}. ${year}"
                if (onlyYearMonthDay) {
                    return "$day ${shortMonth}, ${year}"
                }
                return "$result ${if (needSecond) hhmmss else hhmm}"
            }
            else -> {
                var result = "${if(isShowWeek) "${week}, " else ""}${shortMonth} ${day}, ${year}"
                if (onlyYearMonthDay) {
                    return "$shortMonth ${day}, ${year}"
                }
                return "$result ${if (needSecond) hhmmss else hhmm}"
            }
        }
        var result = "${if(isShowWeek) "${week}, " else ""} $day $shortMonth $year"
        if(onlyYearMonthDay){
            return "$day  ${shortMonth} ${year}"
        }
        return "${result} ${if(needSecond) hhmmss else hhmm}"
    }

    fun getDateFormatString(date: Date, style: GPDateStyle, needWeek: Boolean, needShowAll: Boolean = false) : String {
        Log.d(TAG,"getDateFormatString ,date ${date.toString()}")
        var dateStr = getFormatterDate(date, style.getDateFmt())
        Log.d(TAG,"getDateFormatString ,dateStr: ${dateStr}")
        if (needWeek) {
                var dateComponent = dateCommpent(date,  false, false, style)
                // 添加星期显示
                return when(style) {
                    GPDateStyle.yearMonthDateSpecialCountry -> {
                        "${dateComponent.week}, $dateStr"
                    }

                    GPDateStyle.dayMonthYear -> {
                        "$dateStr, ${dateComponent.week}"
                    }

                    GPDateStyle.monthDayYear -> {
                        "$dateStr, ${dateComponent.week}"
                    }
                }
        } else {
            return dateStr
        }
    }

    private fun dateFormat_gp(isLocalization: Boolean = true): SimpleDateFormat {
        var locale = if (isLocalization) Locale.getDefault()
        else Locale.US

        val dateFormatter = SimpleDateFormat("",locale)
        // 全球化适配

        //var timeZone = GpTimeManager.getGlobalTimeZone()
       // Log.d(TAG,"locale ${locale} GpTimeManager.getGlobalTimeZone: ${GpTimeManager.getGlobalTimeZone()}")
       //  timeZone = beijingTimeZone
        //dateFormatter.calendar = getInstance(timeZone) // Calendar.init(identifier: .iso8601)
        return dateFormatter
    }



    // isUseBuddhist: 是否使用泰国的佛历年格式化, 泰国佛历年为当前年份+543
    fun dateCommpent(date: Date, is12Hours: Boolean?, isUseBuddhist: Boolean = false, dateStyle: GPDateStyle): GPDateCommpent {
        //Log.d(TAG,"dateCommpent is12Hours:"+is12Hours )
        var fmt = "yyyy-MM-dd-EEEE-HH-mm-ss"
        var formatterString = ""
        var dateFmt = dateStyle.getDateFmt()
        var dateFormatterString = ""

        // 是否用佛历年, 仅全球版特有国家化日期样式支持
        if (isUseBuddhist){
            //dateFormatterString = getFormatterDate_th_buddhist(date, dateFmt)
            formatterString = getFormatterDate_th_buddhist(date, fmt)
        } else {
            //dateFormatterString = getFormatterDate(date,  dateFmt)
            formatterString = getFormatterDate(date, fmt)
        }

        var ymde = formatterString.split( "-")
        var len = ymde.size
        //葡萄牙语格式是这样，所以可能会有8个字符的时候，所以可能长度可能为7
       /// 2025-05-19-segunda-feira-21-21-55
        val year = ymde.getOrNull(0) ?: "-"
        val month = ymde.getOrNull(1) ?: "-"
        val shortMonth = shortMonthLocal(month)
        val day = ymde.getOrNull(2) ?: "-"

        var hh = ymde.getOrNull(4) ?: "-"
        var mm = ymde.getOrNull(5) ?: "-"
        //秒
        var ss = ymde.getOrNull(6) ?: "-"

        var week = ymde.getOrNull(3) ?: "-"
        //如果长度是8,葡萄牙语格式是这样
        if (len>7){
            hh = ymde.getOrNull(5) ?: "-"
            mm = ymde.getOrNull(6) ?: "-"
            //秒
            ss = ymde.getOrNull(6) ?: "-"
            week = "${ymde.getOrNull(3)}-${ymde.getOrNull(4)}" ?: "-"
        }

        var weekIndex: Int?

        // 是否用佛历年
        if (isUseBuddhist) {
            weekIndex = dateFormatCalendar_th_buddhist().get(DAY_OF_WEEK)

        } else {
            weekIndex = dateFormatCalendar().get(DAY_OF_WEEK)
        }
        weekLocal(weekIndex - 1)?.let {
            week = it
        }
        var ampm = "AM"

        if (is12Hours == true) {
            var hhInt = hh.toInt()
            if (hhInt >= 12) {
                if (hhInt >= 13) {

                    hhInt -= 12
                }
                hh = "$hhInt"
                ampm = "PM"
            }
        }
        return GPDateCommpent(year, month,  shortMonth, day, week, hh, mm,ss, ampm, dateFormatterString)
    }

    fun getWeekday(date: Date): Int {
        val calendar = getInstance()
        calendar.time = date
        return calendar.get(DAY_OF_WEEK)
    }
    /**
     * 泰国佛历年格式化，获取日期字符串
     *
     * @param date
     * @param dateFormat
     */
    fun getFormatterDate_th_buddhist(date: Date,format:String): String {
        return toString_th_buddhist(date,format)
    }
    fun toString_th_buddhist(date: Date,format: String = "yyyy-MM-dd HH:mm:ss", islocalization: Boolean = true) : String {
        var dateFormater = dateFormat_th_buddhist()
       dateFormater.applyPattern(format)
        var resultStr = dateFormater.format(date)
        return resultStr
    }
    fun getFormatterDate(date: Date, dateFormat: String): String {
        return toString_gp(date,dateFormat)
    }

    fun toString_gp(date: Date, format: String = "yyyy-MM-dd HH:mm:ss", islocalization: Boolean = true) :String {
        var dateFormater = dateFormat_gp(islocalization)
        dateFormater.applyPattern(format)
        var resultStr = dateFormater.format(date)
        return resultStr
    }

    /**
     * 获取泰国格式
     *
     * @return
     */
    private  fun dateFormat_th_buddhist(): SimpleDateFormat {
        val dateFormatter = dateFormat_gp()
        dateFormatter.calendar = getInstance(bangkokTimeZone, thLocale) // 使用泰国时区和语言环境
        return dateFormatter
    }




    private fun dateFormatCalendar(islocalization: Boolean = true) : Calendar {
       return  dateFormat_gp(islocalization).calendar
    }

     fun dateFormatCalendar_th_buddhist() : Calendar {
       return dateFormat_th_buddhist().calendar
    }


    /**
     * 获取月份短字符
     *
     * @param month
     * @return
     */
    private fun shortMonthLocal(month: String): String {
//        val local = arrayOf(
//            "k_date_jan",
//            "k_date_feb",
//            "k_date_mar",
//            "k_date_apr",
//            "k_date_may",
//            "k_date_jun",
//            "k_date_jul",
//            "k_date_aug",
//            "k_date_sep",
//            "k_date_oct",
//            "k_date_nov",
//            "k_date_dec"
//        )
        val local = arrayOf(
            R.string.k_date_jan,
            R.string.k_date_feb,
            R.string.k_date_mar,
            R.string.k_date_apr,
            R.string.k_date_may,
            R.string.k_date_jun,
            R.string.k_date_jul,
            R.string.k_date_aug,
            R.string.k_date_sep,
            R.string.k_date_oct,
            R.string.k_date_nov,
            R.string.k_date_dec
        )
        if (month.toIntOrNull()?.let { local.getOrNull(it - 1) } != null) {
            return GpUiUtils.getString(local[month.toInt() - 1])
          //  return GpUiUtils.getLocalizedText(local[month.toInt() - 1])
        }
        return month
    }

    /**
     * 本地化星期(日历的hearder,只需要一个字)
     * @param weekdDay
     * @return
     */
    fun calendarWeekLocal(weekdDay: Int): String? {
        if (weekdDay < 0 || weekdDay > 6) {
            return null
        }
        val local = arrayOf(
            R.string.k_calendar_sun,
                    R.string.k_calendar_mon,
                    R.string.k_calendar_tues,
                    R.string.k_calendar_wed,
                    R.string.k_calendar_thur,
                    R.string.k_calendar_fri,
                    R.string.k_calendar_sat
        )
        val defaultLocal = arrayOf(
            "S",
            "M",
            "T",
            "W",
            "T",
            "F",
            "S"
        )
//        val local = arrayOf(
//            "k_calendar_sun",
//            "k_calendar_mon",
//            "k_calendar_tues",
//            "k_calendar_wed",
//            "k_calendar_thur",
//            "k_calendar_fri",
//            "k_calendar_sat"
//        )
//        val defaultLocal = arrayOf(
//            "S",
//            "M",
//            "T",
//            "W",
//            "T",
//            "F",
//            "S"
//        )
        val localKey = local[weekdDay]
        val localString = GpUiUtils.getString(localKey)
        if (localString.isNullOrEmpty()) {
            return defaultLocal[weekdDay]
        }
        return localString
    }


    /**
     * 本地化星期
     *
     * @param weekdDay
     * @return
     */
    fun weekLocal(weekdDay: Int): String? {
        if (weekdDay < 0) {
            return null
        }
        val local = arrayOf(
            R.string.k_date_sun,
            R.string.k_date_mon,
                    R.string.k_date_tues,
                    R.string.k_date_wed,
                    R.string.k_date_thur,
                    R.string.k_date_fri,
                    R.string.k_date_sat
        )
        // Check if the weekdDay is within the bounds of the local array
        if (weekdDay >= local.size) {
            return null
        }
        val localKey = local[weekdDay]
        // Assuming localized() is an extension function or utility function to get the localized string
        //获取本地化字符串的值
        val localString = GpUiUtils.getString(localKey)
        // If the localized string is the same as the key, return null
        return if (localString.isNullOrEmpty()) {
            null
        } else {
            localString
        }
    }

    /**
     * 获取日期和时间数组
     *
     * @param date
     * @param style
     * @param is12Hours
     * @return
     */
    fun getID9DateTimeString(date: Date, style: GPDateStyle, is12Hours: Boolean?): Pair<List<Int>, List<Int>> {
        val com = dateCommpent(date, is12Hours, false, style)
        val year = com.year
        val month = com.month
        val day = com.day
        var hh = com.hh
        val mm = com.mm
        val ss = com.ss
        if (is12Hours == true) {
            if (hh?.length == 1) {
                hh = "0$hh"
            }
        }
        var id9Style: GPID9DateStyle = GPID9DateStyle.monthDayYear
        when (style) {
            GPDateStyle.yearMonthDateSpecialCountry -> {
                val languageType = GPLanguageManager.localLanguageType()
                when (languageType) {
                    GpLanguageType.simplifiedChinese,GpLanguageType.traditionalChinese, GpLanguageType.hanguoyu, GpLanguageType.riyu -> {
                        id9Style = GPID9DateStyle.yearMonthDate
                    }
                    GpLanguageType.en_My,GpLanguageType.en_US, GpLanguageType.en_Ph-> {
                        id9Style = GPID9DateStyle.yearMonthDate
                    }
                    GpLanguageType.en_other -> {
                        id9Style = GPID9DateStyle.dayMonthYear
                    }

                    GpLanguageType.yinniyu, GpLanguageType.xibanyayu, GpLanguageType.yindiyu, GpLanguageType.taiyu, GpLanguageType.malaiyu, GpLanguageType.putaoyayu, GpLanguageType.eyu, GpLanguageType.amuhalayu, GpLanguageType.fayu, GpLanguageType.tuerqiyu, GpLanguageType.yidaliyu, GpLanguageType.siwaxiliyu -> {
                        id9Style = GPID9DateStyle.dayMonthYear
                    }
                    GpLanguageType.yuenanyu -> {
                        id9Style = GPID9DateStyle.dayMonthYear
                    }
                    GpLanguageType.mengjialayu -> {
                    }
                    GpLanguageType.deyu -> {
                        id9Style = GPID9DateStyle.dayMonthYear
                    }
                    else -> {
                        id9Style = GPID9DateStyle.monthDayYear
                    }
                }
            }
            GPDateStyle.dayMonthYear -> {
                id9Style = GPID9DateStyle.dayMonthYear
            }
            GPDateStyle.monthDayYear -> {
                id9Style = GPID9DateStyle.monthDayYear
            }
        }
        val dateArr = mutableListOf<Int>()
        when (id9Style) {
            GPID9DateStyle.yearMonthDate -> {
                dateArr.addAll(getTimeIntArr(year))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(month))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(day))
            }
            GPID9DateStyle.dayMonthYear -> {
                dateArr.addAll(getTimeIntArr(day))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(month))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(year))
            }
            GPID9DateStyle.monthDayYear -> {
                dateArr.addAll(getTimeIntArr(month))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(day))
                dateArr.add(-1)
                dateArr.addAll(getTimeIntArr(year))
            }
        }
        val timeArr = mutableListOf<Int>()
        timeArr.addAll(getTimeIntArr(hh))
        timeArr.add(-1)
        timeArr.addAll(getTimeIntArr(mm))
        timeArr.add(-1)
        timeArr.addAll(getTimeIntArr(ss))
        return Pair(dateArr, timeArr)
    }
    
    
    private fun getTimeIntArr(timeStr: String?): List<Int> {
        return timeStr!!.flatMap { it.toString().toIntOrNull()?.let { listOf(it) } ?: emptyList() }
    }


}