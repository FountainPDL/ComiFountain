package com.fountainpdl.comifountain.ui.sources;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.sources.Source;
import java.util.List;

public class ExtensionAdapter extends RecyclerView.Adapter<ExtensionAdapter.VH> {

    public interface Listener {
        void onEdit(Source s);
        void onDelete(Source s);
        void onToggle(Source s, boolean enabled);
    }

    private final List<Source> sources;
    private final Listener listener;

    public ExtensionAdapter(List<Source> sources, Listener listener) {
        this.sources = sources; this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext())
            .inflate(R.layout.item_extension_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Source s = sources.get(pos);
        h.name.setText(s.getName());
        h.url.setText(s.getBaseUrl());
        h.editBtn.setOnClickListener(v -> listener.onEdit(s));
        h.deleteBtn.setOnClickListener(v -> listener.onDelete(s));
    }

    @Override public int getItemCount() { return sources.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView name, url; ImageButton editBtn, deleteBtn;
        VH(View v) {
            super(v);
            name      = v.findViewById(R.id.ext_name);
            url       = v.findViewById(R.id.ext_url);
            editBtn   = v.findViewById(R.id.ext_edit_btn);
            deleteBtn = v.findViewById(R.id.ext_delete_btn);
        }
    }
}
