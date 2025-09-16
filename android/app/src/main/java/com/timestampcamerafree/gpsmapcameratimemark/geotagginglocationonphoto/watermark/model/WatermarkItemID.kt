package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

enum class WatermarkItemID(var id: Int) {
    customItem(-1),
    logo(1),
    time(2),
    address(3),
    coordinate(4),
    map(5),
    weather(6),
    altitude(7),
    note(8),
    watermarkTitle(9),
    watermarkSubtitle(10),
    serviceDetail1(41),
    serviceDetail2(42),
    serviceDetail3(43),

    phoneNumber1(44),
    phoneNumber2(45),


    // Project
    wm7_project(70),
    wm7_developer(71),
    wm7_description(72),
    wm7_area(73),
    wm7_operator(74),
    wm7_inspectior(75),
    wm7_inspection(76),
    wm8_meeting_title(80),
    wm10_clean_title(100);

    fun getIkey(): String  = when (this) {
        customItem -> ""
        logo -> "k_logo"
        time -> "k_time"
        address -> "k_address"
        coordinate ->  "k_coordinate"
        map -> "k_map"
        weather -> "k_weather"
        altitude ->  "k_altitude"
        note ->  "k_note"
        watermarkTitle ->  "k_title"
        watermarkSubtitle ->  "k_subtitle"
        phoneNumber1 -> ""
        phoneNumber2 -> ""
            // Project
        wm7_project-> ""
        wm7_developer-> ""
        wm7_description-> ""
        wm7_area-> ""
        wm7_operator-> ""
        wm7_inspectior-> ""
        wm7_inspection-> ""
        wm8_meeting_title-> "i_meeting_title"
        wm10_clean_title-> ""
        serviceDetail1 -> ""
        serviceDetail2 -> ""
        serviceDetail3 -> ""
    }
}
