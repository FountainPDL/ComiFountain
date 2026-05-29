package com.fountainpdl.comifountain.ui.library;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;
import java.util.*;

public class MangaGridAdapter extends RecyclerView.Adapter<MangaGridAdapter.VH> {

    public interface Listener {
        void onClick(Manga m);
        void onLongClick(Manga m);
    }

    private static final int VIEW_GRID    = 0;
    private static final int VIEW_LIST    = 1;
    private static final int VIEW_COMPACT = 2;

    private final Listener listener;
    private List<Manga> fullList    = new ArrayList<>();
    private List<Manga> displayList = new ArrayList<>();
    private int viewType = VIEW_GRID;

    public MangaGridAdapter(Listener listener) { this.listener = listener; }

    public void setFullList(List<Manga> list) {
        fullList = list != null ? list : new ArrayList<>();
        displayList = new ArrayList<>(fullList);
        notifyDataSetChanged();
    }

    public void submitList(List<Manga> list) { setFullList(list); }

    public void filter(String query) {
        if (query == null || query.isEmpty()) {
            displayList = new ArrayList<>(fullList);
        } else {
            String q = query.toLowerCase();
            displayList = new ArrayList<>();
            for (Manga m : fullList) {
                if (m.title != null && m.title.toLowerCase().contains(q)) displayList.add(m);
            }
        }
        notifyDataSetChanged();
    }

    public void setDisplayMode(boolean grid, boolean compact) {
        viewType = compact ? VIEW_COMPACT : grid ? VIEW_GRID : VIEW_LIST;
        notifyDataSetChanged();
    }

    @Override public int getItemViewType(int pos) { return viewType; }
    @Override public int getItemCount() { return displayList.size(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int type) {
        int layout = type == VIEW_LIST ? R.layout.item_manga_list
                   : type == VIEW_COMPACT ? R.layout.item_manga_compact
                   : R.layout.item_manga_card;
        return new VH(LayoutInflater.from(p.getContext()).inflate(layout, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Manga m = displayList.get(pos);
        if (h.title != null) h.title.setText(m.title);
        if (h.badge != null) {
            h.badge.setVisibility(m.unreadCount > 0 ? View.VISIBLE : View.GONE);
            if (m.unreadCount > 0) h.badge.setText(String.valueOf(m.unreadCount));
        }
        if (h.sourceName != null) h.sourceName.setText(m.sourceName);
        if (h.status != null) h.status.setText(m.status != null ? m.status : "");

        if (h.cover != null) {
            Glide.with(h.cover).load(m.cover)
                .placeholder(R.drawable.ic_manga_placeholder)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .centerCrop().into(h.cover);
        }
        h.itemView.setOnClickListener(v -> listener.onClick(m));
        h.itemView.setOnLongClickListener(v -> { listener.onLongClick(m); return true; });
    }

    static class VH extends RecyclerView.ViewHolder {
        ImageView cover; TextView title, badge, sourceName, status;
        VH(View v) {
            super(v);
            cover      = v.findViewById(R.id.manga_cover);
            title      = v.findViewById(R.id.manga_title);
            badge      = v.findViewById(R.id.manga_unread_badge);
            sourceName = v.findViewById(R.id.manga_source);
            status     = v.findViewById(R.id.manga_status);
        }
    }
}
