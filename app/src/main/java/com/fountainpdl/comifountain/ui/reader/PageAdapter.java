package com.fountainpdl.comifountain.ui.reader;

import android.graphics.*;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.*;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.target.Target;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Page;
import java.util.*;

public class PageAdapter extends RecyclerView.Adapter<PageAdapter.VH> {
    private List<Page> pages = new ArrayList<>();
    private boolean grayscale = false;

    public void setPages(List<Page> p)      { this.pages = p; notifyDataSetChanged(); }
    public void setGrayscale(boolean g)     { this.grayscale = g; notifyDataSetChanged(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_reader_page, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Page page = pages.get(pos);
        h.progress.setVisibility(View.VISIBLE);
        h.error.setVisibility(View.GONE);

        if (grayscale) {
            ColorMatrix cm = new ColorMatrix(); cm.setSaturation(0);
            h.image.setColorFilter(new ColorMatrixColorFilter(cm));
        } else { h.image.clearColorFilter(); }

        Glide.with(h.image.getContext())
            .load(page.isLocal() ? page.localPath : page.url)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .listener(new RequestListener<android.graphics.drawable.Drawable>() {
                @Override public boolean onLoadFailed(@Nullable GlideException e, Object m,
                    Target<android.graphics.drawable.Drawable> t, boolean f) {
                    h.progress.setVisibility(View.GONE); h.error.setVisibility(View.VISIBLE); return false; }
                @Override public boolean onResourceReady(android.graphics.drawable.Drawable r, Object m,
                    Target<android.graphics.drawable.Drawable> t, DataSource d, boolean f) {
                    h.progress.setVisibility(View.GONE); return false; }
            }).into(h.image);
    }

    @Override public int getItemCount() { return pages.size(); }

    static class VH extends RecyclerView.ViewHolder {
        com.github.chrisbanes.photoview.PhotoView image;
        ProgressBar progress; View error;
        VH(View v) { super(v);
            image    = v.findViewById(R.id.page_image);
            progress = v.findViewById(R.id.page_progress);
            error    = v.findViewById(R.id.page_error); }
    }
}
