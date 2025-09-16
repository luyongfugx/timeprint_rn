package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime


/**
 * 日期拆解类
 *
 * @property year
 * @property month
 * @property shortMonth
 * @property day
 * @property week
 * @property hh
 * @property mm
 * @property ss
 * @property ampm
 * @property date
 */
data class GPDateCommpent(
    var year: String? = null,
    var month: String? = null,
    var shortMonth: String? = null,
    var day: String? = null,
    var week: String? = null,
    var hh: String? = null,
    var mm: String? = null,
    // add ss for 秒
    var ss: String? = null,
    var ampm: String? = null,
    // 18/08/2024
    var date: String? = null,
)