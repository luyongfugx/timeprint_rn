package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.os.Bundle
import android.os.Parcel
import android.os.Parcelable

abstract class GpViewConvertListener : Parcelable {
    private val bundle = Bundle()
    abstract fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?)

    override fun describeContents(): Int {
        return 0
    }

    override fun writeToParcel(dest: Parcel, flags: Int) {
    }

    constructor()

    protected constructor(`in`: Parcel?)

    fun put(key: String?, value: String?) {
        bundle.putString(key, value)
    }

    fun put(key: String?, value: Boolean?) {
        bundle.putBoolean(key, value!!)
    }

    fun <T> get(key: String?): T? {
        return bundle[key] as T?
    }

    fun onStartVoiceInput(editTag: String?) {
    }


    companion object {
        val CREATOR: Parcelable.Creator<GpViewConvertListener?> =
            object : Parcelable.Creator<GpViewConvertListener?> {
                override fun createFromParcel(source: Parcel): GpViewConvertListener? {
                    return object : GpViewConvertListener(source) {
                        override fun convertView(holder: GpViewHolder?, dialog: GPBaseDialog?) {
                        }
                    }
                }

                override fun newArray(size: Int): Array<GpViewConvertListener?> {
                    return arrayOfNulls(size)
                }
            }
    }
}