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
import com.bumptech.glide.load.model.GlideUrl;
import com.bumptech.glide.load.model.LazyHeaders;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.target.Target;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Page;
import java.util.*;

/**
 * Adapter for webtoon mode — long vertical strip, no gaps by default.
 */
public class WebtoonAdapter extends RecyclerView.Adapter<WebtoonAdapter.VH> {

    private List<Page> pages = new ArrayList<>();
    private boolean grayscale = false;
    private int gapDp = 0;

    public void setPages(List<Page> p)   { this.pages = p != null ? p : new ArrayList<>(); notifyDataSetChanged(); }
    public void setGrayscale(boolean g)  { this.grayscale = g; notifyDataSetChanged(); }
    public void setGapDp(int dp)         { this.gapDp = dp; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        View v = LayoutInflater.from(p.getContext())
            .inflate(R.layout.item_webtoon_page, p, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Page page = pages.get(pos);
        h.progress.setVisibility(View.VISIBLE);
        h.error.setVisibility(View.GONE);

        // Margin gap between pages
        RecyclerView.LayoutParams lp = (RecyclerView.LayoutParams) h.itemView.getLayoutParams();
        lp.bottomMargin = (int)(gapDp * h.itemView.getContext().getResources().getDisplayMetrics().density);
        h.itemView.setLayoutParams(lp);

        if (grayscale) {
            ColorMatrix cm = new ColorMatrix(); cm.setSaturation(0);
            h.image.setColorFilter(new ColorMatrixColorFilter(cm));
        } else { h.image.clearColorFilter(); }

        String url = page.isLocal() ? page.localPath : page.url;
        if (url == null) { h.progress.setVisibility(View.GONE); return; }

        Object loadTarget = url.startsWith("content://")
            ? android.net.Uri.parse(url)
            : url.startsWith("/")
                ? new java.io.File(url)
                : buildGlideUrl(url);

        Glide.with(h.image.getContext())
            .load(loadTarget)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .listener(new RequestListener<android.graphics.drawable.Drawable>() {
                @Override public boolean onLoadFailed(@Nullable GlideException e,
                    Object m, Target<android.graphics.drawable.Drawable> t, boolean f) {
                    h.progress.setVisibility(View.GONE);
                    h.error.setVisibility(View.VISIBLE);
                    return false;
                }
                @Override public boolean onResourceReady(android.graphics.drawable.Drawable r,
                    Object m, Target<android.graphics.drawable.Drawable> t,
                    DataSource d, boolean f) {
                    h.progress.setVisibility(View.GONE);
                    return false;
                }
            })
            .into(h.image);
    }

    @Override public int getItemCount() { return pages.size(); }

    private GlideUrl buildGlideUrl(String url) {
        LazyHeaders.Builder h = new LazyHeaders.Builder()
            .addHeader("User-Agent", "Mozilla/5.0 (Android)");
        if (url.contains("allanime") || url.contains("wp.allanime"))
            h.addHeader("Referer","https://allmanga.to").addHeader("Origin","https://allmanga.to");
        return new GlideUrl(url, h.build());
    }

    static class VH extends RecyclerView.ViewHolder {
        ImageView image, error; ProgressBar progress;
        VH(View v) { super(v);
            image    = v.findViewById(R.id.webtoon_image);
            progress = v.findViewById(R.id.webtoon_progress);
            error    = v.findViewById(R.id.webtoon_error); }
    }
}
