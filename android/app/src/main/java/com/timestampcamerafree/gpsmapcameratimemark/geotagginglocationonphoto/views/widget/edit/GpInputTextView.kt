package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.edit

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.text.Editable
import android.text.InputFilter
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.DisplayMetrics
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.widget.AppCompatEditText
import androidx.core.content.res.ResourcesCompat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpKits
import kotlin.collections.ArrayList
class GpInputTextView:FrameLayout {
    private var hint = ""
    private var scrollBars = 0
    private var maxLines = 1
    private var enableClear = true
    constructor(context:Context):super(context)
    constructor(context:Context, attrs:AttributeSet?):this(context, attrs, 0)
    constructor(context:Context, attrs:AttributeSet?, defStyleAttr:Int):this(context, attrs, defStyleAttr, 0)
    constructor(context:Context, attrs:AttributeSet?, defStyleAttr:Int, defStyleRes:Int):super(context, attrs, defStyleAttr, defStyleRes) {
        val obtainStyledAttributes =
            context.obtainStyledAttributes(attrs, R.styleable.GpInputTextView)

        hint = obtainStyledAttributes.getString(R.styleable.GpInputTextView_android_hint) ?: ""
        var subType = obtainStyledAttributes.getString(R.styleable.GpInputTextView_subType) ?: ""
        scrollBars =
            obtainStyledAttributes.getInt(R.styleable.GpInputTextView_android_scrollbars, 0)
        maxLines = obtainStyledAttributes.getInt(R.styleable.GpInputTextView_android_maxLines, -1)
        enableClear =
            obtainStyledAttributes.getBoolean(R.styleable.GpInputTextView_enableClear, true)

        delView?.visibility = if (enableClear) VISIBLE else GONE

        editText?.hint = hint
        editText?.let {
            if (scrollBars == 0x00000100) {
                it.isHorizontalScrollBarEnabled = true
                it.isVerticalScrollBarEnabled = false
            } else if (scrollBars == 0x00000200) {
                it.isHorizontalScrollBarEnabled = false
                it.isVerticalScrollBarEnabled = true
            } else {
                it.isHorizontalScrollBarEnabled = false
                it.isVerticalScrollBarEnabled = false
            }
            if (maxLines != -1) {
                it.maxLines = maxLines
            }
        }

        var rd = dpToPixels(context, 5f).toInt() + delSize + dpToPixels(context, 13f).toInt()
        if (!enableClear) {
            rd = editTextPadding
        }
        editText.setPadding(editTextPadding, editTextPadding, rd, editTextPadding)

        editText.tag = subType
        obtainStyledAttributes.recycle()

    }


    private var maxHeight = 0
    private var minHeight = 0
    private var editTextPadding = 0
    private var editTextMinPadding = 0
    private var editTextBackgroundColor = 0
    private var editTextColor = 0
    private var editTextHintColor = 0
    private var editTextBackgroundRadius = 0
    private var delSize = 0
    private var editTextSize = 0

    private val editText:EditText
    private val delView:ImageView

    init {
        editTextSize = dpToPixels(context, 17f).toInt()
        maxHeight = dpToPixels(context, 96f).toInt()
        minHeight = dpToPixels(context, 44f).toInt()
        editTextPadding = dpToPixels(context, 11f).toInt()
        editTextMinPadding = dpToPixels(context, 4f).toInt()
        editTextBackgroundRadius = dpToPixels(context, 5f).toInt()
        editTextBackgroundColor = Color.parseColor("#EBEBED")
        editTextColor = Color.parseColor("#000000")
        editTextHintColor = Color.parseColor("#B0B2BE")
        delSize = dpToPixels(context, 18f).toInt()
        editText = AppCompatEditText(context)

        val gradientDrawable = GradientDrawable()
        gradientDrawable.color = ColorStateList.valueOf(editTextBackgroundColor)
        gradientDrawable.cornerRadius = editTextBackgroundRadius.toFloat()
        editText.background = gradientDrawable
        editText.setTextColor(ColorStateList.valueOf(editTextColor))
        editText.maxHeight = maxHeight
        editText.minHeight = minHeight
        editText.gravity = Gravity.START xor Gravity.CENTER_VERTICAL
        editText.setHintTextColor(editTextHintColor)
        editText.setTextSize(TypedValue.COMPLEX_UNIT_PX, editTextSize.toFloat())
        editText.hint = hint
        addView(editText, LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        delView = ImageView(context)
        delView.setBackgroundColor(Color.BLUE)
        delView.background = (ResourcesCompat.getDrawable(resources, R.drawable.icon_del, null))
        addView(delView, delSize, delSize)
        delView.setOnClickListener(ClearText(editText))
        isFocusableInTouchMode = false
        editText.addTextChangedListener(AutoTextPadding(editText, null)!!)

        if (scrollBars == 0x00000100) {
            editText.isHorizontalScrollBarEnabled = true
            editText.isVerticalScrollBarEnabled = false
        } else if (scrollBars == 0x00000200) {
            editText.isHorizontalScrollBarEnabled = false
            editText.isVerticalScrollBarEnabled = true
        } else {
            editText.isHorizontalScrollBarEnabled = false
            editText.isVerticalScrollBarEnabled = false
        }

    }

    fun setShowSoftInputOnFocus(show:Boolean) {
        editText.showSoftInputOnFocus = show
    }


    override fun setId(id:Int) {
        super.setId(id)
    }
    fun setText(text:String?) {
        editText.setText(text)
    }

    fun setFilters(fs:Array<InputFilter>) {
        editText.filters = fs
    }
    fun setSoftShow() {
        editText.requestFocus()
        GpKits.KeyBoard.showSoftInput(App.context, editText)
    }

    fun hideSoftKey() {
        GpKits.KeyBoard.hideSoftInput(App.context, editText)
    }

    fun setSelection(length:Int) {
        editText.setSelection(length)
    }


    fun length():Int {
        return editText.length()
    }


    fun getEditableText():Editable{
        return editText.editableText
    }

    fun getSelectionStart():Int{
        return editText.selectionStart
    }


    override fun setOnFocusChangeListener(l:OnFocusChangeListener?) {
        editText.setOnFocusChangeListener(AutoFocus(editText, l))
    }

    inner class ClearText(var text:TextView, var target:OnClickListener? = null):OnClickListener {
        override fun onClick(v:View?) {
            text.setText("")
            text.requestFocus()
            target?.onClick(v)
        }
    }


    var lastCount = 0

    inner class AutoTextPadding(var text:TextView, var target:TextWatcher?):TextWatcher {
        override fun beforeTextChanged(s:CharSequence?, start:Int, count:Int, after:Int) {
        }

        override fun onTextChanged(s:CharSequence?, start:Int, before:Int, count:Int) {

        }

        override fun afterTextChanged(s:Editable?) {
            if (text.layout != null) {
                lastCount = text.layout.lineCount
            }
            var rd = dpToPixels(context, 5f).toInt() + delSize + dpToPixels(context, 13f).toInt()
            if (!enableClear) {
                rd = editTextPadding
            }
            if (text.layout?.lineCount ?: lastCount > 3) {
                editText.setPadding(editTextPadding, editTextMinPadding, rd, editTextPadding)
            } else {
                editText.setPadding(editTextPadding, editTextPadding, rd, editTextPadding)
            }
            updateDelVisibility()
            target?.afterTextChanged(s)
        }
    }


    private fun updateDelVisibility() {
        if (!enableClear) {
            return
        }
        if (editText.text?.toString()?.isNotEmpty() == true) {
            delView.visibility = View.VISIBLE
        } else {
            delView.visibility = View.GONE
        }
    }

    fun getText():String {
        return editText.text.toString()
    }


    inner class AutoFocus(var text:TextView, var target:View.OnFocusChangeListener?):View.OnFocusChangeListener {
        override fun onFocusChange(v:View?, hasFocus:Boolean) {
            target?.onFocusChange(v, hasFocus)
        }
    }


    override fun requestFocus(direction:Int, previouslyFocusedRect:Rect?):Boolean {
        return editText.requestFocus(direction, previouslyFocusedRect)
    }

    private var autoTextPaddings:ArrayList<AutoTextPadding> = ArrayList()
    fun addTextChangedListener(tw:TextWatcher) {
        var autoTextPadding = AutoTextPadding(editText, tw)
        autoTextPaddings.add(autoTextPadding)
        editText.addTextChangedListener(autoTextPadding!!)
    }

    fun removeTextChangedListener(tw:TextWatcher) {
        val iterator = autoTextPaddings.iterator()
        while (iterator.hasNext()) {
            val next = iterator.next()
            if (next.target == tw) {
                iterator.remove()
                editText.removeTextChangedListener(next)
            }
        }
    }

    fun setOnDelListener(listener:OnClickListener) {
        delView.setOnClickListener(ClearText(editText, listener))
    }


    fun dpToPixels(context:Context, dp:Float):Float {
        return dp * (context.resources.displayMetrics.densityDpi.toFloat() / DisplayMetrics.DENSITY_DEFAULT)
    }

    override fun onMeasure(widthMeasureSpec:Int, heightMeasureSpec:Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        (delView.layoutParams as FrameLayout.LayoutParams).also {
            it.gravity = Gravity.END xor Gravity.CENTER_VERTICAL
            it.rightMargin = dpToPixels(context, 13f).toInt()
        }

    }

    override fun onLayout(changed:Boolean, left:Int, top:Int, right:Int, bottom:Int) {
        super.onLayout(changed, left, top, right, bottom)

    }


    fun setSingleLine(singleLine:Boolean) {
        editText.setSingleLine()
    }

    fun setImeOptions(imeOptions:Int) {
        editText.imeOptions = imeOptions
    }

    fun setHint(hint:String) {
        editText.hint = hint
    }

    fun setGravity(gravity:Int) {
        editText.gravity = gravity
    }

    fun setEditHeight(height:Int) {
        editText.height = height
    }

    fun setEditFocusable(focusable:Boolean) {
        editText.isFocusable = focusable
    }

    fun setEditFocusableInTouchMode(focusableInTouchMode:Boolean) {
        editText.isFocusableInTouchMode = focusableInTouchMode
        if (!focusableInTouchMode && enableClear) {
            delView?.visibility = GONE
        }
    }

    fun setEditFocusableInTouchMode(focusableInTouchMode:Boolean, enableClear: Boolean) {
        editText.isFocusableInTouchMode = focusableInTouchMode
        this.enableClear = enableClear
        editText.isEnabled = false
        editText.setTextColor(Color.parseColor("#B0B2BE"))
        if (!focusableInTouchMode && !enableClear) {
            delView?.visibility = GONE
        }
    }

    fun setInputType(inputType:Int) {
        editText.inputType = inputType
    }

    fun setOnEditorActionListener(listener:TextView.OnEditorActionListener) {
        editText.setOnEditorActionListener(listener)
    }

    fun setTextColor(color:Int) {
        editText.setTextColor(color)
    }

    fun setInputFilter() {

    }

    fun hideDelViewWhenFirstShow() {
        delView.visibility = View.GONE
    }
}