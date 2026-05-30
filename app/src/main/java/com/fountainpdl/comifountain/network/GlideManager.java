package com.fountainpdl.comifountain.network;

import android.content.Context;
import android.widget.ImageView;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.model.GlideUrl;
import com.bumptech.glide.load.model.LazyHeaders;
import com.fountainpdl.comifountain.R;

/**
 * Centralised image loading — handles per-source headers (e.g. AllManga CDN).
 */
public class GlideManager {

    public static void loadCover(Context context, String url, ImageView into) {
        if (url == null || url.isEmpty()) {
            into.setImageResource(R.drawable.ic_manga_placeholder);
            return;
        }
        GlideUrl glideUrl = buildUrl(url);
        Glide.with(context)
            .load(glideUrl)
            .placeholder(R.drawable.ic_manga_placeholder)
            .error(R.drawable.ic_manga_placeholder)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .centerCrop()
            .into(into);
    }

    public static void loadPage(Context context, String url, ImageView into) {
        GlideUrl glideUrl = buildUrl(url);
        Glide.with(context)
            .load(glideUrl)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .fitCenter()
            .into(into);
    }

    /** Attach appropriate headers depending on URL origin. */
    private static GlideUrl buildUrl(String url) {
        LazyHeaders.Builder headers = new LazyHeaders.Builder()
            .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36");

        if (url.contains("allanime") || url.contains("wp.allanime")
                || url.contains("cdnjs") || url.contains("allanimecdn")) {
            headers.addHeader("Referer", "https://allmanga.to")
                   .addHeader("Origin",  "https://allmanga.to");
        } else if (url.contains("mangapuma")) {
            headers.addHeader("Referer", "https://mangapuma.com");
        } else if (url.contains("ravenscans")) {
            headers.addHeader("Referer", "https://ravenscans.com");
        }
        return new GlideUrl(url, headers.build());
    }
}
