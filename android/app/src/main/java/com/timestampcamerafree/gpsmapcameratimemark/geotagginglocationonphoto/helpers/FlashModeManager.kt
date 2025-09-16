package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion.context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.FlashMode
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.IconFontType

class FlashModeManager {
    companion object {
        fun getFlashModeList(): List<FlashMode> {
            val flashModeList: ArrayList<FlashMode> = ArrayList()
            val flashOff = FlashMode(
                iconText = IconFontType.BTN_FLASH_CLOSE.unicode,
                mode = FLASH_OFF,
                text =  context.resources.getString(R.string.i_flash_close)
            )
            val flashOn = FlashMode(
                iconText = IconFontType.BTN_FLASH_OPEN.unicode,
                mode = FLASH_ON,
                text = context.resources.getString(R.string.i_flash_open)
            )
            val flashAuto = FlashMode(
                iconText = IconFontType.BTN_FLASH_AUTO.unicode,
                mode = FLASH_AUTO,
                text = context.resources.getString(R.string.i_flash_auto)
            )
            val flashAlwaysOn = FlashMode(
                iconText = IconFontType.BTN_FLASHLIGHT.unicode,
                mode = FLASH_ALWAYS_ON,
                text = context.resources.getString(R.string.i_flashlight)
            )

            flashModeList.add(flashOff)
            flashModeList.add(flashOn)
            flashModeList.add(flashAuto)
            flashModeList.add(flashAlwaysOn)
            return flashModeList;
        }
    }
}