
package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

import android.graphics.Color
import android.os.Parcelable
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg
import kotlinx.parcelize.Parcelize
import java.util.concurrent.CopyOnWriteArrayList

@Parcelize
@GenerateNoArg
data class BaseWatermarkModel (
    @SerializedName("id") var id: String? = null,
    @SerializedName("name") var name: String? = null,
    @SerializedName("base_id") var base_id: String? = null,
    @SerializedName("items") var items: CopyOnWriteArrayList<WatermarkItem?> = CopyOnWriteArrayList<WatermarkItem?>(),
    @SerializedName("templateColorStr") var templateColorStr: String? = null,
    @SerializedName("textColorStr") var textColorStr: String? = null,
    @SerializedName("templateScale") var templateScale: Float? = null,
    @SerializedName("logoScale") var logoScale: Float? = null,
    @SerializedName("switchStatus") var switchStatus: Boolean = false,
    //水印在屏幕上的位置，默认为 0，0
    @SerializedName("top") var top:Int = 0,
    @SerializedName("left") var left:Int = 0
) : Parcelable {
    val fullName: String
        get() = "$name $id"
    //新clone 一个BaseWatermarkModel
    fun clone(): BaseWatermarkModel {
      val newBaseWatermarkModel = BaseWatermarkModel()
        newBaseWatermarkModel.id = this.id
        newBaseWatermarkModel.name = this.name
        newBaseWatermarkModel.base_id = this.base_id
        newBaseWatermarkModel.items = this.items
        newBaseWatermarkModel.templateColorStr = this.templateColorStr
        newBaseWatermarkModel.textColorStr = this.textColorStr
        newBaseWatermarkModel.templateScale = this.templateScale
        newBaseWatermarkModel.logoScale = this.logoScale
        newBaseWatermarkModel.switchStatus = this.switchStatus
        return  newBaseWatermarkModel
    }
    val templateColor:Int get() {
        val colorStr = templateColorStr?:"#FFFFFF"
        if(!colorStr.startsWith("#")){
            return Color.parseColor("#$colorStr")
        }
        return Color.parseColor(colorStr)
    }
    val textColor:Int get()  {
        val colorStr = textColorStr?:"#FFFFFF"
        if(!colorStr.startsWith("#")){
            return Color.parseColor("#$colorStr")
        }
        return Color.parseColor(colorStr)
    }
}
