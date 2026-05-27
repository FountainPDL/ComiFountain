package com.fountainpdl.comifountain.ui.sources;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.sources.Source;
import java.util.List;

public class SourceCardAdapter extends RecyclerView.Adapter<SourceCardAdapter.VH> {
    public interface OnBrowse { void onBrowse(Source s); }
    private final List<Source> sources;
    private final OnBrowse listener;

    public SourceCardAdapter(List<Source> sources, OnBrowse listener) {
        this.sources = sources; this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_source_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Source s = sources.get(pos);
        h.name.setText(s.getName());
        h.lang.setText(s.getLang().toUpperCase());
        h.icon.setImageResource(s.getIconResId());
        h.browseBtn.setOnClickListener(v -> listener.onBrowse(s));
    }

    @Override public int getItemCount() { return sources.size(); }

    static class VH extends RecyclerView.ViewHolder {
        ImageView icon; TextView name, lang; Button browseBtn;
        VH(View v) { super(v);
            icon      = v.findViewById(R.id.source_icon);
            name      = v.findViewById(R.id.source_name);
            lang      = v.findViewById(R.id.source_lang);
            browseBtn = v.findViewById(R.id.source_browse_btn); }
    }
}
