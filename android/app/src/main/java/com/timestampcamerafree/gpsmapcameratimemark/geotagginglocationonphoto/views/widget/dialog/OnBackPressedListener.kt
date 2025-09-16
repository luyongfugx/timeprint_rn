package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.dialog

import android.content.DialogInterface
import android.os.Parcel
import android.os.Parcelable
import android.view.KeyEvent

abstract class OnBackPressedListener : Parcelable {
    abstract fun backPressedListener(
        dialog: DialogInterface?,
        keyCode: Int,
        event: KeyEvent?
    )
    constructor()
    protected constructor(`in`: Parcel?)
    override fun describeContents(): Int {
        return 0
    }

    override fun writeToParcel(dest: Parcel, flags: Int) {
    }


    companion object {
        val CREATOR: Parcelable.Creator<OnBackPressedListener?> =
            object : Parcelable.Creator<OnBackPressedListener?> {
                override fun createFromParcel(`in`: Parcel): OnBackPressedListener? {
                    return object : OnBackPressedListener(`in`) {
                        override fun backPressedListener(
                            dialog: DialogInterface?,
                            keyCode: Int,
                            event: KeyEvent?
                        ) {
                        }
                    }
                }

                override fun newArray(size: Int): Array<OnBackPressedListener?> {
                    return arrayOfNulls(size)
                }
            }
    }
}
