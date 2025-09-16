package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark

/**
 * 水印点击来源
 *
 * @property id
 */
enum class EditClickFrom(var id: String) {
    Watermark("waterMark"),
    Logo ( "logo"),  // 默认时间地点水印
    Map ( "map"),  // 自定义文本水印
    WatermarkSelectBtn("watermark_select_btn"), //首页选择水印
}