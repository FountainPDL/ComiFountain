package com.fountainpdl.comifountain.ui.search;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.appcompat.widget.SearchView;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentSearchBinding;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;
import com.fountainpdl.comifountain.ui.library.MangaGridAdapter;
import java.util.List;

public class SearchFragment extends Fragment {

    private FragmentSearchBinding binding;
    private SearchViewModel viewModel;
    private MangaGridAdapter adapter;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSearchBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        // Use activity scope so state survives tab switches
        viewModel = new ViewModelProvider(requireActivity()).get(SearchViewModel.class);

        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) {}
        });
        binding.searchRecycler.setLayoutManager(new GridLayoutManager(requireContext(), 2));
        binding.searchRecycler.setAdapter(adapter);

        setupSourcePicker();

        binding.searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override public boolean onQueryTextSubmit(String q) {
                viewModel.search(q, 1);
                return true;
            }
            @Override public boolean onQueryTextChange(String t) {
                if (t.isEmpty()) viewModel.search("", 1);
                return false;
            }
        });

        // Restore existing query in SearchView
        String existing = viewModel.getCurrentQuery();
        if (!existing.isEmpty()) binding.searchView.setQuery(existing, false);

        viewModel.state.observe(getViewLifecycleOwner(), s -> {
            binding.progressBar.setVisibility(
                s == SearchViewModel.State.LOADING ? View.VISIBLE : View.GONE);
            binding.emptySearch.setVisibility(
                s == SearchViewModel.State.RESULTS
                && (viewModel.results.getValue() == null
                    || viewModel.results.getValue().isEmpty())
                    ? View.VISIBLE : View.GONE);
        });

        viewModel.results.observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
        });

        viewModel.errorMsg.observe(getViewLifecycleOwner(), err -> {
            if (err != null && !err.isEmpty())
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .showLong(requireContext(), "Error: " + err);
        });

        // Browse featured if no prior state
        if (viewModel.results.getValue() == null || viewModel.results.getValue().isEmpty()) {
            viewModel.search("", 1);
        }
    }

    private void setupSourcePicker() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        String[] names = sources.stream().map(Source::getName).toArray(String[]::new);

        // Show current source name
        updateSourceLabel(sources);

        binding.sourcePickerBtn.setOnClickListener(v ->
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Select Source")
                .setItems(names, (d, which) -> {
                    viewModel.setSource(sources.get(which).getId());
                    updateSourceLabel(sources);
                }).show());
    }

    private void updateSourceLabel(List<Source> sources) {
        String id = viewModel.sourceId.getValue();
        for (Source s : sources) {
            if (s.getId().equals(id)) {
                binding.sourcePickerBtn.setText(s.getName());
                return;
            }
        }
        if (!sources.isEmpty()) binding.sourcePickerBtn.setText(sources.get(0).getName());
    }

    private void openDetail(Manga manga) {
        ((ComiFountainApp) requireActivity().getApplication()).getRepository().saveManga(manga);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
