package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget.adapter;

import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;
import androidx.annotation.LayoutRes;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.ViewGroup;

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.BR;

import java.util.Collections;
import java.util.List;

public abstract class BindingAdapter<V extends ViewDataBinding> extends RecyclerView
        .Adapter<BindingViewHolder<V>> {

    protected List<?> items;

    protected String lightCharacters = "";

    public BindingAdapter() {
        this(Collections.emptyList());
    }

    public BindingAdapter(List<?> items) {
        this.items = items;
    }

    public void setItems(List<?> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    public void setLightCharacters(String lightCharacters) {
        this.lightCharacters = lightCharacters;
    }

    public String getLightCharacters() {
        return this.lightCharacters;
    }

    @Override
    public BindingViewHolder<V> onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        int layoutId = viewType;
        if (layoutId == 0) {
            layoutId = layoutRes();
        }
        V binding = DataBindingUtil.inflate(inflater, layoutId, parent, false);
        return createBindingHolder(binding);
    }


    @Override
    public void onBindViewHolder(@NonNull BindingViewHolder<V> holder, int position) {
        if (items.size() > 0 && position < items.size()) {
            holder.getBinding().setVariable(BR.viewModel, items.get(position));
            onBindingView((V) holder.getBinding(), position);
            holder.getBinding().executePendingBindings();
        }
    }

    @Override
    public int getItemCount() {
        if (layoutEmptyRes() != 0 && items.isEmpty()) {
            return 1;
        }
        return items.size();
    }

    protected void onBindingView(V binding, int position) {
    }

    protected BindingViewHolder<V> createBindingHolder(V binding) {
        return new BindingViewHolder<>(binding);
    }

    @Override
    public int getItemViewType(int position) {

        if (items.isEmpty() && layoutEmptyRes() != 0) {
            return layoutEmptyRes();
        } else {
            return layoutRes();
        }
    }

    protected abstract @LayoutRes
    int layoutRes();

    protected @LayoutRes
    int layoutEmptyRes() {
        return 0;
    }
}
