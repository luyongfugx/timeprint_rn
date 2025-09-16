package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import android.content.Context
import androidx.annotation.DrawableRes
import androidx.annotation.IdRes
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

data class MySize(val width: Int, val height: Int, val isFullScreen: Boolean = false) {
    companion object {
        private const val ONE_MEGA_PIXEL = 1000000
        private const val ZERO_MEGA_PIXEL = "0.0"
    }

    private val ratio = width / height.toFloat()

    val pixels: Int = width * height

    val megaPixels: String = String.format("%.1f", (width * height.toFloat()) / ONE_MEGA_PIXEL)

    fun requiresCentering(): Boolean {
        return !isFullScreen && (isFourToThree() || isThreeToTwo() || isSquare())
    }

    fun isSixteenToNine() = ratio == 16 / 9f

    private fun isFiveToThree() = ratio == 5 / 3f

     fun isFourToThree() = ratio == 4 / 3f

    private fun isTwoToOne() = ratio == 2f

    private fun isThreeToFour() = ratio == 3 / 4f

    private fun isThreeToTwo() = ratio == 3 / 2f

    private fun isSixToFive() = ratio == 6 / 5f

    private fun isNineteenToNine() = ratio == 19 / 9f

    private fun isNineteenToEight() = ratio == 19 / 8f

    private fun isOneNineToOne() = ratio == 1.9f

     fun isSquare() = width == height

    fun isSupported(isFullScreenSize16x9: Boolean): Boolean {
        return if (isFullScreenSize16x9) {
            isFourToThree() || isSquare()
        } else {
            isFourToThree() || isSixteenToNine() || isSquare()
        } && megaPixels != ZERO_MEGA_PIXEL
    }

    fun getAspectRatio(context: Context?) = when {
        isSixteenToNine() -> App.context.resources.getString(R.string.i_ratio_9x16) //"16:9"
        isFiveToThree() -> "5:3"
        isFourToThree() -> App.context.resources.getString(R.string.i_ratio_3x4) //"4:3"
        isThreeToFour() -> "3:4"
        isThreeToTwo() -> "3:2"
        isSixToFive() -> "6:5"
        isOneNineToOne() -> "1.9:1"
        isNineteenToNine() -> "19:9"
        isNineteenToEight() -> "19:8"
        isSquare() -> App.context.resources.getString(R.string.i_ratio_1x1)
        isTwoToOne() -> "2:1"
        else -> App.context.resources.getString(R.string.i_ratio_full)
    }

    @DrawableRes
    fun getImageResId(): Int = when {
        isFullScreen -> R.drawable.ic_photo_full_vector
        isSixteenToNine() -> R.drawable.ic_photo_16x9_vector
        isFourToThree() -> R.drawable.ic_photo_4x3_vector
        isSquare() -> R.drawable.ic_photo_1x1_vector
        else -> throw UnsupportedOperationException("This size $this is not supported")
    }

    @IdRes
    fun getButtonId(): Int = when {
        isFullScreen -> R.id.photo_full
        isSixteenToNine() -> R.id.photo_16x9
        isFourToThree() -> R.id.photo_4x3
        isSquare() -> R.id.photo_1x1
        else -> throw UnsupportedOperationException("This size $this is not supported")
    }

    /**
     * 排序
     *
     * @return
     */
    fun getSortId(): Int = when {
        isFourToThree() -> 3
        isSquare() -> 2
        isSixteenToNine() -> 1
        else -> 0
    }

    fun toResolutionOption(): ResolutionOption {
        return ResolutionOption(buttonViewId = getButtonId(), imageDrawableResId = getImageResId(), resolution = getAspectRatio(null))
    }
}
