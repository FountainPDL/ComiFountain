package com.fountainpdl.comifountain.ui.reader;

import android.os.Bundle;
import android.view.*;
import android.view.GestureDetector;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.ViewPager2;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.databinding.FragmentReaderBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;

public class ReaderFragment extends Fragment {

    private static final String ARG_MANGA   = "manga_id";
    private static final String ARG_CHAPTER = "chapter_id";

    private FragmentReaderBinding binding;
    private ReaderViewModel vm;
    private PageAdapter    pagerAdapter;
    private WebtoonAdapter webtoonAdapter;
    private boolean barsVisible = false; // start hidden
    private boolean isWebtoon   = false;
    private String  mangaId, chapterId;

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
            requireActivity().getWindow().addFlags(
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).hideSystemBars();

        String mode = prefs.getReadingMode();
        isWebtoon   = "webtoon".equals(mode) || "vertical-gaps".equals(mode);
        int gapDp   = "vertical-gaps".equals(mode) ? 8 : 0;

        if (isWebtoon) {
            setupWebtoon(prefs, gapDp);
        } else {
            setupPager(prefs, mode);
        }

        setupControls();
        observeViewModel();

        vm.load(mangaId, chapterId);
    }

    private void setupPager(AppPreferences prefs, String mode) {
        binding.readerPager.setVisibility(View.VISIBLE);
        binding.webtoonRecycler.setVisibility(View.GONE);

        pagerAdapter = new PageAdapter();
        pagerAdapter.setGrayscale(prefs.isGrayscale());

        boolean vertical = "vertical".equals(mode);
        binding.readerPager.setOrientation(vertical
            ? ViewPager2.ORIENTATION_VERTICAL
            : ViewPager2.ORIENTATION_HORIZONTAL);
        if ("rtl".equals(mode))
            binding.readerPager.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        binding.readerPager.setAdapter(pagerAdapter);
        binding.readerPager.registerOnPageChangeCallback(
            new ViewPager2.OnPageChangeCallback() {
                @Override public void onPageSelected(int pos) {
                    vm.updatePage(pos);
                    updatePageIndicator(pos + 1, vm.getTotalPages());
                }
                @Override public void onPageScrollStateChanged(int state) {
                    if (state == ViewPager2.SCROLL_STATE_DRAGGING && barsVisible)
                        hideBars();
                }
            });

        binding.pageSlider.addOnChangeListener((s, val, fromUser) -> {
            if (fromUser) binding.readerPager.setCurrentItem((int) val, false);
        });

        // Tap to toggle
        GestureDetector gd = new GestureDetector(requireContext(),
            new GestureDetector.SimpleOnGestureListener() {
                @Override public boolean onSingleTapConfirmed(android.view.MotionEvent e) {
                    toggleBars(); return true;
                }
            });
        binding.readerPager.setOnTouchListener((v, e) -> { gd.onTouchEvent(e); return false; });
    }

    private void setupWebtoon(AppPreferences prefs, int gapDp) {
        binding.readerPager.setVisibility(View.GONE);
        binding.webtoonRecycler.setVisibility(View.VISIBLE);

        webtoonAdapter = new WebtoonAdapter();
        webtoonAdapter.setGrayscale(prefs.isGrayscale());
        webtoonAdapter.setGapDp(gapDp);

        LinearLayoutManager llm = new LinearLayoutManager(requireContext());
        binding.webtoonRecycler.setLayoutManager(llm);
        binding.webtoonRecycler.setAdapter(webtoonAdapter);

        // Update page indicator while scrolling
        binding.webtoonRecycler.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override public void onScrolled(@NonNull RecyclerView rv, int dx, int dy) {
                int pos = llm.findFirstVisibleItemPosition();
                if (pos >= 0) {
                    vm.updatePage(pos);
                    updatePageIndicator(pos + 1, vm.getTotalPages());
                }
                // Hide controls when scrolling
                if (Math.abs(dy) > 8 && barsVisible) hideBars();
            }
        });

        // Tap to toggle
        GestureDetector gd = new GestureDetector(requireContext(),
            new GestureDetector.SimpleOnGestureListener() {
                @Override public boolean onSingleTapConfirmed(android.view.MotionEvent e) {
                    toggleBars(); return true;
                }
            });
        binding.webtoonRecycler.setOnTouchListener((v, e) -> { gd.onTouchEvent(e); return false; });
    }

    private void setupControls() {
        binding.readerBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());
        binding.pageSlider.addOnChangeListener((s, val, fromUser) -> {
            if (!fromUser) return;
            if (isWebtoon) {
                binding.webtoonRecycler.scrollToPosition((int) val);
            } else {
                binding.readerPager.setCurrentItem((int) val, false);
            }
        });
    }

    private void observeViewModel() {
        vm.pages.observe(getViewLifecycleOwner(), pages -> {
            if (pages == null || pages.isEmpty()) return;
            int total = pages.size();
            binding.pageSlider.setValueFrom(0);
            binding.pageSlider.setValueTo(Math.max(1, total - 1));
            binding.pageSlider.setValue(0);
            updatePageIndicator(1, total);

            if (isWebtoon) {
                webtoonAdapter.setPages(pages);
            } else {
                pagerAdapter.setPages(pages);
            }
        });

        vm.loading.observe(getViewLifecycleOwner(), loading ->
            binding.readerProgress.setVisibility(
                Boolean.TRUE.equals(loading) ? View.VISIBLE : View.GONE));

        vm.error.observe(getViewLifecycleOwner(), err -> {
            if (err != null && !err.isEmpty())
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .showLong(requireContext(), err);
        });
    }

    private void updatePageIndicator(int current, int total) {
        binding.pageIndicator.setText(current + " / " + total);
    }

    private void toggleBars() {
        if (barsVisible) hideBars(); else showBars();
    }

    private void hideBars() {
        barsVisible = false;
        binding.readerTopBar.animate().alpha(0).setDuration(180)
            .withEndAction(() -> binding.readerTopBar.setVisibility(View.GONE)).start();
        binding.readerBottomBar.animate().alpha(0).setDuration(180)
            .withEndAction(() -> binding.readerBottomBar.setVisibility(View.GONE)).start();
    }

    private void showBars() {
        barsVisible = true;
        binding.readerTopBar.setVisibility(View.VISIBLE);
        binding.readerTopBar.animate().alpha(1).setDuration(180).start();
        binding.readerBottomBar.setVisibility(View.VISIBLE);
        binding.readerBottomBar.animate().alpha(1).setDuration(180).start();
    }

    @Override
    public void onPause() {
        super.onPause();
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).showSystemBars();
        requireActivity().getWindow().clearFlags(
            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
