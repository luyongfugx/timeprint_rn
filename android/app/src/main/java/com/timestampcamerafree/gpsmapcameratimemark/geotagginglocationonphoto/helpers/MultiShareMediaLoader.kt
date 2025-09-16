package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.MultiShareMediaItem
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale


object MultiShareMediaLoader {

    const val TAG = "MultiShareActivity"

    fun loadImagesGroupedByDate(context: Context): List<MultiShareMediaItem> {
        val items = mutableListOf<MultiShareMediaItem>()
        val uriExternal = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATE_TAKEN
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC"

        val cursor = context.contentResolver.query(
            uriExternal, projection, null, null, sortOrder
        )

        val dateFormat = SimpleDateFormat("yyyy.MM.dd", Locale.getDefault())
        val grouped = LinkedHashMap<String, MutableList<MultiShareMediaItem.Photo>>()

        cursor?.use {
            val idIndex = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val dateIndex = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_TAKEN)

            while (it.moveToNext()) {
                val id = it.getLong(idIndex)
                val dateTaken = it.getLong(dateIndex)
                val uri = ContentUris.withAppendedId(uriExternal, id)
                val date = dateFormat.format(Date(dateTaken))

                val photo = MultiShareMediaItem.Photo(uri, date)
                grouped.getOrPut(date) { mutableListOf() }.add(photo)
            }
        }
        Log.d(TAG,"grouped ${grouped.size}")
        grouped.forEach { (date, photos) ->
            Log.d(TAG,"grouped ${date} ${photos.size}")
            items.add(MultiShareMediaItem.DateHeader(date))
            items.addAll(photos)
        }

        return items
    }
}
