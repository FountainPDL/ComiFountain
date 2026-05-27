package com.fountainpdl.comifountain.ui.library;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;

public class MangaGridAdapter extends ListAdapter<Manga, MangaGridAdapter.VH> {

    public interface Listener {
        void onClick(Manga m);
        void onLongClick(Manga m);
    }

    private final Listener listener;

    public MangaGridAdapter(Listener listener) {
        super(DIFF);
        this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_manga_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Manga m = getItem(pos);
        h.title.setText(m.title);
        h.badge.setVisibility(m.unreadCount > 0 ? View.VISIBLE : View.GONE);
        if (m.unreadCount > 0) h.badge.setText(String.valueOf(m.unreadCount));
        Glide.with(h.cover).load(m.cover)
            .placeholder(R.drawable.ic_manga_placeholder)
            .diskCacheStrategy(DiskCacheStrategy.ALL).centerCrop().into(h.cover);
        h.itemView.setOnClickListener(v -> listener.onClick(m));
        h.itemView.setOnLongClickListener(v -> { listener.onLongClick(m); return true; });
    }

    static class VH extends RecyclerView.ViewHolder {
        ImageView cover; TextView title, badge;
        VH(View v) { super(v);
            cover = v.findViewById(R.id.manga_cover);
            title = v.findViewById(R.id.manga_title);
            badge = v.findViewById(R.id.manga_unread_badge); }
    }

    private static final DiffUtil.ItemCallback<Manga> DIFF = new DiffUtil.ItemCallback<Manga>() {
        @Override public boolean areItemsTheSame(@NonNull Manga a, @NonNull Manga b) { return a.id.equals(b.id); }
        @Override public boolean areContentsTheSame(@NonNull Manga a, @NonNull Manga b) {
            return a.title.equals(b.title) && a.unreadCount == b.unreadCount
                && java.util.Objects.equals(a.cover, b.cover); }
    };
}
