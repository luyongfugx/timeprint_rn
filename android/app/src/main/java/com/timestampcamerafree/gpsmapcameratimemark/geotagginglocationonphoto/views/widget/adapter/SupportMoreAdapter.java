package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter;

import static com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter.SupportMoreListener.BOTTOM_END;
import static com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter.SupportMoreListener.BOTTOM_LOADING;

import androidx.databinding.ObservableInt;
import androidx.databinding.ViewDataBinding;
import androidx.annotation.LayoutRes;

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.BR;

import java.util.List;



public abstract class SupportMoreAdapter<V extends ViewDataBinding> extends BindingAdapter<V> {

    private ObservableInt status = new ObservableInt(BOTTOM_LOADING);

    private SupportMoreListener listener;

    public SupportMoreAdapter(SupportMoreListener listener) {
        this.listener = listener;
    }

    public SupportMoreAdapter(List<?> items, SupportMoreListener listener) {
        super(items);
        this.listener = listener;
    }

    @Override
    public void onBindViewHolder(BindingViewHolder<V> holder, int position) {

        if (items.size() > 0 && position == items.size()) {
            holder.getBinding().setVariable(BR.viewModel, status);
            holder.getBinding().setVariable(BR.presenter, listener);
            if (listener.canLoadMore()) {
                status.set(BOTTOM_LOADING);
                listener.loadMore();
            } else {
                status.set(BOTTOM_END);
            }
            holder.getBinding().executePendingBindings();

        } else {
            super.onBindViewHolder(holder, position);
        }
    }

    @Override
    public int getItemCount() {
        if (items.size() > 0) {
            return items.size() + 1;
        }
        return super.getItemCount();
    }

    @Override
    public int getItemViewType(int position) {

        if (items.size() > 0 && position >= items.size()) {
            return layoutBottomRes();
        } else {
            return super.getItemViewType(position);
        }
    }

    protected @LayoutRes
    abstract int layoutBottomRes();


    public void setStatus(int status) {
        this.status.set(status);
    }

}
