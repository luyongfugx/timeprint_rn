package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.widget.RelativeLayout
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.LogoPosition

/**
 * logo,map等需要
 * 根据角度来获取logo，map等的左上，等位置
 */
class GpWidgetPosManager {
    companion object {
        private var TAG = "GpWidgetPosManager";
        private var gravityList = arrayOf(
            RelativeLayout.ALIGN_PARENT_TOP,
            RelativeLayout.ALIGN_PARENT_LEFT,
            RelativeLayout.ALIGN_PARENT_RIGHT,
            RelativeLayout.CENTER_IN_PARENT,
            RelativeLayout.ALIGN_PARENT_BOTTOM
        )

        /**
         * 根据布局对应列表
         */
        private var widgetGravitys = arrayOf(
            arrayOf(gravityList[3]), //居中
            arrayOf(gravityList[0], gravityList[1]), // 左上
            arrayOf(gravityList[0], gravityList[2]), // 右上
            arrayOf(gravityList[4], gravityList[2]), // 右下
            arrayOf(gravityList[4], gravityList[1]) // 左下
        )
        /**
         * 根据logo当前的位置和旋转的角度，获得当前logo的布局规则
         * */
        fun getLayoutRulesByPosAndOrientation(position: LogoPosition?, currentOrientation: Int): Array<Int> {
            var outGravityArrayIndex = when(position){
                LogoPosition.CENTER-> 0
                LogoPosition.LEFT_TOP-> 1
                LogoPosition.RIGHT_TOP-> 2
                LogoPosition.RIGHT_BOTTOM -> 3
                else -> 0
            }
            if (LogoPosition.CENTER == position){
                return widgetGravitys[0]
            }
            // 用角度除90度，就是旋转后的布局位置索引
            var  result = outGravityArrayIndex - currentOrientation / 90
            if (result < 1) {
                result += widgetGravitys.size - 1
            }
            return widgetGravitys[result]
        }
    }
}