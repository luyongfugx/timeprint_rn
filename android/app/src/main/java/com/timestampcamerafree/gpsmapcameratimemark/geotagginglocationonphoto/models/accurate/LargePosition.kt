package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate;

import android.os.Parcel
import android.os.Parcelable
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

@GenerateNoArg
data class LargePosition(@SerializedName("id") var id: Int,
                         @SerializedName("name") var name: String):Parcelable{
    constructor(parcel: Parcel) : this(
            parcel.readInt(),
            parcel.readString()?:"") {
    }

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeInt(id)
        parcel.writeString(name)
    }

    override fun describeContents(): Int {
        return 0
    }

    companion object CREATOR : Parcelable.Creator<LargePosition> {
        override fun createFromParcel(parcel: Parcel): LargePosition {
            return LargePosition(parcel)
        }

        override fun newArray(size: Int): Array<LargePosition?> {
            return arrayOfNulls(size)
        }
    }

}