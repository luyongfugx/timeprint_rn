package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers
import android.widget.ImageView
import androidx.databinding.BindingAdapter

/**
 * binding
 */
object ImageViewBindingAdapters {
    @JvmStatic
    @BindingAdapter("android:srcDrawable")
    fun setImageResource(imageView: ImageView, resource: Int?) {
        resource?.let {
            imageView.setImageResource(it)
        }
    }
    @JvmStatic
    @BindingAdapter("android:tintColor")
    fun setColorFilter(imageView: ImageView, resource: Int?) {
        resource?.let {
            imageView.setColorFilter(it)
        }
    }


}