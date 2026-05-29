package com.fountainpdl.comifountain.ui.history;

import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.HistoryEntry;
import java.text.SimpleDateFormat;
import java.util.*;

public class HistoryAdapter extends RecyclerView.Adapter<HistoryAdapter.VH> {
    private final List<HistoryEntry> entries;
    private static final SimpleDateFormat FMT = new SimpleDateFormat("MMM dd, yyyy  HH:mm", Locale.US);

    public HistoryAdapter(List<HistoryEntry> entries) { this.entries = entries; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_history, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        HistoryEntry e = entries.get(pos);
        h.mangaId.setText(e.mangaId);
        h.chapterId.setText(e.chapterId);
        h.readAt.setText(FMT.format(new Date(e.readAt)));
    }

    @Override public int getItemCount() { return entries.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView mangaId, chapterId, readAt;
        VH(View v) {
            super(v);
            mangaId   = v.findViewById(R.id.history_manga);
            chapterId = v.findViewById(R.id.history_chapter);
            readAt    = v.findViewById(R.id.history_date);
        }
    }
}
