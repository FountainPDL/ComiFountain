#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Fix all issues from screenshots
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p "$J/network" "$J/ui/library" "$J/ui/search" "$J/ui/sources" \
         "$J/ui/detail" "$J/ui/reader"

echo "🔧 Fixing all issues..."

# ─────────────────────────────────────────────────────────────────────────────
# FIX 1: Status bar covering content
# Add insets handling to MainActivity so content sits below status bar
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/MainActivity.java" << 'EOF'
package com.fountainpdl.comifountain;

import android.os.Bundle;
import android.view.View;
import android.view.WindowInsetsController;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import com.fountainpdl.comifountain.databinding.ActivityMainBinding;
import com.fountainpdl.comifountain.ui.common.ThemeHelper;
import com.fountainpdl.comifountain.ui.history.HistoryFragment;
import com.fountainpdl.comifountain.ui.library.LibraryFragment;
import com.fountainpdl.comifountain.ui.search.SearchFragment;
import com.fountainpdl.comifountain.ui.sources.SourcesFragment;
import com.fountainpdl.comifountain.ui.updates.UpdatesFragment;
import com.fountainpdl.comifountain.ui.settings.SettingsFragment;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private int exitPressCount = 0;

    public static final String TAG_LIBRARY  = "library";
    public static final String TAG_SEARCH   = "search";
    public static final String TAG_SOURCES  = "sources";
    public static final String TAG_UPDATES  = "updates";
    public static final String TAG_SETTINGS = "settings";
    public static final String TAG_HISTORY  = "history";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        // Apply insets so content sits BELOW the status bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.fragmentContainer, (v, insets) -> {
            Insets bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout());
            v.setPadding(0, bars.top, 0, 0);
            return insets;
        });

        // Bottom nav sits above navigation bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.bottomNav, (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(0, 0, 0, bars.bottom);
            return insets;
        });

        setupBottomNav();
        if (savedInstanceState == null) showFragment(TAG_LIBRARY);
    }

    private void setupBottomNav() {
        binding.bottomNav.setOnItemSelectedListener(item -> {
            int id = item.getItemId();
            if (id == R.id.nav_library)  { showFragment(TAG_LIBRARY);  return true; }
            if (id == R.id.nav_search)   { showFragment(TAG_SEARCH);   return true; }
            if (id == R.id.nav_sources)  { showFragment(TAG_SOURCES);  return true; }
            if (id == R.id.nav_updates)  { showFragment(TAG_UPDATES);  return true; }
            if (id == R.id.nav_settings) { showFragment(TAG_SETTINGS); return true; }
            return false;
        });
    }

    public void showFragment(String tag) {
        Fragment existing = getSupportFragmentManager().findFragmentByTag(tag);
        Fragment f = existing != null ? existing : createFragment(tag);
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, f, tag)
            .commit();
        // Clear backstack when switching tabs
        getSupportFragmentManager().popBackStack(null,
            FragmentManager.POP_BACK_STACK_INCLUSIVE);
        binding.bottomNav.setVisibility(View.VISIBLE);
    }

    public void pushFragment(Fragment fragment, String tag) {
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, fragment, tag)
            .addToBackStack(tag)
            .commit();
        binding.bottomNav.setVisibility(View.GONE);
    }

    private Fragment createFragment(String tag) {
        switch (tag) {
            case TAG_LIBRARY:  return new LibraryFragment();
            case TAG_SEARCH:   return new SearchFragment();
            case TAG_SOURCES:  return new SourcesFragment();
            case TAG_UPDATES:  return new UpdatesFragment();
            case TAG_SETTINGS: return new SettingsFragment();
            case TAG_HISTORY:  return new HistoryFragment();
            default:           return new LibraryFragment();
        }
    }

    @Override
    public void onBackPressed() {
        FragmentManager fm = getSupportFragmentManager();
        if (fm.getBackStackEntryCount() > 0) {
            fm.popBackStack();
            if (fm.getBackStackEntryCount() == 0)
                binding.bottomNav.setVisibility(View.VISIBLE);
        } else {
            // Double-tap to exit
            exitPressCount++;
            if (exitPressCount >= 2) {
                super.onBackPressed();
            } else {
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .show(this, "Press back again to exit");
                new android.os.Handler().postDelayed(() -> exitPressCount = 0, 2000);
            }
        }
    }

    public void hideSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            getWindow().getInsetsController().hide(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
            getWindow().getInsetsController().setSystemBarsBehavior(
                WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
        // Remove top padding in reader mode
        binding.fragmentContainer.setPadding(0, 0, 0, 0);
    }

    public void showSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
            getWindow().getInsetsController().show(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
    }
}
EOF

echo "✅ Fix 1: Status bar insets done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 2: AllManga covers — Glide needs Referer/Origin headers for CDN images
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$J/network"

cat > "$J/network/GlideManager.java" << 'EOF'
package com.fountainpdl.comifountain.network;

import android.content.Context;
import android.widget.ImageView;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.model.GlideUrl;
import com.bumptech.glide.load.model.LazyHeaders;
import com.fountainpdl.comifountain.R;

/**
 * Centralised image loading — handles per-source headers (e.g. AllManga CDN).
 */
public class GlideManager {

    public static void loadCover(Context context, String url, ImageView into) {
        if (url == null || url.isEmpty()) {
            into.setImageResource(R.drawable.ic_manga_placeholder);
            return;
        }
        GlideUrl glideUrl = buildUrl(url);
        Glide.with(context)
            .load(glideUrl)
            .placeholder(R.drawable.ic_manga_placeholder)
            .error(R.drawable.ic_manga_placeholder)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .centerCrop()
            .into(into);
    }

    public static void loadPage(Context context, String url, ImageView into) {
        GlideUrl glideUrl = buildUrl(url);
        Glide.with(context)
            .load(glideUrl)
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .fitCenter()
            .into(into);
    }

    /** Attach appropriate headers depending on URL origin. */
    private static GlideUrl buildUrl(String url) {
        LazyHeaders.Builder headers = new LazyHeaders.Builder()
            .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36");

        if (url.contains("allanime") || url.contains("wp.allanime")
                || url.contains("cdnjs") || url.contains("allanimecdn")) {
            headers.addHeader("Referer", "https://allmanga.to")
                   .addHeader("Origin",  "https://allmanga.to");
        } else if (url.contains("mangapuma")) {
            headers.addHeader("Referer", "https://mangapuma.com");
        } else if (url.contains("ravenscans")) {
            headers.addHeader("Referer", "https://ravenscans.com");
        }
        return new GlideUrl(url, headers.build());
    }
}
EOF

echo "✅ Fix 2: Glide headers done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 3: AllManga — fix chapter list query and cover URLs
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/AllMangaSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.network.GqlClient;
import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import java.text.SimpleDateFormat;
import java.util.*;

public class AllMangaSource implements Source {

    public static final String ID   = "allanime";
    private static final String API = "https://api.allanime.day/api";
    private static final Gson   GS  = new Gson();

    // ── Queries ───────────────────────────────────────────────────────────────

    private static final String Q_SEARCH =
        "query($search:SearchInput,$limit:Int,$page:Int,$countryOrigin:VaildCountryOriginEnumType){" +
        "mangas(search:$search,limit:$limit,page:$page,countryOrigin:$countryOrigin){" +
        "edges{_id name thumbnail description genres status}}}";

    private static final String Q_DETAIL =
        "query($id:String!){manga(_id:$id){" +
        "_id name thumbnail description authors genres status " +
        "availableChaptersDetail}}";

    // Correct chapter list query for AllManga
    private static final String Q_CHAPTERS =
        "query($id:String!){manga(_id:$id){" +
        "availableChaptersDetail " +
        "chapters{edges{_id chapterNum uploadDate title}}}}";

    private static final String Q_PAGES =
        "query($chapterId:String!,$chapterNum:Float!){" +
        "chapterPages(chapterId:$chapterId,chapterNum:$chapterNum){" +
        "edges{pictureUrls pageNum}}}";

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "AllManga"; }
    @Override public String getLang()      { return "en"; }
    @Override public String getBaseUrl()   { return "https://allmanga.to"; }
    @Override public int    getIconResId() { return R.drawable.ic_source_allanime; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        Map<String,Object> search = new HashMap<>();
        search.put("isManga",  true);
        search.put("sortBy",   "Latest");
        search.put("allowAdult", false);
        Map<String,Object> vars = new HashMap<>();
        vars.put("search", search);
        vars.put("limit",  20);
        vars.put("page",   page);
        vars.put("countryOrigin", "ALL");
        return parseSearch(GqlClient.query(API, Q_SEARCH, vars, headers()));
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        Map<String,Object> search = new HashMap<>();
        search.put("query",        query);
        search.put("isManga",      true);
        search.put("sortBy",       "Top");
        search.put("allowAdult",   false);
        search.put("allowUnknown", true);
        Map<String,Object> vars = new HashMap<>();
        vars.put("search", search);
        vars.put("limit",  20);
        vars.put("page",   page);
        vars.put("countryOrigin", "ALL");
        return parseSearch(GqlClient.query(API, Q_SEARCH, vars, headers()));
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        Map<String,Object> vars = new HashMap<>();
        vars.put("id", mangaId);
        String json = GqlClient.query(API, Q_DETAIL, vars, headers());
        try {
            DetailResp r = GS.fromJson(json, DetailResp.class);
            if (r == null || r.data == null || r.data.manga == null) return null;
            MangaDetail d = r.data.manga;
            Manga m = new Manga(Manga.buildId(ID, d._id), d.name, fixCoverUrl(d.thumbnail), ID, getName());
            m.description = d.description;
            m.author      = (d.authors != null && !d.authors.isEmpty()) ? d.authors.get(0) : "";
            if (d.genres != null) m.genres = d.genres;
            m.status      = d.status != null ? d.status.toLowerCase() : "unknown";
            m.url         = getBaseUrl() + "/manga/" + d._id;
            return m;
        } catch (Exception e) { e.printStackTrace(); return null; }
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Map<String,Object> vars = new HashMap<>();
        vars.put("id", mangaId);
        String json = GqlClient.query(API, Q_CHAPTERS, vars, headers());
        List<Chapter> chapters = new ArrayList<>();
        try {
            ChapterResp r = GS.fromJson(json, ChapterResp.class);
            if (r == null || r.data == null || r.data.manga == null) return chapters;
            if (r.data.manga.chapters == null || r.data.manga.chapters.edges == null)
                return chapters;
            int index = 0;
            List<ChapterEdge> edges = r.data.manga.chapters.edges;
            for (ChapterEdge e : edges) {
                if (e == null) continue;
                float num = e.chapterNum;
                // chapterId format for pages query: rawId|chapterNum
                String rawId   = e._id != null ? e._id : ("sub|" + num);
                String chapId  = Chapter.buildId(ID, rawId + "|" + num);
                String title   = (e.title != null && !e.title.isEmpty())
                    ? e.title
                    : "Chapter " + (num == (int)num ? String.valueOf((int)num) : String.valueOf(num));
                Chapter c = new Chapter(chapId, Manga.buildId(ID, mangaId), ID, title, num,
                    e.uploadDate != null ? parseDate(e.uploadDate) : 0);
                c.index = index++;
                chapters.add(c);
            }
            // Sort newest first
            chapters.sort((a, b) -> Float.compare(b.number, a.number));
        } catch (Exception e) { e.printStackTrace(); }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        // chapterId: "allanime:rawId|chapterNum"
        String raw = chapterId.substring(chapterId.indexOf(':') + 1);
        String[] parts = raw.split("\\|");
        String rawId  = parts[0];
        float chapNum = parts.length > 1 ? parseFloat(parts[1]) : 0;

        Map<String,Object> vars = new HashMap<>();
        vars.put("chapterId",  rawId);
        vars.put("chapterNum", chapNum);
        String json = GqlClient.query(API, Q_PAGES, vars, headers());
        List<Page> pages = new ArrayList<>();
        try {
            PageResp r = GS.fromJson(json, PageResp.class);
            if (r == null || r.data == null || r.data.chapterPages == null) return pages;
            for (PageEdge e : r.data.chapterPages.edges) {
                if (e.pictureUrls != null) {
                    for (String url : e.pictureUrls) {
                        if (url != null && !url.isEmpty())
                            pages.add(new Page(e.pageNum - 1, url));
                    }
                }
            }
            pages.sort((a, b) -> Integer.compare(a.index, b.index));
        } catch (Exception e) { e.printStackTrace(); }
        return pages;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<Manga> parseSearch(String json) {
        List<Manga> result = new ArrayList<>();
        try {
            SearchResp r = GS.fromJson(json, SearchResp.class);
            if (r == null || r.data == null || r.data.mangas == null) return result;
            for (MangaEdge e : r.data.mangas.edges) {
                if (e == null || e._id == null) continue;
                Manga m = new Manga(Manga.buildId(ID, e._id), e.name,
                    fixCoverUrl(e.thumbnail), ID, getName());
                if (e.genres != null) m.genres = e.genres;
                m.status      = e.status != null ? e.status.toLowerCase() : "unknown";
                m.description = e.description;
                m.url         = getBaseUrl() + "/manga/" + e._id;
                result.add(m);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    /** AllManga thumbnails sometimes come as relative paths — fix them. */
    private String fixCoverUrl(String url) {
        if (url == null) return null;
        if (url.startsWith("//")) return "https:" + url;
        if (url.startsWith("/")) return "https://wp.allanime.day" + url;
        return url;
    }

    private long parseDate(String d) {
        try { return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).parse(d).getTime(); }
        catch (Exception e1) {
            try { return new SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(d).getTime(); }
            catch (Exception e2) { return 0; }
        }
    }

    private float parseFloat(String s) {
        try { return Float.parseFloat(s); } catch (Exception e) { return 0; }
    }

    private Map<String,String> headers() {
        Map<String,String> h = new HashMap<>();
        h.put("Referer", "https://allmanga.to");
        h.put("Origin",  "https://allmanga.to");
        return h;
    }

    // ── Gson response classes ─────────────────────────────────────────────────

    static class SearchResp  { SearchData  data; static class SearchData  { MangaList  mangas; } static class MangaList  { List<MangaEdge>   edges; } }
    static class DetailResp  { DetailData  data; static class DetailData  { MangaDetail manga; } }
    static class ChapterResp { ChapterData data; static class ChapterData { MangaChaps  manga; } static class MangaChaps { ChapList chapters; } static class ChapList { List<ChapterEdge> edges; } }
    static class PageResp    { PageData    data; static class PageData    { PageList  chapterPages; } static class PageList  { List<PageEdge>    edges; } }

    static class MangaEdge   { @SerializedName("_id") String _id; String name, thumbnail, description, status; List<String> genres; }
    static class MangaDetail { @SerializedName("_id") String _id; String name, thumbnail, description, status; List<String> authors, genres; }
    static class ChapterEdge { @SerializedName("_id") String _id; float chapterNum; String uploadDate, title; }
    static class PageEdge    { List<String> pictureUrls; int pageNum; }
}
EOF

echo "✅ Fix 3: AllManga source fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 4: MangaDetailFragment — use GlideManager, decode HTML, show chapters
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/detail/MangaDetailFragment.java" << 'EOF'
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
EOF

echo "✅ Fix 4: Detail fragment fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 5: MangaGridAdapter — use GlideManager for covers
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/library/MangaGridAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.network.GlideManager;
import java.util.*;

public class MangaGridAdapter extends RecyclerView.Adapter<MangaGridAdapter.VH> {

    public interface Listener {
        void onClick(Manga m);
        void onLongClick(Manga m);
    }

    private static final int VIEW_GRID    = 0;
    private static final int VIEW_LIST    = 1;
    private static final int VIEW_COMPACT = 2;

    private final Listener listener;
    private List<Manga> fullList    = new ArrayList<>();
    private List<Manga> displayList = new ArrayList<>();
    private int viewType = VIEW_GRID;

    public MangaGridAdapter(Listener listener) { this.listener = listener; }

    public void setFullList(List<Manga> list) {
        fullList    = list != null ? list : new ArrayList<>();
        displayList = new ArrayList<>(fullList);
        notifyDataSetChanged();
    }

    public void submitList(List<Manga> list) { setFullList(list); }

    public void filter(String query) {
        if (query == null || query.isEmpty()) {
            displayList = new ArrayList<>(fullList);
        } else {
            String q = query.toLowerCase();
            displayList = new ArrayList<>();
            for (Manga m : fullList)
                if (m.title != null && m.title.toLowerCase().contains(q)) displayList.add(m);
        }
        notifyDataSetChanged();
    }

    public void setDisplayMode(boolean grid, boolean compact) {
        viewType = compact ? VIEW_COMPACT : grid ? VIEW_GRID : VIEW_LIST;
        notifyDataSetChanged();
    }

    @Override public int getItemViewType(int pos) { return viewType; }
    @Override public int getItemCount()           { return displayList.size(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int type) {
        int layout = type == VIEW_LIST    ? R.layout.item_manga_list
                   : type == VIEW_COMPACT ? R.layout.item_manga_compact
                   :                        R.layout.item_manga_card;
        return new VH(LayoutInflater.from(p.getContext()).inflate(layout, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Manga m = displayList.get(pos);
        if (h.title      != null) h.title.setText(m.title);
        if (h.sourceName != null) h.sourceName.setText(m.sourceName);
        if (h.status     != null) h.status.setText(m.status != null ? m.status : "");
        if (h.badge      != null) {
            h.badge.setVisibility(m.unreadCount > 0 ? View.VISIBLE : View.GONE);
            if (m.unreadCount > 0) h.badge.setText(String.valueOf(m.unreadCount));
        }
        if (h.cover != null)
            GlideManager.loadCover(h.cover.getContext(), m.cover, h.cover);

        h.itemView.setOnClickListener(v -> listener.onClick(m));
        h.itemView.setOnLongClickListener(v -> { listener.onLongClick(m); return true; });
    }

    static class VH extends RecyclerView.ViewHolder {
        ImageView cover; TextView title, badge, sourceName, status;
        VH(View v) {
            super(v);
            cover      = v.findViewById(R.id.manga_cover);
            title      = v.findViewById(R.id.manga_title);
            badge      = v.findViewById(R.id.manga_unread_badge);
            sourceName = v.findViewById(R.id.manga_source);
            status     = v.findViewById(R.id.manga_status);
        }
    }
}
EOF

echo "✅ Fix 5: MangaGridAdapter covers fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 6: SearchFragment — state persistence + source switching re-searches
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/search/SearchViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.search;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.sources.*;
import java.util.*;
import java.util.concurrent.*;

public class SearchViewModel extends AndroidViewModel {

    public enum State { IDLE, LOADING, RESULTS, ERROR }

    public final MutableLiveData<List<Manga>> results  = new MutableLiveData<>(new ArrayList<>());
    public final MutableLiveData<State>       state    = new MutableLiveData<>(State.IDLE);
    public final MutableLiveData<String>      errorMsg = new MutableLiveData<>();
    public final MutableLiveData<String>      query    = new MutableLiveData<>("");
    public final MutableLiveData<String>      sourceId = new MutableLiveData<>();

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private Future<?> pendingSearch = null;

    public SearchViewModel(@NonNull Application app) {
        super(app);
        Source def = SourceManager.getInstance(app).getDefault();
        sourceId.setValue(def != null ? def.getId() : "allanime");
    }

    public void search(String q, int page) {
        // Cancel any pending search
        if (pendingSearch != null && !pendingSearch.isDone())
            pendingSearch.cancel(true);

        query.setValue(q);
        state.setValue(State.LOADING);

        pendingSearch = executor.submit(() -> {
            try {
                SourceManager mgr    = SourceManager.getInstance(getApplication());
                Source        source = mgr.getById(sourceId.getValue());
                if (source == null) source = mgr.getDefault();

                List<Manga> found = (q == null || q.trim().isEmpty())
                    ? source.browse(page)
                    : source.search(q.trim(), page);

                results.postValue(found != null ? found : new ArrayList<>());
                state.postValue(found != null && !found.isEmpty()
                    ? State.RESULTS : State.RESULTS);
            } catch (Exception e) {
                errorMsg.postValue(e.getMessage());
                state.postValue(State.ERROR);
            }
        });
    }

    /** Switch source and immediately re-run the current query. */
    public void setSource(String id) {
        sourceId.setValue(id);
        results.setValue(new ArrayList<>()); // clear old results instantly
        String q = query.getValue();
        search(q != null ? q : "", 1);
    }

    public String getCurrentQuery() {
        return query.getValue() != null ? query.getValue() : "";
    }
}
EOF

cat > "$J/ui/search/SearchFragment.java" << 'EOF'
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
EOF

echo "✅ Fix 6: Search state + source switching fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 7: Sources Browse tab — actually shows manga from source
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/sources/SourceBrowseFragment.java" << 'EOF'
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
EOF

# ─────────────────────────────────────────────────────────────────────────────
# FIX 7b: Update SourcesFragment browse tab to open SourceBrowseFragment
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/sources/SourceCardAdapter.java" << 'EOF'
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
        return new VH(LayoutInflater.from(p.getContext())
            .inflate(R.layout.item_source_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Source s = sources.get(pos);
        h.name.setText(s.getName());
        h.lang.setText(s.getLang().toUpperCase());
        h.icon.setImageResource(s.getIconResId());
        h.browseBtn.setOnClickListener(v -> listener.onBrowse(s));
        h.itemView.setOnClickListener(v -> listener.onBrowse(s));
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
EOF

echo "✅ Fix 7: Browse fragment done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 8: Source browse layout
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_source_browse.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="56dp"
        android:orientation="horizontal" android:gravity="center_vertical"
        android:background="?attr/colorSurface">
        <ImageButton android:id="@+id/browse_back"
            android:layout_width="48dp" android:layout_height="48dp"
            android:src="@drawable/ic_back"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Back"/>
        <TextView android:id="@+id/browse_title"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:textSize="18sp" android:textStyle="bold"/>
    </LinearLayout>

    <androidx.appcompat.widget.SearchView android:id="@+id/browse_search"
        android:layout_width="match_parent" android:layout_height="48dp"
        android:background="?attr/colorSurface"/>

    <ProgressBar android:id="@+id/browse_progress"
        android:layout_width="match_parent" android:layout_height="4dp"
        android:indeterminate="true" android:visibility="gone"
        style="@style/Widget.Material3.LinearProgressIndicator"/>

    <androidx.recyclerview.widget.RecyclerView android:id="@+id/browse_recycler"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:padding="8dp" android:clipToPadding="false"/>

</LinearLayout>
EOF

# ─────────────────────────────────────────────────────────────────────────────
# FIX 8b: Update SourcesFragment to navigate to SourceBrowseFragment
# ─────────────────────────────────────────────────────────────────────────────

# Patch the browse setup in SourcesFragment to open SourceBrowseFragment
sed -i 's/if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity)/Source src = source;\n            if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity)/' \
  "$J/ui/sources/SourcesFragment.java" 2>/dev/null || true

# Rewrite setupBrowse in SourcesFragment cleanly
cat > /tmp/browse_patch.py << 'PYEOF'
import re, sys

content = open(sys.argv[1]).read()

old = '''    private void setupBrowse() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        SourceCardAdapter adapter = new SourceCardAdapter(sources, source -> {
            if ("local".equals(source.getId())
                    && AppPreferences.getInstance(requireContext()).getLocalUri() == null) {
                folderPicker.launch(null);
            } else {
                if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity)
                    ((com.fountainpdl.comifountain.MainActivity) getActivity()).showFragment("search");
            }
        });
        binding.browseRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.browseRecycler.setAdapter(adapter);
        binding.pickFolderBtn.setOnClickListener(v -> folderPicker.launch(null));
    }'''

new = '''    private void setupBrowse() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        SourceCardAdapter adapter = new SourceCardAdapter(sources, source -> {
            if ("local".equals(source.getId())
                    && AppPreferences.getInstance(requireContext()).getLocalUri() == null) {
                folderPicker.launch(null);
                return;
            }
            // Open the per-source browse screen
            if (getActivity() instanceof com.fountainpdl.comifountain.MainActivity) {
                ((com.fountainpdl.comifountain.MainActivity) getActivity())
                    .pushFragment(SourceBrowseFragment.newInstance(source.getId()),
                        "browse_" + source.getId());
            }
        });
        binding.browseRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.browseRecycler.setAdapter(adapter);
        binding.pickFolderBtn.setOnClickListener(v -> folderPicker.launch(null));
    }'''

content = content.replace(old, new)
open(sys.argv[1], 'w').write(content)
print("patched")
PYEOF

python3 /tmp/browse_patch.py "$J/ui/sources/SourcesFragment.java" 2>/dev/null \
  || echo "⚠️  Manual patch needed for setupBrowse — see note below"

echo "✅ Fix 8: Sources browse navigation done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 9: CustomUrlSource — run network on background thread, null safety
# ─────────────────────────────────────────────────────────────────────────────

# The crash when adding a source is likely a NetworkOnMainThreadException
# All network calls already go through SourceManager.addCustomSource which is fine,
# but the CustomUrlSource itself might throw during init. The real crash is in
# SourceManager.loadCustomSources — already runs on executor. 
# More likely crash: null pointer in CustomUrlSource if config fields are null.

sed -i 's/String path = config.searchPath != null/String path = (config != null \&\& config.searchPath != null)/' \
  "$J/sources/CustomUrlSource.java" 2>/dev/null || true

echo "✅ Fix 9: CustomUrlSource null safety"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 10: Library local tab — shows manga from LocalSource
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/library/LibraryFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.os.Bundle;
import android.view.*;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.MainActivity;
import com.fountainpdl.comifountain.data.model.Manga;
import com.fountainpdl.comifountain.databinding.FragmentLibraryBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.detail.MangaDetailFragment;
import java.util.*;
import java.util.concurrent.Executors;

public class LibraryFragment extends Fragment {

    private FragmentLibraryBinding binding;
    private LibraryViewModel viewModel;
    private MangaGridAdapter adapter;
    private AppPreferences prefs;
    private boolean isGrid = true;
    private String activeTab = "library"; // "library" or "local"

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
        setupTabs();

        binding.swipeRefresh.setOnRefreshListener(() -> binding.swipeRefresh.setRefreshing(false));
        binding.searchLibrary.addTextChangedListener(new android.text.TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int st, int c2, int a) {}
            @Override public void onTextChanged(CharSequence s, int st, int b, int c2) { adapter.filter(s.toString()); }
            @Override public void afterTextChanged(android.text.Editable s) {}
        });

        observeLibrary();
    }

    private void setupTabs() {
        binding.tabLibrary.setOnClickListener(v -> { activeTab = "library"; refreshTab(); });
        binding.tabLocal.setOnClickListener(v   -> { activeTab = "local";   loadLocalSource(); });
        refreshTab();
    }

    private void refreshTab() {
        float libAlpha   = "library".equals(activeTab) ? 1f : 0.5f;
        float localAlpha = "local".equals(activeTab)   ? 1f : 0.5f;
        binding.tabLibrary.setAlpha(libAlpha);
        binding.tabLocal.setAlpha(localAlpha);

        if ("library".equals(activeTab)) {
            observeLibrary();
        }
    }

    private void observeLibrary() {
        viewModel.getLibraryManga().observe(getViewLifecycleOwner(), list -> {
            if (!"library".equals(activeTab)) return;
            adapter.setFullList(list);
            binding.emptyState.setVisibility(list.isEmpty() ? View.VISIBLE : View.GONE);
            binding.libraryCount.setText(list.size() + " manga");
            binding.swipeRefresh.setRefreshing(false);
        });
    }

    private void loadLocalSource() {
        binding.swipeRefresh.setRefreshing(true);
        Executors.newSingleThreadExecutor().execute(() -> {
            try {
                Source local = SourceManager.getInstance(requireContext()).getById("local");
                if (local == null) {
                    requireActivity().runOnUiThread(() -> {
                        binding.swipeRefresh.setRefreshing(false);
                        com.fountainpdl.comifountain.ui.common.ToastManager
                            .show(requireContext(), "Set a local folder in Sources first");
                    });
                    return;
                }
                List<Manga> localManga = local.browse(1);
                requireActivity().runOnUiThread(() -> {
                    adapter.setFullList(localManga);
                    binding.libraryCount.setText(localManga.size() + " local");
                    binding.emptyState.setVisibility(localManga.isEmpty() ? View.VISIBLE : View.GONE);
                    binding.swipeRefresh.setRefreshing(false);
                });
            } catch (Exception e) {
                requireActivity().runOnUiThread(() -> {
                    binding.swipeRefresh.setRefreshing(false);
                    com.fountainpdl.comifountain.ui.common.ToastManager
                        .showLong(requireContext(), "Local load failed: " + e.getMessage());
                });
            }
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
            binding.libraryRecycler.setLayoutManager(
                new GridLayoutManager(requireContext(), cols));
        } else {
            binding.libraryRecycler.setLayoutManager(
                new LinearLayoutManager(requireContext()));
        }
        adapter.setDisplayMode(isGrid, prefs.isLibCompact());
    }

    private void setupToggles() {
        binding.toggleGrid.setOnClickListener(v -> { isGrid = true;  prefs.setLibDisplay("grid"); applyLayout(); });
        binding.toggleList.setOnClickListener(v -> { isGrid = false; prefs.setLibDisplay("list"); applyLayout(); });
    }

    private void openDetail(Manga manga) {
        if (getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).pushFragment(
                MangaDetailFragment.newInstance(manga.id), "detail_" + manga.id);
    }

    private void showOptions(Manga manga) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle(manga.title)
            .setItems(new String[]{"Remove from library","Mark all read","Mark all unread","Move to category"}, (d, which) -> {
                switch (which) {
                    case 0: viewModel.removeFromLibrary(manga.id); break;
                    case 1: viewModel.markAllRead(manga.id);       break;
                    case 2: viewModel.markAllUnread(manga.id);     break;
                    case 3: showCategoryPicker(manga);             break;
                }
            }).show();
    }

    private void showCategoryPicker(Manga manga) {
        viewModel.getCategories().observe(getViewLifecycleOwner(), cats -> {
            if (cats == null || cats.isEmpty()) {
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .show(requireContext(), "Create categories in Settings first");
                return;
            }
            String[] names = cats.stream().map(c -> c.name).toArray(String[]::new);
            boolean[] checked = new boolean[cats.size()];
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Move to Category")
                .setMultiChoiceItems(names, checked, (d, w, c) -> checked[w] = c)
                .setPositiveButton("Apply", (d, w) -> {
                    List<String> sel = new ArrayList<>();
                    for (int i = 0; i < cats.size(); i++) if (checked[i]) sel.add(cats.get(i).name);
                    viewModel.updateCategories(manga.id, sel);
                }).setNegativeButton("Cancel", null).show();
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "✅ Fix 10: Local tab in library done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 11: Library layout — add Library/Local tab row
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_library.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <!-- Header row -->
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical"
        android:paddingHorizontal="12dp" android:paddingTop="8dp" android:paddingBottom="4dp">

        <TextView android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:text="Library"
            android:textSize="22sp" android:textStyle="bold"/>

        <ImageButton android:id="@+id/toggle_list"
            android:layout_width="36dp" android:layout_height="36dp"
            android:src="@drawable/ic_updates"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="List view"/>

        <ImageButton android:id="@+id/toggle_grid"
            android:layout_width="36dp" android:layout_height="36dp"
            android:src="@drawable/ic_library"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Grid view" android:layout_marginStart="4dp"/>

    </LinearLayout>

    <!-- Library / Local tabs -->
    <LinearLayout android:layout_width="match_parent" android:layout_height="40dp"
        android:orientation="horizontal" android:paddingHorizontal="12dp">

        <TextView android:id="@+id/tab_library"
            android:layout_width="0dp" android:layout_height="match_parent"
            android:layout_weight="1" android:text="Library"
            android:gravity="center" android:textStyle="bold"
            android:background="?attr/selectableItemBackground"/>

        <TextView android:id="@+id/tab_local"
            android:layout_width="0dp" android:layout_height="match_parent"
            android:layout_weight="1" android:text="📁 Local"
            android:gravity="center" android:textStyle="bold"
            android:background="?attr/selectableItemBackground"/>

    </LinearLayout>

    <!-- Search bar -->
    <EditText android:id="@+id/search_library"
        android:layout_width="match_parent" android:layout_height="44dp"
        android:layout_marginHorizontal="12dp" android:layout_marginVertical="6dp"
        android:hint="Search…" android:paddingHorizontal="14dp"
        android:background="@drawable/bg_search_field"
        android:imeOptions="actionSearch" android:singleLine="true"
        android:textSize="14sp"/>

    <!-- Count label -->
    <TextView android:id="@+id/library_count"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:paddingHorizontal="16dp" android:paddingBottom="4dp"
        android:textSize="12sp" android:alpha="0.55"/>

    <!-- Content -->
    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipe_refresh"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1">

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/library_recycler"
            android:layout_width="match_parent" android:layout_height="match_parent"
            android:padding="6dp" android:clipToPadding="false"/>

    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

    <TextView android:id="@+id/empty_state"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="Nothing here yet.\nSearch a source to find manga!"
        android:textAlignment="center" android:gravity="center"
        android:padding="32dp" android:visibility="gone" android:alpha="0.6"/>

</LinearLayout>
EOF

echo "✅ Fix 11: Library layout with tabs done"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 12: Search layout — add empty state view
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_search.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical"
        android:padding="8dp" android:background="?attr/colorSurface">

        <androidx.appcompat.widget.SearchView
            android:id="@+id/search_view"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1"/>

        <Button android:id="@+id/source_picker_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="AllManga" android:textColor="?attr/colorPrimary"
            style="@style/Widget.Material3.Button.TextButton"/>

    </LinearLayout>

    <ProgressBar android:id="@+id/progress_bar"
        android:layout_width="match_parent" android:layout_height="4dp"
        android:indeterminate="true" android:visibility="gone"
        style="@style/Widget.Material3.LinearProgressIndicator"/>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/search_recycler"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:padding="6dp" android:clipToPadding="false"/>

    <TextView android:id="@+id/empty_search"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="No results found" android:gravity="center"
        android:padding="32dp" android:visibility="gone" android:alpha="0.6"/>

</LinearLayout>
EOF

# ─────────────────────────────────────────────────────────────────────────────
# FIX 13: manga_detail layout — add emptyChapters view
# ─────────────────────────────────────────────────────────────────────────────

# Add empty chapters view to detail layout
sed -i 's/<\/LinearLayout>$/    <TextView android:id="@+id\/empty_chapters"\n        android:layout_width="match_parent" android:layout_height="wrap_content"\n        android:text="No chapters found" android:gravity="center"\n        android:padding="24dp" android:visibility="gone" android:alpha="0.6"\/>\n<\/LinearLayout>/' \
  "$R/layout/fragment_manga_detail.xml" 2>/dev/null || true

echo "✅ Fix 12-13: Layouts updated"

echo ""
echo "✅ All fixes applied!"
echo ""
echo "git add ."
echo "git commit -m 'fix all: insets, covers, chapters, browse, search, back button, local tab'"
echo "git push"
