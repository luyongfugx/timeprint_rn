package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.util.Log
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter

/**
 *
 *
 * @constructor
 * TODO
 *
 * @param fragmentActivity
 */
class GpEditWaterMarkViewPagerAdapter(fragmentActivity: FragmentActivity) : FragmentStateAdapter(fragmentActivity) {
    private val fragments = mutableListOf<Fragment>()
    private val fragmentTitles = mutableListOf<String>()

    fun addFragment(fragment: Fragment, title: String) {

        fragments.add(fragment)
        fragmentTitles.add(title)
    }

    override fun getItemCount(): Int {
        return fragments.size
    }

    override fun createFragment(position: Int): Fragment {
        return fragments[position]
    }

    fun getPageTitle(position: Int): String {
        return fragmentTitles[position]
    }
}
