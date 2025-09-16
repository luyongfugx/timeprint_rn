package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.content.Context
import android.graphics.Typeface
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatTextView

/**
 * iconfontTextview
 *
 * @constructor
 * TODO
 *
 * @param context
 * @param attrs
 * @param defStyleAttr
 */
class IconFontTextView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : AppCompatTextView(context, attrs, defStyleAttr) {

    init {
        initIconFont()
    }

    private fun initIconFont() {
        try {
            val typeface = Typeface.createFromAsset(context.assets, "fonts/iconfont.ttf") // 替换为你的字体文件名
            typeface?.let {
                setTypeface(it)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}