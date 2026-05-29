package com.fountainpdl.comifountain.ui.history;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.*;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.HistoryEntry;
import com.fountainpdl.comifountain.databinding.FragmentHistoryBinding;
import java.text.SimpleDateFormat;
import java.util.*;

public class HistoryFragment extends Fragment {

    private FragmentHistoryBinding binding;
    private MangaRepository repo;

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentHistoryBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        repo = ((ComiFountainApp) requireActivity().getApplication()).getRepository();

        binding.clearHistoryBtn.setOnClickListener(v ->
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Clear History?")
                .setMessage("This will remove all reading history.")
                .setPositiveButton("Clear", (d, w) -> repo.clearHistory())
                .setNegativeButton("Cancel", null)
                .show()
        );

        repo.getRecentHistory().observe(getViewLifecycleOwner(), entries -> {
            if (entries == null || entries.isEmpty()) {
                binding.historyEmpty.setVisibility(View.VISIBLE);
                binding.historyRecycler.setVisibility(View.GONE);
                return;
            }
            binding.historyEmpty.setVisibility(View.GONE);
            binding.historyRecycler.setVisibility(View.VISIBLE);
            binding.historyRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
            binding.historyRecycler.setAdapter(new HistoryAdapter(entries));
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
