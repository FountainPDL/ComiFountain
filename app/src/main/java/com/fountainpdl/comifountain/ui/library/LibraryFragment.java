package com.fountainpdl.comifountain.ui.library;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentLibraryBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;

public class LibraryFragment extends Fragment {

    private FragmentLibraryBinding binding;
    private LibraryViewModel viewModel;
    private MangaGridAdapter adapter;
    private AppPreferences prefs;
    private boolean isGrid = true;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentLibraryBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs     = AppPreferences.getInstance(requireContext());
        viewModel = new ViewModelProvider(this).get(LibraryViewModel.class);
        isGrid    = "grid".equals(prefs.getLibDisplay());

        setupAdapter();
        setupToggles();

        binding.swipeRefresh.setOnRefreshListener(() -> binding.swipeRefresh.setRefreshing(false));
        binding.searchLibrary.addTextChangedListener(new android.text.TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int st, int c, int a) {}
            @Override public void onTextChanged(CharSequence s, int st, int b, int c) {
                adapter.filter(s.toString());
            }
            @Override public void afterTextChanged(android.text.Editable s) {}
        });

        viewModel.getLibraryManga().observe(getViewLifecycleOwner(), list -> {
            adapter.setFullList(list);
            binding.emptyState.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
            binding.libraryCount.setText(list.size() + " manga");
            binding.swipeRefresh.setRefreshing(false);
        });
    }

    private void setupAdapter() {
        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) { showOptions(m); }
        });
        applyLayout();
        binding.libraryRecycler.setAdapter(adapter);
        binding.libraryRecycler.setHasFixedSize(true);
    }

    private void applyLayout() {
        int cols = prefs.getLibraryCols();
        if (isGrid) {
            binding.libraryRecycler.setLayoutManager(new GridLayoutManager(requireContext(), cols));
        } else {
            binding.libraryRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        }
        adapter.setDisplayMode(isGrid, prefs.isLibCompact());
    }

    private void setupToggles() {
        binding.toggleGrid.setOnClickListener(v -> {
            isGrid = true;
            prefs.setLibDisplay("grid");
            applyLayout();
        });
        binding.toggleList.setOnClickListener(v -> {
            isGrid = false;
            prefs.setLibDisplay("list");
            applyLayout();
        });
    }

    private void openDetail(Manga manga) {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    private void showOptions(Manga manga) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle(manga.title)
            .setItems(new String[]{
                "Remove from library", "Mark all read",
                "Mark all unread", "Move to category"
            }, (d, which) -> {
                switch (which) {
                    case 0: viewModel.removeFromLibrary(manga.id); break;
                    case 1: viewModel.markAllRead(manga.id);      break;
                    case 2: viewModel.markAllUnread(manga.id);    break;
                    case 3: showCategoryPicker(manga);            break;
                }
            }).show();
    }

    private void showCategoryPicker(Manga manga) {
        viewModel.getCategories().observe(getViewLifecycleOwner(), cats -> {
            if (cats == null || cats.isEmpty()) {
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .show(requireContext(), "No categories yet. Create one in Settings.");
                return;
            }
            String[] names = cats.stream()
                .map(c -> c.name).toArray(String[]::new);
            boolean[] checked = new boolean[cats.size()];
            // Pre-check existing
            if (manga.categories != null) {
                for (int i = 0; i < cats.size(); i++) {
                    checked[i] = manga.categories.contains(cats.get(i).name);
                }
            }
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Move to Category")
                .setMultiChoiceItems(names, checked, (d, which, isChecked) -> checked[which] = isChecked)
                .setPositiveButton("Apply", (d, w) -> {
                    java.util.List<String> selected = new java.util.ArrayList<>();
                    for (int i = 0; i < cats.size(); i++) if (checked[i]) selected.add(cats.get(i).name);
                    viewModel.updateCategories(manga.id, selected);
                })
                .setNegativeButton("Cancel", null)
                .show();
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
