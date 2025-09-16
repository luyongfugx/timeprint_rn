package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.BaseWatermarkModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkID
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID

/**
 * 每种水印top(includes) 和 bottom(excludes) 的item管理器
 *
 */
class WatermarkItemManager {
    companion object {
        private val watermarkID1BottomExcludes = listOf(
            WatermarkItemID.time,
        )

        private val watermarkID12BottomExcludes = listOf(
            WatermarkItemID.address,
            WatermarkItemID.time,
        )
        private val watermarkID3BottomExcludes = listOf(
            WatermarkItemID.watermarkTitle,
        )
        private val watermarkID4BottomExcludes = listOf(
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.weather,
            WatermarkItemID.address,
            WatermarkItemID.altitude,
            WatermarkItemID.coordinate,
            WatermarkItemID.time
        )
        private val watermarkID6BottomExcludes = listOf(
            WatermarkItemID.time,
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.watermarkSubtitle
        )
        private val watermarkID13BottomExcludes = listOf(
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.watermarkSubtitle
        )
        private val watermarkID14BottomExcludes = listOf(
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.watermarkSubtitle
        )
        private val watermarkID7BottomExcludes = listOf(

            WatermarkItemID.watermarkTitle,
            WatermarkItemID.watermarkSubtitle
        )
        private val watermarkID8_1BottomExcludes = listOf(
            WatermarkItemID.time,
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.wm8_meeting_title
        )
        private val watermarkID11_12BottomExcludes = listOf(
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.wm8_meeting_title
        )

        private val watermarkID4TopIncludes = listOf(
            WatermarkItemID.weather,
            WatermarkItemID.address,
            WatermarkItemID.altitude,
            WatermarkItemID.coordinate,
            WatermarkItemID.time
        )
        private val watermarkID13TopIncludes = listOf(
            WatermarkItemID.weather,
            WatermarkItemID.address,
            WatermarkItemID.altitude,
            WatermarkItemID.coordinate,
            WatermarkItemID.time
        )
        private val watermarkID14TopIncludes = listOf(
            WatermarkItemID.weather,
            WatermarkItemID.address,
            WatermarkItemID.altitude,
            WatermarkItemID.coordinate,
            WatermarkItemID.time
        )



        private val watermarkBottomExcludeMap: MutableMap<String, List<WatermarkItemID>> = mutableMapOf(
            WatermarkID.ID1.id to watermarkID1BottomExcludes,
            WatermarkID.ID12.id to watermarkID12BottomExcludes,
            WatermarkID.ID3.id to watermarkID3BottomExcludes,
            WatermarkID.ID2.id to watermarkID3BottomExcludes,
            WatermarkID.ID4.id to watermarkID4BottomExcludes,
            WatermarkID.ID5.id to watermarkID4BottomExcludes,
            WatermarkID.ID6.id to watermarkID6BottomExcludes,
            WatermarkID.ID7.id to watermarkID7BottomExcludes,
            WatermarkID.ID8_1.id to watermarkID8_1BottomExcludes,
            WatermarkID.ID10_1.id to watermarkID11_12BottomExcludes,
            WatermarkID.ID11_1.id to watermarkID11_12BottomExcludes,
            WatermarkID.ID13.id to watermarkID13BottomExcludes,
            WatermarkID.ID14.id to watermarkID14BottomExcludes,
            WatermarkID.ID15_1.id to watermarkID3BottomExcludes,
            WatermarkID.ID15_2.id to watermarkID3BottomExcludes
        )

        private val watermarkTopIncludeMap: MutableMap<String, List<WatermarkItemID>> = mutableMapOf(
            WatermarkID.ID1.id to watermarkID1BottomExcludes,
            WatermarkID.ID12.id to watermarkID12BottomExcludes,
            WatermarkID.ID3.id to watermarkID3BottomExcludes,
            WatermarkID.ID2.id to watermarkID3BottomExcludes,
            WatermarkID.ID4.id to watermarkID4TopIncludes,
            WatermarkID.ID5.id to watermarkID4TopIncludes,
            WatermarkID.ID6.id to watermarkID4TopIncludes,
            WatermarkID.ID7.id to watermarkID4TopIncludes,
            WatermarkID.ID8_1.id to watermarkID4TopIncludes,
            WatermarkID.ID10_1.id to watermarkID4TopIncludes,
            WatermarkID.ID11_1.id to watermarkID4TopIncludes,
            WatermarkID.ID13.id to watermarkID13TopIncludes,
            WatermarkID.ID14.id to watermarkID14TopIncludes,
            WatermarkID.ID15_1.id to watermarkID3BottomExcludes,
            WatermarkID.ID15_2.id to watermarkID3BottomExcludes
        )




        /**
         * 过滤掉内容为空的item
         *
         * @param items
         * @return
         */
        fun filterEmptyContentItemList(items:List<WatermarkItem?>?): List<WatermarkItem?>? {
            return items?.filter { watermarkItem -> watermarkItem?.content?.isNotEmpty() == true }
        }

        /**
         * 基础过滤，过滤掉必须过滤的item，比如map,logo,以及天气，地址空的时候
         * @param items
         * @return
         */
        private fun filterBaseItem(items:List<WatermarkItem?>?): List<WatermarkItem?>? {
            val newItemList = items?.filter { watermarkItem ->
                //如果打开且，不是地图，logo,天气和地址，则显示
                if ((watermarkItem?.isOpen == true && (
                            watermarkItem.id != WatermarkItemID.map.id &&
                                    watermarkItem.id != WatermarkItemID.logo.id &&
                                    watermarkItem.id != WatermarkItemID.weather.id &&
                                    watermarkItem.id != WatermarkItemID.address.id
                            ))){
                    return@filter true
                }
                //天气打开且不为空
                if(watermarkItem?.isOpen == true && watermarkItem.id == WatermarkItemID.weather.id && watermarkItem.content?.isNotEmpty()==true){
                    return@filter true
                }
                //地址打开且不为空
                if(watermarkItem?.isOpen == true && watermarkItem.id == WatermarkItemID.address.id && watermarkItem.content?.isNotEmpty()==true){
                    return@filter true
                }
                return@filter false
            }
            return newItemList
        }

        /**
         * 底部Items
         *
         * @param watermarkModel
         * @return
         */

        fun getBottomItemList(watermarkModel: BaseWatermarkModel): List<WatermarkItem?> {
            return try {
                val newItemList = filterBaseItem(watermarkModel.items)
                filterBottomById(newItemList, watermarkModel.id ?: "") ?: emptyList()
            } catch (e: Exception) {
                emptyList()
            }
        }

        /**
         * 过滤掉底部不显示的item
         *
         * @param items
         * @param id
         * @return
         */
        private fun filterBottomById(items:List<WatermarkItem?>?,id: String): List<WatermarkItem?>? {
            val excludes = watermarkBottomExcludeMap[id]
            return items?.filter { watermarkItem ->
                watermarkItem?.idType?.let {
                    excludes?.contains(
                        it
                    )
                } == false
            }
        }


        /*
        顶部items
         */
        fun getTopItemList(watermarkModel: BaseWatermarkModel): List<WatermarkItem?> {
            return try {
                val newItemList = filterBaseItem(watermarkModel.items)
                filterTopExcludeById(newItemList, watermarkModel.id ?: "") ?: emptyList()
            } catch (e: Exception) {
                emptyList()
            }
        }


        /**
         * 过滤掉底部不显示的item
         *
         * @param items
         * @param id
         * @return
         */
        private fun filterTopExcludeById(items:List<WatermarkItem?>?,id: String): List<WatermarkItem?>? {
            val includes = watermarkTopIncludeMap[id]
            return items?.filter { watermarkItem ->
                watermarkItem?.idType?.let {
                    includes?.contains(
                        it
                    )
                } == true
            }
        }


    }
}