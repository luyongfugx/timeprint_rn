package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import android.location.Address
import java.util.Locale

data class SerializableAddress(
    val featureName: String?,
    val countryCode: String?,
    val countryName: String?,
    val adminArea: String?,
    val subAdminArea: String?,
    val locality: String?,
    val subLocality: String?,
    val thoroughfare: String?,
    val subThoroughfare: String?,
    val postalCode: String?,
    val phone: String?,
    val url: String?,
    val latitude: Double,
    val longitude: Double,
    val addressLines: Array<String> = emptyArray()
) {
    constructor(address: Address) : this(
        featureName = address.featureName,
        countryCode = address.countryCode,
        countryName = address.countryName,
        adminArea = address.adminArea,
        subAdminArea = address.subAdminArea,
        locality = address.locality,
        subLocality = address.subLocality,
        thoroughfare = address.thoroughfare,
        subThoroughfare = address.subThoroughfare,
        postalCode = address.postalCode,
        phone = address.phone,
        url = address.url,
        latitude = address.latitude,
        longitude = address.longitude,
        addressLines = (0 until 1).map { address.getAddressLine(it) }.toTypedArray()
    )

    fun toAddress(): Address {
        return Address(Locale.getDefault()).apply {
            featureName = this@SerializableAddress.featureName
            countryCode = this@SerializableAddress.countryCode
            countryName = this@SerializableAddress.countryName
            adminArea = this@SerializableAddress.adminArea
            subAdminArea = this@SerializableAddress.subAdminArea
            locality = this@SerializableAddress.locality
            subLocality = this@SerializableAddress.subLocality
            thoroughfare = this@SerializableAddress.thoroughfare
            subThoroughfare = this@SerializableAddress.subThoroughfare
            postalCode = this@SerializableAddress.postalCode
            phone = this@SerializableAddress.phone
            url = this@SerializableAddress.url
            latitude = this@SerializableAddress.latitude
            longitude = this@SerializableAddress.longitude

            // Set all address lines
            addressLines.forEachIndexed { index, line ->
                setAddressLine(index, line)
            }
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as SerializableAddress

        if (featureName != other.featureName) return false
        if (countryCode != other.countryCode) return false
        if (countryName != other.countryName) return false
        if (adminArea != other.adminArea) return false
        if (subAdminArea != other.subAdminArea) return false
        if (locality != other.locality) return false
        if (subLocality != other.subLocality) return false
        if (thoroughfare != other.thoroughfare) return false
        if (subThoroughfare != other.subThoroughfare) return false
        if (postalCode != other.postalCode) return false
        if (phone != other.phone) return false
        if (url != other.url) return false
        if (latitude != other.latitude) return false
        if (longitude != other.longitude) return false
        if (!addressLines.contentEquals(other.addressLines)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = featureName?.hashCode() ?: 0
        result = 31 * result + (countryCode?.hashCode() ?: 0)
        result = 31 * result + (countryName?.hashCode() ?: 0)
        result = 31 * result + (adminArea?.hashCode() ?: 0)
        result = 31 * result + (subAdminArea?.hashCode() ?: 0)
        result = 31 * result + (locality?.hashCode() ?: 0)
        result = 31 * result + (subLocality?.hashCode() ?: 0)
        result = 31 * result + (thoroughfare?.hashCode() ?: 0)
        result = 31 * result + (subThoroughfare?.hashCode() ?: 0)
        result = 31 * result + (postalCode?.hashCode() ?: 0)
        result = 31 * result + (phone?.hashCode() ?: 0)
        result = 31 * result + (url?.hashCode() ?: 0)
        result = 31 * result + latitude.hashCode()
        result = 31 * result + longitude.hashCode()
        result = 31 * result + addressLines.contentHashCode()
        return result
    }
}