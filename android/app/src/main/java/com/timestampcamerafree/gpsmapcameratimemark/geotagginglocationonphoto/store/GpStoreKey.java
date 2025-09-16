package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store;

import android.os.Parcel;
import android.os.Parcelable;
import com.google.gson.annotations.SerializedName;
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg;

import org.jetbrains.annotations.NotNull;
import java.util.Objects;
import androidx.lifecycle.LifecycleOwner;

@GenerateNoArg
public class GpStoreKey implements Parcelable {
    public static GpStoreKey valueOf(String key, LifecycleOwner lifecycleOwner) {
          GpStoreKey storeKey =  new GpStoreKey(key, lifecycleOwner);
        return storeKey;
    }

    @SerializedName("rawKey")
    public final String rawKey;

    @SerializedName("sourceKey")
    public final String sourceKey;

    private GpStoreKey(Parcel in) {
        rawKey = in.readString();
        sourceKey = in.readString();
    }

    public String getKey() {
        return toString();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        GpStoreKey storeKey = (GpStoreKey) o;
        return Objects.equals(rawKey, storeKey.rawKey) &&
                Objects.equals(sourceKey, storeKey.sourceKey);
    }

    @Override
    public int hashCode() {
        return Objects.hash(rawKey, sourceKey);
    }
    private String name = "";
    @NotNull
    @Override
    public String toString() {
        return rawKey.concat("_").concat(sourceKey).concat("_").concat(name);
    }

    protected GpStoreKey(String rawKey, LifecycleOwner ower) {
        this.rawKey = rawKey;
        this.sourceKey = ower.hashCode()+"";

        name = ower.getClass().getName();
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(rawKey);
        dest.writeString(sourceKey);
    }

    public static final Creator<GpStoreKey> CREATOR = new Creator<GpStoreKey>() {
        @Override
        public GpStoreKey createFromParcel(Parcel in) {
            return new GpStoreKey(in);
        }

        @Override
        public GpStoreKey[] newArray(int size) {
            return new GpStoreKey[size];
        }
    };

}
