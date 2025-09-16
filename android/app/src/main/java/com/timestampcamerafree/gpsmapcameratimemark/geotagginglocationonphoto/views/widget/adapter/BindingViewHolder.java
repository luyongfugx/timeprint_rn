package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter;

import androidx.databinding.ViewDataBinding;
import androidx.recyclerview.widget.RecyclerView;

public class BindingViewHolder<T extends ViewDataBinding> extends RecyclerView.ViewHolder {
    protected final T binding;

    public BindingViewHolder(T t) {
        super(t.getRoot());
        this.binding = t;

    }

    public T getBinding() {
        return binding;
    }
}
