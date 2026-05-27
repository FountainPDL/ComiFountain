package com.fountainpdl.comifountain.ui.updates;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.databinding.FragmentUpdatesBinding;
import com.fountainpdl.comifountain.ui.library.*;

public class UpdatesFragment extends Fragment {

    private FragmentUpdatesBinding binding;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentUpdatesBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        LibraryViewModel vm = new ViewModelProvider(this).get(LibraryViewModel.class);
        MangaGridAdapter adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(com.fountainpdl.comifountain.data.model.Manga m) {}
            @Override public void onLongClick(com.fountainpdl.comifountain.data.model.Manga m) {}
        });
        binding.updatesRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.updatesRecycler.setAdapter(adapter);
        vm.getMangaWithUpdates().observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
            binding.emptyUpdates.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
