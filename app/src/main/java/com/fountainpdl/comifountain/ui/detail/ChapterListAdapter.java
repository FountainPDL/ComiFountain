package com.fountainpdl.comifountain.ui.detail;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import java.text.SimpleDateFormat;
import java.util.*;

public class ChapterListAdapter extends ListAdapter<Chapter, ChapterListAdapter.VH> {
    public interface Listener { void onRead(Chapter c); void onDownload(Chapter c); }

    private final Listener listener;
    private static final SimpleDateFormat FMT = new SimpleDateFormat("MMM dd, yyyy", Locale.US);

    public ChapterListAdapter(Listener l) { super(DIFF); this.listener = l; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_chapter, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Chapter c = getItem(pos);
        h.title.setText(c.displayName());
        h.title.setAlpha(c.isRead ? 0.4f : 1.0f);
        h.date.setText(c.date > 0 ? FMT.format(new Date(c.date)) : "");
        h.bookmark.setVisibility(c.bookmarked ? View.VISIBLE : View.GONE);
        h.downloaded.setVisibility(c.isDownloaded() ? View.VISIBLE : View.GONE);
        h.itemView.setOnClickListener(v -> listener.onRead(c));
        h.downloadBtn.setOnClickListener(v -> listener.onDownload(c));
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, date; ImageButton downloadBtn; View bookmark, downloaded;
        VH(View v) { super(v);
            title       = v.findViewById(R.id.chapter_title);
            date        = v.findViewById(R.id.chapter_date);
            downloadBtn = v.findViewById(R.id.chapter_download_btn);
            bookmark    = v.findViewById(R.id.chapter_bookmark_icon);
            downloaded  = v.findViewById(R.id.chapter_download_icon); }
    }

    private static final DiffUtil.ItemCallback<Chapter> DIFF = new DiffUtil.ItemCallback<Chapter>() {
        @Override public boolean areItemsTheSame(@NonNull Chapter a, @NonNull Chapter b) { return a.id.equals(b.id); }
        @Override public boolean areContentsTheSame(@NonNull Chapter a, @NonNull Chapter b) {
            return a.isRead == b.isRead && a.bookmarked == b.bookmarked && a.isDownloaded() == b.isDownloaded(); }
    };
}
