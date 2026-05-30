package com.fountainpdl.comifountain.ui.sources;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.appcompat.widget.SearchView;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.*;
import androidx.recyclerview.widget.GridLayoutManager;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentSourceBrowseBinding;
import com.fountainpdl.comifountain.sources.Source;
import com.fountainpdl.comifountain.sources.SourceManager;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;
import com.fountainpdl.comifountain.ui.library.MangaGridAdapter;
import java.util.*;
import java.util.concurrent.*;

public class SourceBrowseFragment extends Fragment {

    private static final String ARG_SOURCE = "source_id";
    private FragmentSourceBrowseBinding binding;
    private MangaGridAdapter adapter;
    private String sourceId;
    private int currentPage = 1;
    private boolean isLoading = false;

    private final MutableLiveData<List<Manga>> results = new MutableLiveData<>(new ArrayList<>());
    private final ExecutorService exec = Executors.newSingleThreadExecutor();

    public static SourceBrowseFragment newInstance(String sourceId) {
        SourceBrowseFragment f = new SourceBrowseFragment();
        Bundle b = new Bundle(); b.putString(ARG_SOURCE, sourceId); f.setArguments(b);
        return f;
    }

    @Override public void onCreate(@Nullable Bundle s) {
        super.onCreate(s);
        sourceId = getArguments() != null ? getArguments().getString(ARG_SOURCE) : "";
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSourceBrowseBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        Source source = SourceManager.getInstance(requireContext()).getById(sourceId);
        String name = source != null ? source.getName() : sourceId;
        binding.browseTitle.setText(name);
        binding.browseBack.setOnClickListener(v -> requireActivity().onBackPressed());

        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) {}
        });
        binding.browseRecycler.setLayoutManager(new GridLayoutManager(requireContext(), 2));
        binding.browseRecycler.setAdapter(adapter);

        // Search within source
        binding.browseSearch.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override public boolean onQueryTextSubmit(String q) {
                loadSource(q, 1, true); return true;
            }
            @Override public boolean onQueryTextChange(String t) {
                if (t.isEmpty()) loadSource("", 1, true);
                return false;
            }
        });

        // Load more on scroll
        binding.browseRecycler.addOnScrollListener(new androidx.recyclerview.widget.RecyclerView.OnScrollListener() {
            @Override public void onScrolled(@NonNull androidx.recyclerview.widget.RecyclerView rv, int dx, int dy) {
                androidx.recyclerview.widget.GridLayoutManager lm =
                    (androidx.recyclerview.widget.GridLayoutManager) rv.getLayoutManager();
                if (lm != null && !isLoading) {
                    int last    = lm.findLastVisibleItemPosition();
                    int total   = lm.getItemCount();
                    if (last >= total - 4) {
                        loadSource(binding.browseSearch.getQuery().toString(), ++currentPage, false);
                    }
                }
            }
        });

        results.observe(getViewLifecycleOwner(), list -> adapter.setFullList(list));

        // Initial browse
        loadSource("", 1, true);
    }

    private void loadSource(String query, int page, boolean reset) {
        if (isLoading) return;
        isLoading = true;
        binding.browseProgress.setVisibility(View.VISIBLE);

        exec.execute(() -> {
            try {
                Source src = SourceManager.getInstance(requireContext()).getById(sourceId);
                if (src == null) return;
                List<Manga> found = (query == null || query.isEmpty())
                    ? src.browse(page) : src.search(query, page);

                requireActivity().runOnUiThread(() -> {
                    List<Manga> current = results.getValue();
                    if (reset || current == null) {
                        results.setValue(found);
                    } else {
                        List<Manga> combined = new ArrayList<>(current);
                        combined.addAll(found);
                        results.setValue(combined);
                    }
                    binding.browseProgress.setVisibility(View.GONE);
                    isLoading = false;
                });
            } catch (Exception e) {
                requireActivity().runOnUiThread(() -> {
                    binding.browseProgress.setVisibility(View.GONE);
                    isLoading = false;
                    com.fountainpdl.comifountain.ui.common.ToastManager
                        .showLong(requireContext(), "Failed: " + e.getMessage());
                });
            }
        });
    }

    private void openDetail(Manga manga) {
        ((ComiFountainApp) requireActivity().getApplication()).getRepository().saveManga(manga);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
