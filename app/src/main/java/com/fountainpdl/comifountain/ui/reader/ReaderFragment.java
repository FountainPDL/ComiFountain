package com.fountainpdl.comifountain.ui.reader;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.viewpager2.widget.ViewPager2;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.databinding.FragmentReaderBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;

public class ReaderFragment extends Fragment {

    private static final String ARG_MANGA   = "manga_id";
    private static final String ARG_CHAPTER = "chapter_id";

    private FragmentReaderBinding binding;
    private ReaderViewModel vm;
    private PageAdapter adapter;
    private boolean barsVisible = true;
    private String mangaId, chapterId;

    public static ReaderFragment newInstance(String mangaId, String chapterId) {
        ReaderFragment f = new ReaderFragment();
        Bundle b = new Bundle();
        b.putString(ARG_MANGA, mangaId);
        b.putString(ARG_CHAPTER, chapterId);
        f.setArguments(b);
        return f;
    }

    @Override public void onCreate(@Nullable Bundle s) {
        super.onCreate(s);
        if (getArguments() != null) {
            mangaId   = getArguments().getString(ARG_MANGA);
            chapterId = getArguments().getString(ARG_CHAPTER);
        }
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentReaderBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        vm = new ViewModelProvider(this).get(ReaderViewModel.class);
        AppPreferences prefs = AppPreferences.getInstance(requireContext());

        if (prefs.isKeepScreen())
            requireActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).hideSystemBars();

        adapter = new PageAdapter();
        adapter.setGrayscale(prefs.isGrayscale());

        String mode = prefs.getReadingMode();
        binding.readerPager.setOrientation(
            ("vertical".equals(mode) || "webtoon".equals(mode))
                ? ViewPager2.ORIENTATION_VERTICAL
                : ViewPager2.ORIENTATION_HORIZONTAL);
        if ("rtl".equals(mode))
            binding.readerPager.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        binding.readerPager.setAdapter(adapter);
        binding.readerPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override public void onPageSelected(int pos) {
                vm.updatePage(pos);
                int total = vm.getTotalPages();
                binding.pageIndicator.setText((pos + 1) + " / " + total);
                if (total > 1) binding.pageSlider.setValue(pos);
            }
        });

        binding.pageSlider.addOnChangeListener((s2, val, fromUser) -> {
            if (fromUser) binding.readerPager.setCurrentItem((int) val, false);
        });

        binding.readerPager.setOnClickListener(v -> toggleBars());
        binding.readerBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());

        vm.pages.observe(getViewLifecycleOwner(), p -> {
            adapter.setPages(p);
            if (!p.isEmpty()) {
                binding.pageSlider.setValueFrom(0);
                binding.pageSlider.setValueTo(Math.max(1, p.size() - 1));
                binding.pageSlider.setValue(0);
                binding.pageIndicator.setText("1 / " + p.size());
            }
        });
        vm.loading.observe(getViewLifecycleOwner(), l ->
            binding.readerProgress.setVisibility(Boolean.TRUE.equals(l) ? View.VISIBLE : View.GONE));

        vm.load(mangaId, chapterId);
    }

    private void toggleBars() {
        barsVisible = !barsVisible;
        int vis = barsVisible ? View.VISIBLE : View.GONE;
        binding.readerTopBar.setVisibility(vis);
        binding.readerBottomBar.setVisibility(vis);
    }

    @Override
    public void onPause() {
        super.onPause();
        if (getActivity() instanceof MainActivity) ((MainActivity) getActivity()).showSystemBars();
        requireActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
