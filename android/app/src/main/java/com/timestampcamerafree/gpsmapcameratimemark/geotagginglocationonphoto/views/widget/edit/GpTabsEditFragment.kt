package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProvider
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKey
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.BaseFragment
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager

/*
  多tab页
 */
class GpTabsEditFragment: BaseFragment(), View.OnClickListener {
    private val TAG = "GpTabsEditFragment"
    private lateinit var viewPagerAdapter: GpEditWaterMarkViewPagerAdapter
    private lateinit var viewPager: ViewPager2
    private lateinit var tabLayout: TabLayout
    private lateinit var  selectStampFragment: GpSelectStampFragment
    var itemGpTabsIdEdit = -1
    private val eViewModel by lazy { ViewModelProvider(parentFragment ?: requireActivity()).get(EditViewModel::class.java) }
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        this.observeDataStores(GpStoreKeys.KEY_SHOW_STAMP_EDIT_TAB,{ updateValue: Boolean ->
          showEditTab()
        })
        this.observeDataStores(GpStoreKeys.WATERMARK_ID_CHANGE,{ updateValue: Boolean ->
            //如果修改了id,则eViewModel 重新获取数据
            eViewModel.getData()
        })

       var from = arguments?.getString("from") ?: "" // 获取字符串参数
        if (from == EditClickFrom.WatermarkSelectBtn.id){ //如果是首页选择水印
            showSelectTab()
        }
        else {
            showEditTab()
        }
    }
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val bundle = arguments
        val view = inflater.inflate(R.layout.layout_tabs_edit, container, false)
        val iv_edit_close = view.findViewById<View>(R.id.iv_edit_close)
        viewPager = view.findViewById(R.id.viewpager)
        tabLayout = view.findViewById(R.id.tab_layout)
        // Set up the adapter
        viewPagerAdapter = GpEditWaterMarkViewPagerAdapter(requireActivity())
      var editFragment =  GpEditWaterMarkFragment().apply {
           viewModel = eViewModel
            itemIdEdit = itemGpTabsIdEdit
            singleLineItem(true)
            arguments = bundle
        }
        selectStampFragment = GpSelectStampFragment()
        // Add the fragments
        viewPagerAdapter.addFragment(editFragment, GpUiUtils.getString(R.string.i_edit_stamp))
        viewPagerAdapter.addFragment(selectStampFragment, GpUiUtils.getString(R.string.i_choose_stamp))
        // Set the adapter to the ViewPager2
        viewPager.adapter = viewPagerAdapter
        TabLayoutMediator(tabLayout, viewPager) { tab, position ->
            tab.text = viewPagerAdapter.getPageTitle(position)
        }.attach()
        iv_edit_close.setOnClickListener({
            eViewModel.clickClose()
        })
        return view
    }
    private fun  showEditTab(){
        viewPager.currentItem = 0
    }
    private fun  showSelectTab(){
        viewPager.currentItem = 1

    }

    /**
     * 监听DataStores，主要用来监听水印修改等等
     *
     * @param T
     * @param storeKey
     * @param observer
     */
    private fun<T> observeDataStores(storeKey:String, observer: Observer<T>){
        GpDataStores.observe(
            GpStoreKey.valueOf(
                storeKey,
                requireActivity()
            ), observer, this
        )
    }
    override fun onBackPressed() {
        eViewModel.clickClose()
        TODO("Not yet implemented")
    }

    override fun onClick(v: View?) {
        TODO("Not yet implemented")
    }

}