package com.fountainpdl.comifountain.ui.detail;

import android.os.Bundle;
import android.text.Html;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.databinding.FragmentMangaDetailBinding;
import com.fountainpdl.comifountain.network.GlideManager;
import com.fountainpdl.comifountain.ui.reader.ReaderFragment;

public class MangaDetailFragment extends Fragment {

    private static final String ARG = "manga_id";
    private FragmentMangaDetailBinding binding;
    private MangaDetailViewModel vm;
    private ChapterListAdapter adapter;
    private String mangaId;

    public static MangaDetailFragment newInstance(String id) {
        MangaDetailFragment f = new MangaDetailFragment();
        Bundle b = new Bundle(); b.putString(ARG, id); f.setArguments(b);
        return f;
    }

    @Override public void onCreate(@Nullable Bundle s) {
        super.onCreate(s);
        mangaId = getArguments() != null ? getArguments().getString(ARG) : "";
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentMangaDetailBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        vm = new ViewModelProvider(this).get(MangaDetailViewModel.class);

        binding.detailBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());
        binding.libraryBtn.setOnClickListener(v -> {
            vm.toggleLibrary(mangaId);
        });

        // Expand/collapse description
        binding.detailDescription.setOnClickListener(v -> {
            if (binding.detailDescription.getMaxLines() == 4) {
                binding.detailDescription.setMaxLines(Integer.MAX_VALUE);
            } else {
                binding.detailDescription.setMaxLines(4);
            }
        });

        adapter = new ChapterListAdapter(new ChapterListAdapter.Listener() {
            @Override public void onRead(Chapter c)     { openReader(c); }
            @Override public void onDownload(Chapter c) { /* TODO */ }
        });
        binding.chapterRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.chapterRecycler.setAdapter(adapter);
        binding.chapterRecycler.setNestedScrollingEnabled(false);

        vm.manga.observe(getViewLifecycleOwner(), m -> {
            if (m == null) return;
            binding.detailTitle.setText(m.title);
            binding.detailAuthor.setText(m.author != null && !m.author.isEmpty()
                ? m.author : "Unknown");
            binding.detailStatus.setText(m.status != null
                ? capitalize(m.status) : "");
            // Decode HTML entities in description
            if (m.description != null && !m.description.isEmpty()) {
                binding.detailDescription.setText(
                    Html.fromHtml(m.description, Html.FROM_HTML_MODE_COMPACT));
            }
            // Load cover with proper headers
            GlideManager.loadCover(requireContext(), m.cover, binding.detailCover);
        });

        vm.chapters.observe(getViewLifecycleOwner(), list -> {
            if (list == null) return;
            adapter.submitList(list);
            binding.chapterCount.setText(list.size() + " chapters");
            binding.emptyChapters.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
        });

        vm.inLibrary.observe(getViewLifecycleOwner(), lib ->
            binding.libraryBtn.setText(Boolean.TRUE.equals(lib)
                ? "✓ In Library" : "Add to Library"));

        vm.state.observe(getViewLifecycleOwner(), s -> {
            binding.detailProgress.setVisibility(
                s == MangaDetailViewModel.State.LOADING ? View.VISIBLE : View.GONE);
            if (s == MangaDetailViewModel.State.ERROR && vm.error.getValue() != null) {
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .showLong(requireContext(), "Error: " + vm.error.getValue());
            }
        });

        vm.load(mangaId);
    }

    private void openReader(Chapter chapter) {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                ReaderFragment.newInstance(mangaId, chapter.id), "reader_" + chapter.id);
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
