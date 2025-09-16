package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

enum class WatermarkID(var id: String) {
    ID1 ( "1"),  // 默认时间地点水印
    ID2 ( "2"),  // 自定义文本水印
    ID3 ( "3" ), // 签到水印，签退水印
    ID4 ( "4" ), // 电话号码服务水印
    ID5 ( "5" ), // 安保水印
    ID6 ( "6" ), // 工作记录
    ID7 ( "7" ), // 工程水印
    ID8_1 ( "8_1"),  // 会议记录
    ID9_1 ( "9_1"),  // 时刻水印
    ID10_1 ( "10_1" ), //清洁水印
    ID11_1 ( "11_1" ),//签收水印
    ID12 ( "12" ),//新默认水印
    ID13 ( "13" ),//地图
    ID14 ( "14" ),//地图2
    ID15_1 ( "15_1" ),//新k_clock_in
    ID15_2 ( "15_2" );//新k_clock_out
}

enum class WatermarkBaseID(var id: String) {
    ID1 ( "1"),  // 默认时间地点水印
    ID2 ( "2"),  // 自定义文本水印
    ID3 ( "3" ), // 签到水印，签退水印
    ID4 ( "4" ), // 自定义文本水印
    ID5 ( "5" ), // 安保水印
    ID6 ( "6" ), // 工作记录
    ID7 ( "7" ), // 工程水印
    ID8 ( "8" ), // 会议记录
    ID9 ( "9"),  // 会议记录
    ID10 ( "10" ), //清洁水印
    ID11 ( "11" ),//签收水印
    ID12 ( "12" ),//新默认水印
    ID13 ( "13" ),//地图
    ID14 ( "14" ),//地图2
    ID15 ("15" ),//新版的签到和签退水印
    ID16 ("16" );//电话号码服务水印
}



