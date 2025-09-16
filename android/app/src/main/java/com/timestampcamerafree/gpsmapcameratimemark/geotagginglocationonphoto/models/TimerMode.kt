package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import androidx.annotation.DrawableRes
import androidx.annotation.IdRes
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

enum class TimerMode(val millisInFuture: Long) {
    OFF(0),
    TIMER_3(3000),
    TIMER_5(5000),
    TIMER_10(10000);

    fun getTimerModeResId(): Int {
        return when (this) {
            OFF -> R.id.timer_off
            TIMER_3 -> R.id.timer_3s
            TIMER_5 -> R.id.timer_5s
            TIMER_10 -> R.id.timer_10_s
        }
    }

    fun getTimerModeDrawableRes(): Int {
        return when (this) {
            OFF -> R.drawable.ic_timer_off_vector
            TIMER_3 -> R.drawable.ic_timer_3_vector
            TIMER_5 -> R.drawable.ic_timer_5_vector
            TIMER_10 -> R.drawable.ic_timer_10_vector
        }
    }
}

data class TimerModeOption(
    @IdRes val buttonViewId: Int,
    val text: String,
    @DrawableRes val imageDrawableResId: Int,
    val value: Int
) {
    companion object {
        fun fromValue(value: Int): TimerModeOption {
            return when (value) {
                0 -> TimerModeOption(
                    buttonViewId = R.id.timer_off,
                    text = "0s",
                    imageDrawableResId = R.drawable.ic_timer_off_vector,
                    value = 0
                )
                3 -> TimerModeOption(
                    buttonViewId = R.id.timer_3s,
                    text = "3s",
                    imageDrawableResId = R.drawable.ic_timer_3_vector,
                    value = 3
                )
                5 -> TimerModeOption(
                    buttonViewId = R.id.timer_5s,
                    text = "5s",
                    imageDrawableResId = R.drawable.ic_timer_5_vector,
                    value = 5
                )
                10 -> TimerModeOption(
                    buttonViewId = R.id.timer_10_s,
                    text = "10s",
                    imageDrawableResId = R.drawable.ic_timer_10_vector,
                    value = 10
                )
                else -> throw IllegalArgumentException("Invalid timer value: $value")
            }
        }
    }
}