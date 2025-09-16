package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion.context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.SettingItem
////设置菜单
//const val SETTING_PHOTO_QUALITY = 0
////保存原始照片
//const val SETTING_PHOTO_SAVE_ORIGIN = 1
////切换语言
//const val SETTING_CHANGE_LANG = 3
////联系客服
//const val SETTING_CONTACT = 4

class SettingMenuManager {
    companion object {
        fun getSettingItemList(): List<SettingItem> {
            val settingList: ArrayList<SettingItem> = ArrayList()
            val  photoQuality = SettingItem(
                id = SETTING_PHOTO_QUALITY,
                title = context.resources.getString(R.string.i_photo_quality)
            )
            val  photoSaveOrigin = SettingItem(
                id = SETTING_PHOTO_SAVE_ORIGIN,
                title = context.resources.getString(R.string.i_save_origin_photo)
            )
            val  moreSetting = SettingItem(
                id = SETTING_MORE,
                title = context.resources.getString(R.string.i_share_more)
            )
            val  changeLang = SettingItem(
                id = SETTING_CHANGE_LANG,
                title = context.resources.getString(R.string.i_swith_language)
            )
            val  contactus = SettingItem(
                id = SETTING_CONTACT,
                title = context.resources.getString(R.string.k_feed_back)
            )
            val  changeSaveFolder = SettingItem(
                id = SETTING_SAVE_FOLDER,
                title = context.resources.getString(R.string.k_photo_save_path)
            )
            settingList.add(photoQuality)
            settingList.add(photoSaveOrigin)
            settingList.add(changeLang)
            settingList.add(contactus)
            settingList.add(changeSaveFolder)
            settingList.add(moreSetting)
            return settingList;
        }
    }
}