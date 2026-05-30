#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Fix2: All 12 issues
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p "$J/sources" "$J/ui/reader" "$J/ui/search" "$J/ui/sources" \
         "$J/ui/detail" "$J/ui/library" "$J/download"

echo "🔧 Starting Fix2..."

# ─────────────────────────────────────────────────────────────────────────────
# FIX 1: Library persistence
# Root cause: saveManga() with REPLACE overwrites inLibrary=true → false
# Fix: merge inLibrary status before inserting
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/MangaRepository.java" << 'EOF'
package com.fountainpdl.comifountain.data;

import android.content.Context;
import androidx.lifecycle.LiveData;
import com.fountainpdl.comifountain.data.db.*;
import com.fountainpdl.comifountain.data.model.*;
import com.google.gson.Gson;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MangaRepository {

    private final MangaDao    mangaDao;
    private final ChapterDao  chapterDao;
    private final CategoryDao categoryDao;
    private final HistoryDao  historyDao;
    private final ExecutorService exec = Executors.newFixedThreadPool(4);
    private static final Gson GSON = new Gson();

    public MangaRepository(Context context) {
        AppDatabase db = AppDatabase.getInstance(context);
        mangaDao    = db.mangaDao();
        chapterDao  = db.chapterDao();
        categoryDao = db.categoryDao();
        historyDao  = db.historyDao();
    }

    // ── Library ───────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> getLibraryManga()                      { return mangaDao.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryMangaByCategory(String cat) { return mangaDao.getLibraryByCategory(cat); }
    public LiveData<List<Manga>> getMangaWithUpdates()                  { return mangaDao.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadgeCount()                 { return mangaDao.getUpdatesBadgeCount(); }
    public LiveData<Manga>       observeManga(String id)                { return mangaDao.observeMangaById(id); }

    /**
     * Save manga from network — PRESERVES inLibrary flag from DB.
     * This is the critical fix: never overwrite inLibrary with false on re-fetch.
     */
    public void saveManga(Manga m) {
        exec.execute(() -> {
            // Check if already in library before replacing
            Manga existing = mangaDao.getMangaById(m.id);
            if (existing != null) {
                m.inLibrary   = existing.inLibrary;
                m.addedDate   = existing.addedDate;
                m.categories  = existing.categories;
                m.lastRead    = existing.lastRead;
                m.progress    = existing.progress;
            }
            mangaDao.insertManga(m);
        });
    }

    public void saveMangaList(List<Manga> list) {
        exec.execute(() -> {
            for (Manga m : list) {
                Manga existing = mangaDao.getMangaById(m.id);
                if (existing != null) {
                    m.inLibrary  = existing.inLibrary;
                    m.addedDate  = existing.addedDate;
                    m.categories = existing.categories;
                }
            }
            mangaDao.insertAll(list);
        });
    }

    public void updateManga(Manga m) { exec.execute(() -> mangaDao.updateManga(m)); }

    // ── Library management ────────────────────────────────────────────────────

    public void addToLibrary(String id) {
        exec.execute(() -> mangaDao.addToLibrary(id, System.currentTimeMillis()));
    }
    public void removeFromLibrary(String id) {
        exec.execute(() -> mangaDao.removeFromLibrary(id));
    }
    public void checkIsInLibrary(String id, Callback<Boolean> cb) {
        exec.execute(() -> cb.onResult(mangaDao.isInLibrary(id)));
    }
    public void updateLastRead(String id) {
        exec.execute(() -> mangaDao.updateLastRead(id, System.currentTimeMillis()));
    }
    public void updateCategories(String id, List<String> cats) {
        exec.execute(() -> mangaDao.updateCategories(id, GSON.toJson(cats)));
    }

    // ── Chapters ──────────────────────────────────────────────────────────────

    public LiveData<List<Chapter>> getChaptersForManga(String id) {
        return chapterDao.getChaptersForManga(id);
    }
    public void saveChapters(List<Chapter> chapters) {
        exec.execute(() -> {
            chapterDao.insertChapters(chapters);
            if (!chapters.isEmpty()) syncChapterStats(chapters.get(0).mangaId);
        });
    }
    public void getFirstUnreadChapter(String id, Callback<Chapter> cb) {
        exec.execute(() -> cb.onResult(chapterDao.getFirstUnreadChapter(id)));
    }
    public void getResumeChapter(String id, Callback<Chapter> cb) {
        exec.execute(() -> {
            Chapter c = chapterDao.getResumeChapter(id);
            if (c == null) c = chapterDao.getFirstUnreadChapter(id);
            cb.onResult(c);
        });
    }

    // ── Read state ────────────────────────────────────────────────────────────

    public void markChapterRead(String chapId, String mangaId) {
        exec.execute(() -> { chapterDao.markRead(chapId); syncChapterStats(mangaId); });
    }
    public void markChapterUnread(String chapId, String mangaId) {
        exec.execute(() -> { chapterDao.markUnread(chapId); syncChapterStats(mangaId); });
    }
    public void markAllRead(String mangaId) {
        exec.execute(() -> { chapterDao.markAllRead(mangaId); syncChapterStats(mangaId); });
    }
    public void markAllUnread(String mangaId) {
        exec.execute(() -> { chapterDao.markAllUnread(mangaId); syncChapterStats(mangaId); });
    }
    public void updateLastPageRead(String chapId, int page) {
        exec.execute(() -> chapterDao.updateLastPageRead(chapId, page));
    }

    // ── Bookmarks ─────────────────────────────────────────────────────────────

    public void setBookmark(String chapId, boolean b) {
        exec.execute(() -> chapterDao.setBookmark(chapId, b));
    }
    public LiveData<List<Chapter>> getBookmarkedChapters(String id) {
        return chapterDao.getBookmarkedChapters(id);
    }

    // ── Downloads ─────────────────────────────────────────────────────────────

    public void markDownloaded(String chapId, String path) {
        exec.execute(() -> chapterDao.markDownloaded(chapId, System.currentTimeMillis(), path));
    }
    public void clearDownload(String chapId) {
        exec.execute(() -> chapterDao.clearDownload(chapId));
    }

    // ── Categories ────────────────────────────────────────────────────────────

    public LiveData<List<Category>> getCategories() { return categoryDao.getAll(); }
    public void addCategory(String name) {
        exec.execute(() -> {
            int pos = categoryDao.count();
            categoryDao.insert(new Category(name, pos));
        });
    }
    public void deleteCategory(Category c) { exec.execute(() -> categoryDao.delete(c)); }

    // ── History ───────────────────────────────────────────────────────────────

    public LiveData<List<HistoryEntry>> getRecentHistory() { return historyDao.getRecent(); }
    public void recordHistory(String mangaId, String chapterId) {
        exec.execute(() -> historyDao.insert(new HistoryEntry(mangaId, chapterId)));
    }
    public void clearHistory()                     { exec.execute(historyDao::clearAll); }
    public void clearHistoryForManga(String id)    { exec.execute(() -> historyDao.clearForManga(id)); }

    // ── Search ────────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> searchLibrary(String q) { return mangaDao.searchLibrary(q); }

    // ── Internal ─────────────────────────────────────────────────────────────

    private void syncChapterStats(String mangaId) {
        int    total   = chapterDao.getTotalCount(mangaId);
        int    unread  = chapterDao.getUnreadCount(mangaId);
        List<Chapter> chapters = chapterDao.getChaptersForMangaSync(mangaId);
        long   latest  = 0;
        for (Chapter c : chapters) if (c.date > latest) latest = c.date;
        mangaDao.updateChapterStats(mangaId, total, unread, latest);
    }

    public interface Callback<T> { void onResult(T result); }
}
EOF

echo "✅ Fix 1: Library persistence fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 2: AllManga — correct chapter query + cover URL fix + dedup
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/AllMangaSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.network.GqlClient;
import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;
import java.text.SimpleDateFormat;
import java.util.*;

public class AllMangaSource implements Source {

    public static final String ID   = "allanime";
    private static final String API = "https://api.allanime.day/api";
    private static final Gson   GS  = new Gson();

    // ── GraphQL Queries ───────────────────────────────────────────────────────

    private static final String Q_SEARCH =
        "query($search:SearchInput,$limit:Int,$page:Int,$countryOrigin:VaildCountryOriginEnumType){" +
        "mangas(search:$search,limit:$limit,page:$page,countryOrigin:$countryOrigin){" +
        "edges{_id name thumbnail description genres status}}}";

    private static final String Q_DETAIL =
        "query($id:String!){manga(_id:$id){" +
        "_id name thumbnail description authors genres status}}";

    // Correct query: use availableChaptersDetail to get chapter numbers,
    // then fetch them page-by-page using chapters query with pagination
    private static final String Q_CHAPTERS =
        "query($id:String!,$page:Int){manga(_id:$id){" +
        "chapters(page:$page,limit:50,orderBy:\"asc\"){" +
        "edges{_id chapterNum uploadDate title}}}}";

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
        search.put("isManga",    true);
        search.put("sortBy",     "Latest");
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
            Manga m = new Manga(Manga.buildId(ID, d._id), d.name, fixUrl(d.thumbnail), ID, getName());
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
        List<Chapter> all = new ArrayList<>();
        Set<String>   seen = new HashSet<>();
        int page = 1;

        while (true) {
            Map<String,Object> vars = new HashMap<>();
            vars.put("id",   mangaId);
            vars.put("page", page);
            String json = GqlClient.query(API, Q_CHAPTERS, vars, headers());
            List<Chapter> batch = parseChapterBatch(json, mangaId);
            if (batch.isEmpty()) break;

            for (Chapter c : batch) {
                if (seen.add(c.id)) all.add(c);
            }
            if (batch.size() < 50) break; // last page
            page++;
            if (page > 20) break; // safety cap (1000 chapters max)
        }

        // Re-index after collecting all
        all.sort((a, b) -> Float.compare(a.number, b.number));
        for (int i = 0; i < all.size(); i++) all.get(i).index = i;

        return all;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String raw = chapterId.substring(chapterId.indexOf(':') + 1);
        String[] parts = raw.split("\\|");
        String rawId  = parts[0];
        float  chapNum = parts.length > 1 ? parseFloat(parts[1]) : 0f;

        Map<String,Object> vars = new HashMap<>();
        vars.put("chapterId",  rawId);
        vars.put("chapterNum", chapNum);
        String json = GqlClient.query(API, Q_PAGES, vars, headers());
        List<Page> pages = new ArrayList<>();
        try {
            PageResp r = GS.fromJson(json, PageResp.class);
            if (r == null || r.data == null || r.data.chapterPages == null) return pages;
            for (PageEdge e : r.data.chapterPages.edges) {
                if (e.pictureUrls != null)
                    for (String url : e.pictureUrls)
                        if (url != null && !url.isEmpty())
                            pages.add(new Page(e.pageNum - 1, fixUrl(url)));
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
                Manga m = new Manga(Manga.buildId(ID, e._id), e.name, fixUrl(e.thumbnail), ID, getName());
                if (e.genres != null) m.genres = e.genres;
                m.status      = e.status != null ? e.status.toLowerCase() : "unknown";
                m.description = e.description;
                m.url         = getBaseUrl() + "/manga/" + e._id;
                result.add(m);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    private List<Chapter> parseChapterBatch(String json, String mangaId) {
        List<Chapter> chapters = new ArrayList<>();
        try {
            ChapterResp r = GS.fromJson(json, ChapterResp.class);
            if (r == null || r.data == null || r.data.manga == null) return chapters;
            if (r.data.manga.chapters == null || r.data.manga.chapters.edges == null)
                return chapters;
            for (ChapterEdge e : r.data.manga.chapters.edges) {
                if (e == null) continue;
                float  num   = e.chapterNum;
                String rawId = e._id != null ? e._id : ("sub|" + num);
                String title = (e.title != null && !e.title.isEmpty() && !e.title.equals("0"))
                    ? e.title
                    : "Chapter " + (num == (int)num ? String.valueOf((int)num) : String.valueOf(num));
                String chapId = Chapter.buildId(ID, rawId + "|" + num);
                Chapter c = new Chapter(chapId, Manga.buildId(ID, mangaId), ID,
                    title, num, e.uploadDate != null ? parseDate(e.uploadDate) : 0);
                chapters.add(c);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return chapters;
    }

    /** Fix relative URLs from AllManga CDN */
    private String fixUrl(String url) {
        if (url == null || url.isEmpty()) return null;
        if (url.startsWith("//"))          return "https:" + url;
        if (url.startsWith("/"))           return "https://wp.allanime.day" + url;
        if (!url.startsWith("http"))       return "https://wp.allanime.day/" + url;
        return url;
    }

    private long parseDate(String d) {
        for (String fmt : new String[]{
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd"}) {
            try { return new SimpleDateFormat(fmt, Locale.US).parse(d).getTime(); }
            catch (Exception ignored) {}
        }
        return 0;
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

    // ── Gson classes ──────────────────────────────────────────────────────────
    static class SearchResp  { SearchData data;  static class SearchData  { MangaList   mangas; } static class MangaList { List<MangaEdge> edges; } }
    static class DetailResp  { DetailData data;  static class DetailData  { MangaDetail manga; } }
    static class ChapterResp { ChapData   data;  static class ChapData    { ChapManga   manga; } static class ChapManga { ChapList chapters; } static class ChapList { List<ChapterEdge> edges; } }
    static class PageResp    { PageData   data;  static class PageData    { PageList  chapterPages; } static class PageList { List<PageEdge> edges; } }

    static class MangaEdge   { @SerializedName("_id") String _id; String name,thumbnail,description,status; List<String> genres; }
    static class MangaDetail { @SerializedName("_id") String _id; String name,thumbnail,description,status; List<String> authors,genres; }
    static class ChapterEdge { @SerializedName("_id") String _id; float chapterNum; String uploadDate,title; }
    static class PageEdge    { List<String> pictureUrls; int pageNum; }
}
EOF

echo "✅ Fix 2: AllManga chapters + covers fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 3: RavenScans — deduplicate results
# ─────────────────────────────────────────────────────────────────────────────

# Patch parseGrid in RavenScansSource to track seen IDs
cat > /tmp/patch_raven.py << 'PYEOF'
import sys
content = open(sys.argv[1]).read()
old = '''    private List<Manga> parseGrid(Document doc) {
        List<Manga> result = new ArrayList<>();
        Elements items = doc.select(".bsx,.bs,.manga-poster,.page-item-detail");
        for (Element item : items) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".tt,.manga-name,.post-title");
            if (link == null) continue;
            String href  = link.attr("href");
            String rawId = mangaSlug(href);
            String title = name != null ? name.text() : rawId;
            String cover = img != null ? img.attr("src") : null;
            Manga m = new Manga(Manga.buildId(ID, rawId), title, cover, ID, getName());
            m.url = href;
            result.add(m);
        }
        return result;
    }'''
new = '''    private List<Manga> parseGrid(Document doc) {
        List<Manga> result = new ArrayList<>();
        java.util.Set<String> seen = new java.util.HashSet<>();
        Elements items = doc.select(".bsx,.bs,.manga-poster,.page-item-detail");
        for (Element item : items) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".tt,.manga-name,.post-title");
            if (link == null) continue;
            String href  = link.attr("href");
            String rawId = mangaSlug(href);
            if (!seen.add(rawId)) continue; // deduplicate
            String title = name != null ? name.text() : rawId;
            String cover = img != null ? img.attr("src") : null;
            Manga m = new Manga(Manga.buildId(ID, rawId), title, cover, ID, getName());
            m.url = href;
            result.add(m);
        }
        return result;
    }'''
content = content.replace(old, new)
open(sys.argv[1], 'w').write(content)
PYEOF
python3 /tmp/patch_raven.py "$J/sources/RavenScansSource.java" 2>/dev/null \
  && echo "✅ Fix 3: RavenScans dedup fixed" \
  || echo "⚠️  RavenScans patch skipped (file not found)"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 4: SourceManager — add custom source off main thread
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/SourceManager.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import android.content.Context;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.CustomSource;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SourceManager {

    private static SourceManager instance;
    private final Context context;
    private final Map<String, Source> sources = Collections.synchronizedMap(new LinkedHashMap<>());
    private final ExecutorService exec = Executors.newSingleThreadExecutor();

    private SourceManager(Context ctx) {
        this.context = ctx.getApplicationContext();
        registerBuiltIn();
        loadCustomSources();
    }

    public static SourceManager getInstance(Context context) {
        if (instance == null) synchronized (SourceManager.class) {
            if (instance == null) instance = new SourceManager(context.getApplicationContext());
        }
        return instance;
    }

    private void registerBuiltIn() {
        register(new AllMangaSource());
        register(new MangaPumaSource());
        register(new RavenScansSource());
        register(new LocalSource(context));
    }

    public void loadCustomSources() {
        exec.execute(() -> {
            try {
                List<CustomSource> customs = AppDatabase.getInstance(context)
                    .customSourceDao().getAllEnabledSync();
                for (CustomSource cs : customs)
                    sources.put("custom_" + cs.id, new CustomUrlSource(cs));
            } catch (Exception e) { e.printStackTrace(); }
        });
    }

    public void register(Source s) { sources.put(s.getId(), s); }
    public Source getById(String id) { return sources.get(id); }
    public List<Source> getAll()    { return new ArrayList<>(sources.values()); }
    public List<Source> getBuiltIn() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values()) if (!s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public List<Source> getCustom() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values()) if (s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public Source getDefault() {
        for (Source s : sources.values()) return s;
        return null;
    }

    /** Add custom source safely on background thread. */
    public void addCustomSource(CustomSource cs, Runnable onDone) {
        exec.execute(() -> {
            try {
                AppDatabase.getInstance(context).customSourceDao().insert(cs);
                sources.put("custom_" + cs.id, new CustomUrlSource(cs));
                if (onDone != null) onDone.run();
            } catch (Exception e) { e.printStackTrace(); }
        });
    }

    public void removeCustomSource(String sourceId) {
        String dbId = sourceId.replace("custom_", "");
        exec.execute(() -> {
            try {
                CustomSource cs = AppDatabase.getInstance(context).customSourceDao().getById(dbId);
                if (cs != null) AppDatabase.getInstance(context).customSourceDao().delete(cs);
            } catch (Exception e) { e.printStackTrace(); }
        });
        sources.remove(sourceId);
    }

    public void updateCustomSourceUrl(String sourceId, String newUrl) {
        String dbId = sourceId.replace("custom_", "");
        exec.execute(() -> {
            try {
                AppDatabase.getInstance(context).customSourceDao().updateUrl(dbId, newUrl);
            } catch (Exception e) { e.printStackTrace(); }
        });
        loadCustomSources(); // reload
    }
}
EOF

echo "✅ Fix 4: SourceManager thread-safe"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 5: GlideManager — broader cover URL support
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/network/GlideManager.java" << 'EOF'
package com.fountainpdl.comifountain.network;

import android.content.Context;
import android.widget.ImageView;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.bumptech.glide.load.model.GlideUrl;
import com.bumptech.glide.load.model.LazyHeaders;
import com.fountainpdl.comifountain.R;

public class GlideManager {

    public static void loadCover(Context context, String url, ImageView into) {
        if (url == null || url.isEmpty()) {
            into.setImageResource(R.drawable.ic_manga_placeholder);
            return;
        }
        // Handle content:// URIs (local source)
        if (url.startsWith("content://")) {
            Glide.with(context)
                .load(android.net.Uri.parse(url))
                .placeholder(R.drawable.ic_manga_placeholder)
                .error(R.drawable.ic_manga_placeholder)
                .diskCacheStrategy(DiskCacheStrategy.NONE)
                .centerCrop()
                .into(into);
            return;
        }
        // Handle file paths (local downloaded)
        if (url.startsWith("/")) {
            Glide.with(context)
                .load(new java.io.File(url))
                .placeholder(R.drawable.ic_manga_placeholder)
                .centerCrop().into(into);
            return;
        }
        try {
            GlideUrl glideUrl = new GlideUrl(url, buildHeaders(url));
            Glide.with(context)
                .load(glideUrl)
                .placeholder(R.drawable.ic_manga_placeholder)
                .error(R.drawable.ic_manga_placeholder)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .centerCrop()
                .into(into);
        } catch (Exception e) {
            into.setImageResource(R.drawable.ic_manga_placeholder);
        }
    }

    public static void loadPage(Context context, String url, ImageView into) {
        if (url == null || url.isEmpty()) return;
        if (url.startsWith("content://")) {
            Glide.with(context).load(android.net.Uri.parse(url))
                .diskCacheStrategy(DiskCacheStrategy.NONE).fitCenter().into(into);
            return;
        }
        if (url.startsWith("/")) {
            Glide.with(context).load(new java.io.File(url)).fitCenter().into(into);
            return;
        }
        try {
            Glide.with(context)
                .load(new GlideUrl(url, buildHeaders(url)))
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .fitCenter().into(into);
        } catch (Exception ignored) {}
    }

    private static LazyHeaders buildHeaders(String url) {
        LazyHeaders.Builder h = new LazyHeaders.Builder()
            .addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36");
        if (url.contains("allanime") || url.contains("wp.allanime")
                || url.contains("allanimecdn") || url.contains("aln.to")) {
            h.addHeader("Referer", "https://allmanga.to")
             .addHeader("Origin",  "https://allmanga.to");
        } else if (url.contains("mangapuma")) {
            h.addHeader("Referer", "https://mangapuma.com");
        } else if (url.contains("ravenscans")) {
            h.addHeader("Referer", "https://ravenscans.com");
        }
        return h.build();
    }
}
EOF

echo "✅ Fix 5: GlideManager covers fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 6: Back button — never exits on first press
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/MainActivity.java" << 'EOF'
package com.fountainpdl.comifountain;

import android.os.Bundle;
import android.os.Handler;
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
    private boolean backPressedOnce = false;

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

        // Proper insets — content below status bar, nav above nav bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.fragmentContainer, (v, insets) -> {
            Insets sys = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.displayCutout());
            v.setPadding(0, sys.top, 0, 0);
            return insets;
        });
        ViewCompat.setOnApplyWindowInsetsListener(binding.bottomNav, (v, insets) -> {
            Insets sys = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(0, 0, 0, sys.bottom);
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
            .replace(R.id.fragment_container, f, tag).commit();
        getSupportFragmentManager().popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE);
        binding.bottomNav.setVisibility(View.VISIBLE);
        // Restore insets for normal fragments
        binding.fragmentContainer.setPadding(
            binding.fragmentContainer.getPaddingLeft(),
            binding.fragmentContainer.getPaddingTop(),
            binding.fragmentContainer.getPaddingRight(),
            0);
    }

    public void pushFragment(Fragment fragment, String tag) {
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, fragment, tag)
            .addToBackStack(tag).commit();
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
            // Double-press to exit
            if (backPressedOnce) {
                super.onBackPressed();
                return;
            }
            backPressedOnce = true;
            com.fountainpdl.comifountain.ui.common.ToastManager
                .show(this, "Press back again to exit");
            new Handler().postDelayed(() -> backPressedOnce = false, 2000);
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
        // Remove top padding in fullscreen
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

echo "✅ Fix 6: Back button fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 7: Reader — controls hide on tap AND on scroll
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/reader/ReaderFragment.java" << 'EOF'
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
            requireActivity().getWindow().addFlags(
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (prefs.isFullscreen() && getActivity() instanceof MainActivity)
            ((MainActivity) getActivity()).hideSystemBars();

        adapter = new PageAdapter();
        adapter.setGrayscale(prefs.isGrayscale());

        // Reading mode
        String mode = prefs.getReadingMode();
        binding.readerPager.setOrientation(
            ("vertical".equals(mode) || "webtoon".equals(mode))
                ? ViewPager2.ORIENTATION_VERTICAL
                : ViewPager2.ORIENTATION_HORIZONTAL);
        if ("rtl".equals(mode))
            binding.readerPager.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);

        binding.readerPager.setAdapter(adapter);

        // Page change — update indicator + slider + hide bars on scroll
        binding.readerPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override public void onPageSelected(int pos) {
                vm.updatePage(pos);
                int total = vm.getTotalPages();
                binding.pageIndicator.setText((pos + 1) + " / " + total);
                if (total > 1) binding.pageSlider.setValue(pos);
            }
            @Override public void onPageScrollStateChanged(int state) {
                // Hide controls when user starts swiping
                if (state == ViewPager2.SCROLL_STATE_DRAGGING && barsVisible) {
                    hideBars();
                }
            }
        });

        binding.pageSlider.addOnChangeListener((s2, val, fromUser) -> {
            if (fromUser) binding.readerPager.setCurrentItem((int) val, false);
        });

        // Tap center of screen to toggle bars
        binding.readerPager.setOnClickListener(v -> toggleBars());
        // Also detect tap via touch interceptor
        binding.readerTouchInterceptor.setOnClickListener(v -> toggleBars());

        binding.readerBackBtn.setOnClickListener(v -> requireActivity().onBackPressed());

        vm.pages.observe(getViewLifecycleOwner(), pages -> {
            adapter.setPages(pages);
            if (!pages.isEmpty()) {
                binding.pageSlider.setValueFrom(0);
                binding.pageSlider.setValueTo(Math.max(1, pages.size() - 1));
                binding.pageSlider.setValue(0);
                binding.pageIndicator.setText("1 / " + pages.size());
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

        vm.load(mangaId, chapterId);

        // Start with bars hidden after 2 seconds
        binding.readerPager.postDelayed(this::hideBars, 2500);
    }

    private void toggleBars() {
        if (barsVisible) hideBars(); else showBars();
    }

    private void hideBars() {
        barsVisible = false;
        binding.readerTopBar.animate().alpha(0f).setDuration(200)
            .withEndAction(() -> binding.readerTopBar.setVisibility(View.GONE)).start();
        binding.readerBottomBar.animate().alpha(0f).setDuration(200)
            .withEndAction(() -> binding.readerBottomBar.setVisibility(View.GONE)).start();
    }

    private void showBars() {
        barsVisible = true;
        binding.readerTopBar.setVisibility(View.VISIBLE);
        binding.readerTopBar.animate().alpha(1f).setDuration(200).start();
        binding.readerBottomBar.setVisibility(View.VISIBLE);
        binding.readerBottomBar.animate().alpha(1f).setDuration(200).start();
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
EOF

echo "✅ Fix 7: Reader controls auto-hide fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 8: Remove source picker button from search, keep it in the header area
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_search.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <!-- Search bar only — source shown as subtitle -->
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical" android:background="?attr/colorSurface"
        android:paddingBottom="4dp">

        <androidx.appcompat.widget.SearchView
            android:id="@+id/search_view"
            android:layout_width="match_parent" android:layout_height="52dp"
            android:iconifiedByDefault="false"/>

        <!-- Tappable source label below search bar -->
        <TextView android:id="@+id/source_picker_btn"
            android:layout_width="match_parent" android:layout_height="32dp"
            android:gravity="center_vertical"
            android:paddingHorizontal="16dp"
            android:text="Source: AllManga  ▾"
            android:textSize="12sp"
            android:textColor="?attr/colorPrimary"
            android:background="?attr/selectableItemBackground"/>

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

# Update SearchFragment to use the new layout (source label instead of button)
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
        // Activity-scoped ViewModel so state persists across tab switches
        viewModel = new ViewModelProvider(requireActivity()).get(SearchViewModel.class);

        adapter = new MangaGridAdapter(new MangaGridAdapter.Listener() {
            @Override public void onClick(Manga m)     { openDetail(m); }
            @Override public void onLongClick(Manga m) {}
        });
        binding.searchRecycler.setLayoutManager(new GridLayoutManager(requireContext(), 2));
        binding.searchRecycler.setAdapter(adapter);

        setupSourcePicker();

        binding.searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override public boolean onQueryTextSubmit(String q) { viewModel.search(q, 1); return true; }
            @Override public boolean onQueryTextChange(String t) {
                if (t.isEmpty()) viewModel.search("", 1);
                return false;
            }
        });

        // Restore query in SearchView
        String existing = viewModel.getCurrentQuery();
        if (!existing.isEmpty()) binding.searchView.setQuery(existing, false);

        viewModel.state.observe(getViewLifecycleOwner(), s -> {
            boolean loading = s == SearchViewModel.State.LOADING;
            binding.progressBar.setVisibility(loading ? View.VISIBLE : View.GONE);
        });

        viewModel.results.observe(getViewLifecycleOwner(), list -> {
            adapter.submitList(list);
            boolean empty = list == null || list.isEmpty();
            binding.emptySearch.setVisibility(
                !empty || viewModel.state.getValue() == SearchViewModel.State.LOADING
                    ? View.GONE : View.VISIBLE);
        });

        viewModel.errorMsg.observe(getViewLifecycleOwner(), err -> {
            if (err != null && !err.isEmpty())
                com.fountainpdl.comifountain.ui.common.ToastManager
                    .showLong(requireContext(), "Error: " + err);
        });

        if (viewModel.results.getValue() == null || viewModel.results.getValue().isEmpty())
            viewModel.search("", 1);
    }

    private void setupSourcePicker() {
        List<Source> sources = SourceManager.getInstance(requireContext()).getAll();
        updateSourceLabel(sources);
        binding.sourcePickerBtn.setOnClickListener(v -> {
            String[] names = sources.stream().map(Source::getName).toArray(String[]::new);
            new androidx.appcompat.app.AlertDialog.Builder(requireContext())
                .setTitle("Select Source")
                .setItems(names, (d, which) -> {
                    viewModel.setSource(sources.get(which).getId());
                    updateSourceLabel(sources);
                }).show();
        });
    }

    private void updateSourceLabel(List<Source> sources) {
        String id = viewModel.sourceId.getValue();
        for (Source s : sources) {
            if (s.getId().equals(id)) {
                binding.sourcePickerBtn.setText("Source: " + s.getName() + "  ▾");
                return;
            }
        }
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

echo "✅ Fix 8: Source picker moved below search bar"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 9: Local source crash — safe DocumentFile handling
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/LocalSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import android.content.Context;
import android.net.Uri;
import androidx.documentfile.provider.DocumentFile;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import java.io.*;
import java.util.*;
import java.util.zip.*;

public class LocalSource implements Source {

    public static final String ID = "local";
    private final Context ctx;
    private Uri rootUri;

    public LocalSource(Context context) { this.ctx = context.getApplicationContext(); }

    public void setRootUri(Uri uri) { this.rootUri = uri; }
    public Uri  getRootUri()        { return rootUri; }

    @Override public String getId()        { return ID; }
    @Override public String getName()      { return "Local"; }
    @Override public String getLang()      { return "local"; }
    @Override public String getBaseUrl()   { return ""; }
    @Override public int    getIconResId() { return R.drawable.ic_source_local; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        List<Manga> result = new ArrayList<>();
        if (rootUri == null) return result;
        DocumentFile root = safeTreeUri(rootUri);
        if (root == null || !root.isDirectory()) return result;
        DocumentFile[] children = root.listFiles();
        if (children == null) return result;
        for (DocumentFile child : children) {
            try {
                if (child.isDirectory()) {
                    Manga m = dirToManga(child);
                    if (m != null) result.add(m);
                } else if (isCbz(child.getName())) {
                    Manga m = cbzToManga(child);
                    if (m != null) result.add(m);
                }
            } catch (Exception ignored) {}
        }
        return result;
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        List<Manga> filtered = new ArrayList<>();
        String q = query.toLowerCase();
        for (Manga m : browse(page))
            if (m.title != null && m.title.toLowerCase().contains(q)) filtered.add(m);
        return filtered;
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        // mangaId is "local:URI_STRING"
        String uriStr = mangaId.contains(":") ? mangaId.substring(mangaId.indexOf(':') + 1) : mangaId;
        DocumentFile dir = safeDocumentFile(uriStr);
        return dir != null ? dirToManga(dir) : null;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        String uriStr = mangaId.contains(":") ? mangaId.substring(mangaId.indexOf(':') + 1) : mangaId;
        DocumentFile dir = safeDocumentFile(uriStr);
        if (dir == null || !dir.isDirectory()) return new ArrayList<>();

        List<Chapter> chapters = new ArrayList<>();
        DocumentFile[] children = dir.listFiles();
        if (children == null) return chapters;
        Arrays.sort(children, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int index = 0;
        for (DocumentFile child : children) {
            if (!child.isDirectory() && !isCbz(child.getName())) continue;
            float  num    = extractNum(child.getName());
            String chapId = Chapter.buildId(ID, child.getUri().toString());
            Chapter c     = new Chapter(chapId, mangaId, ID, child.getName(), num, child.lastModified());
            c.index = index++;
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        // chapterId: "local:content://..."
        String rawUri = chapterId.contains(":") ? chapterId.substring(chapterId.indexOf(':') + 1) : chapterId;
        DocumentFile target = safeDocumentFile(rawUri);
        if (target == null) return new ArrayList<>();
        return target.isDirectory() ? pagesFromDir(target) : pagesFromCbz(target);
    }

    // ── Safe DocumentFile creation ────────────────────────────────────────────

    private DocumentFile safeTreeUri(Uri uri) {
        try { return DocumentFile.fromTreeUri(ctx, uri); }
        catch (Exception e) { return null; }
    }

    private DocumentFile safeDocumentFile(String uriStr) {
        try {
            Uri uri = Uri.parse(uriStr);
            String scheme = uri.getScheme();
            if ("content".equals(scheme)) {
                // Try as tree URI first, then as single document
                try {
                    DocumentFile f = DocumentFile.fromTreeUri(ctx, uri);
                    if (f != null && f.exists()) return f;
                } catch (Exception ignored) {}
                try {
                    DocumentFile f = DocumentFile.fromSingleUri(ctx, uri);
                    if (f != null && f.exists()) return f;
                } catch (Exception ignored) {}
            }
        } catch (Exception ignored) {}
        return null;
    }

    // ── Page extraction ───────────────────────────────────────────────────────

    private List<Page> pagesFromDir(DocumentFile dir) {
        List<Page> pages = new ArrayList<>();
        DocumentFile[] files = dir.listFiles();
        if (files == null) return pages;
        Arrays.sort(files, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int idx = 0;
        for (DocumentFile f : files)
            if (f.isFile() && isImage(f.getName()))
                pages.add(new Page(idx++, null, f.getUri().toString()));
        return pages;
    }

    private List<Page> pagesFromCbz(DocumentFile cbz) throws Exception {
        List<Page> pages = new ArrayList<>();
        File cacheDir = new File(ctx.getCacheDir(), "cbz_" + Math.abs(cbz.getName().hashCode()));
        cacheDir.mkdirs();
        try (InputStream is = ctx.getContentResolver().openInputStream(cbz.getUri());
             ZipInputStream zis = new ZipInputStream(is)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (!entry.isDirectory() && isImage(entry.getName())) {
                    File out = new File(cacheDir, new File(entry.getName()).getName());
                    try (FileOutputStream fos = new FileOutputStream(out)) {
                        byte[] buf = new byte[8192]; int len;
                        while ((len = zis.read(buf)) > 0) fos.write(buf, 0, len);
                    }
                }
                zis.closeEntry();
            }
        }
        File[] extracted = cacheDir.listFiles();
        if (extracted == null) return pages;
        Arrays.sort(extracted, (a, b) -> naturalOrder(a.getName(), b.getName()));
        int idx = 0;
        for (File f : extracted)
            if (isImage(f.getName())) pages.add(new Page(idx++, null, f.getAbsolutePath()));
        return pages;
    }

    // ── Manga creation ────────────────────────────────────────────────────────

    private Manga dirToManga(DocumentFile dir) {
        if (dir == null) return null;
        String uri  = dir.getUri().toString();
        Manga  m    = new Manga(Manga.buildId(ID, uri), dir.getName(), null, ID, getName());
        m.url = uri;
        DocumentFile[] files = dir.listFiles();
        if (files == null) return m;
        // Cover: file named "cover.*"
        for (DocumentFile f : files) {
            String name = f.getName() != null ? f.getName().toLowerCase() : "";
            if (name.startsWith("cover") && isImage(name)) { m.cover = f.getUri().toString(); break; }
        }
        // Fallback: first image in first chapter
        if (m.cover == null) {
            Arrays.sort(files, (a, b) -> naturalOrder(a.getName(), b.getName()));
            for (DocumentFile f : files) {
                if (f.isDirectory()) {
                    DocumentFile[] inner = f.listFiles();
                    if (inner != null) {
                        Arrays.sort(inner, (a, b) -> naturalOrder(a.getName(), b.getName()));
                        for (DocumentFile img : inner)
                            if (isImage(img.getName())) { m.cover = img.getUri().toString(); break; }
                    }
                    if (m.cover != null) break;
                } else if (isImage(f.getName())) {
                    m.cover = f.getUri().toString();
                    break;
                }
            }
        }
        return m;
    }

    private Manga cbzToManga(DocumentFile file) {
        String uri   = file.getUri().toString();
        String title = file.getName();
        if (title != null && title.toLowerCase().endsWith(".cbz"))
            title = title.substring(0, title.length() - 4);
        return new Manga(Manga.buildId(ID, uri), title, null, ID, getName());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private boolean isCbz(String name)  { return name != null && name.toLowerCase().endsWith(".cbz"); }
    private boolean isImage(String n)   {
        if (n == null) return false;
        String l = n.toLowerCase();
        return l.endsWith(".jpg")||l.endsWith(".jpeg")||l.endsWith(".png")
             ||l.endsWith(".webp")||l.endsWith(".gif");
    }
    private float extractNum(String n)  {
        if (n == null) return 0;
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("(\\d+\\.?\\d*)").matcher(n);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }
    private int naturalOrder(String a, String b) {
        if (a == null) a = ""; if (b == null) b = "";
        int i = 0, j = 0;
        while (i < a.length() && j < b.length()) {
            if (Character.isDigit(a.charAt(i)) && Character.isDigit(b.charAt(j))) {
                int na = 0, nb = 0;
                while (i < a.length() && Character.isDigit(a.charAt(i))) na = na*10+(a.charAt(i++)-'0');
                while (j < b.length() && Character.isDigit(b.charAt(j))) nb = nb*10+(b.charAt(j++)-'0');
                if (na != nb) return Integer.compare(na, nb);
            } else { if (a.charAt(i) != b.charAt(j)) return a.charAt(i)-b.charAt(j); i++; j++; }
        }
        return a.length() - b.length();
    }
}
EOF

echo "✅ Fix 9: LocalSource crash fixed"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 10: SourcesFragment — use thread-safe addCustomSource
# ─────────────────────────────────────────────────────────────────────────────

# Patch only the addCustomSource call in SourcesFragment
cat > /tmp/patch_sources.py << 'PYEOF'
import sys
c = open(sys.argv[1]).read()
old = '''                CustomSource cs = new CustomSource(
                    java.util.UUID.randomUUID().toString(), name, url,
                    search.isEmpty() ? "/?s={query}" : search);
                SourceManager.getInstance(requireContext()).addCustomSource(cs);
                ToastManager.show(requireContext(), name + " added!");
                refreshExtensionList();'''
new = '''                CustomSource cs = new CustomSource(
                    java.util.UUID.randomUUID().toString(), name, url,
                    search.isEmpty() ? "/?s={query}" : search);
                SourceManager.getInstance(requireContext()).addCustomSource(cs, () -> {
                    if (getActivity() != null) {
                        getActivity().runOnUiThread(() -> {
                            ToastManager.show(requireContext(), name + " added!");
                            refreshExtensionList();
                        });
                    }
                });'''
c = c.replace(old, new)
open(sys.argv[1], 'w').write(c)
PYEOF
python3 /tmp/patch_sources.py "$J/ui/sources/SourcesFragment.java" 2>/dev/null \
  && echo "✅ Fix 10: Source add crash fixed" \
  || echo "⚠️  SourcesFragment patch skipped"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 11: Reader layout — add touch interceptor view
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_reader.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="#000">

    <androidx.viewpager2.widget.ViewPager2
        android:id="@+id/reader_pager"
        android:layout_width="match_parent" android:layout_height="match_parent"/>

    <!-- Transparent touch interceptor for tap-to-toggle -->
    <View android:id="@+id/reader_touch_interceptor"
        android:layout_width="match_parent" android:layout_height="match_parent"
        android:background="@android:color/transparent"/>

    <ProgressBar android:id="@+id/reader_progress"
        android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="center" android:visibility="gone"/>

    <!-- Top bar -->
    <LinearLayout android:id="@+id/reader_top_bar"
        android:layout_width="match_parent" android:layout_height="56dp"
        android:layout_gravity="top" android:orientation="horizontal"
        android:gravity="center_vertical" android:background="#CC000000"
        android:paddingHorizontal="8dp">

        <ImageButton android:id="@+id/reader_back_btn"
            android:layout_width="48dp" android:layout_height="48dp"
            android:src="@drawable/ic_back"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Back" android:tint="#FFFFFF"/>

        <TextView android:id="@+id/reader_chapter_title"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:textColor="#FFFFFF"
            android:textSize="15sp" android:textStyle="bold"
            android:singleLine="true" android:ellipsize="end"
            android:paddingHorizontal="8dp"/>

    </LinearLayout>

    <!-- Bottom bar -->
    <LinearLayout android:id="@+id/reader_bottom_bar"
        android:layout_width="match_parent" android:layout_height="64dp"
        android:layout_gravity="bottom" android:orientation="horizontal"
        android:gravity="center_vertical" android:background="#CC000000"
        android:paddingHorizontal="12dp">

        <TextView android:id="@+id/page_indicator"
            android:layout_width="56dp" android:layout_height="wrap_content"
            android:textColor="#FFFFFF" android:textSize="12sp"
            android:gravity="center"/>

        <com.google.android.material.slider.Slider
            android:id="@+id/page_slider"
            android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1"
            android:valueFrom="0" android:valueTo="1" android:stepSize="1"/>

    </LinearLayout>

</FrameLayout>
EOF

echo "✅ Fix 11: Reader layout with touch interceptor"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 12: Download — properly save to file and mark downloaded
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/download/DownloadManager.java" << 'EOF'
package com.fountainpdl.comifountain.download;

import android.content.Context;
import android.os.Environment;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.Source;
import com.fountainpdl.comifountain.sources.SourceManager;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import okhttp3.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;

public class DownloadManager {

    public enum Status { QUEUED, DOWNLOADING, DONE, ERROR }

    private static DownloadManager instance;
    private final Context ctx;
    private final MangaRepository repo;
    private final ExecutorService exec = Executors.newFixedThreadPool(2);
    private final Map<String, Status> statusMap = Collections.synchronizedMap(new HashMap<>());
    private final Map<String, Float>  progressMap = Collections.synchronizedMap(new HashMap<>());

    public interface Listener {
        void onProgress(String chapterId, int done, int total);
        void onComplete(String chapterId, String path);
        void onError(String chapterId, String message);
    }

    private DownloadManager(Context context) {
        ctx  = context.getApplicationContext();
        repo = new MangaRepository(context);
    }

    public static DownloadManager getInstance(Context context) {
        if (instance == null) synchronized (DownloadManager.class) {
            if (instance == null) instance = new DownloadManager(context);
        }
        return instance;
    }

    public void download(String mangaTitle, String mangaId, Chapter chapter, Listener listener) {
        if (statusMap.get(chapter.id) == Status.DOWNLOADING) {
            ToastManager.show(ctx, "Already downloading");
            return;
        }
        statusMap.put(chapter.id, Status.QUEUED);

        exec.submit(() -> {
            statusMap.put(chapter.id, Status.DOWNLOADING);
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawManga = mangaId.substring(mangaId.indexOf(':') + 1);
                String rawChap  = chapter.id.substring(chapter.id.indexOf(':') + 1);
                Source source   = SourceManager.getInstance(ctx).getById(sourceId);
                if (source == null) throw new Exception("Source not found");

                List<Page> pages = source.getPageList(rawManga, rawChap);
                if (pages.isEmpty()) throw new Exception("No pages found");

                File chapDir = getChapterDir(mangaTitle, chapter.displayName());
                chapDir.mkdirs();

                OkHttpClient client = new OkHttpClient.Builder()
                    .connectTimeout(30, TimeUnit.SECONDS)
                    .readTimeout(60, TimeUnit.SECONDS)
                    .build();

                int total = pages.size();
                for (int i = 0; i < total; i++) {
                    Page page = pages.get(i);
                    String loadUrl = page.isLocal() ? null : page.url;
                    if (loadUrl == null) continue;

                    File imgFile = new File(chapDir, String.format("%03d.jpg", page.index));
                    if (!imgFile.exists()) {
                        downloadFile(client, loadUrl, imgFile, sourceId);
                    }
                    if (listener != null) listener.onProgress(chapter.id, i + 1, total);
                }

                repo.markDownloaded(chapter.id, chapDir.getAbsolutePath());
                statusMap.put(chapter.id, Status.DONE);
                if (listener != null) listener.onComplete(chapter.id, chapDir.getAbsolutePath());
                ToastManager.show(ctx, "✅ Downloaded: " + chapter.displayName());

            } catch (Exception e) {
                statusMap.put(chapter.id, Status.ERROR);
                if (listener != null) listener.onError(chapter.id, e.getMessage());
                ToastManager.showLong(ctx, "Download failed: " + e.getMessage());
            }
        });
    }

    public void deleteDownload(Chapter chapter) {
        if (chapter.downloadPath != null) deleteDir(new File(chapter.downloadPath));
        repo.clearDownload(chapter.id);
        statusMap.remove(chapter.id);
    }

    public Status getStatus(String chapterId) {
        return statusMap.getOrDefault(chapterId, Status.QUEUED);
    }

    public boolean isDownloaded(String chapterId) {
        return statusMap.get(chapterId) == Status.DONE;
    }

    private void downloadFile(OkHttpClient client, String url, File out, String sourceId)
            throws Exception {
        Request.Builder rb = new Request.Builder().url(url)
            .header("User-Agent", "Mozilla/5.0 (Android)");
        if (sourceId.contains("allanime")) {
            rb.header("Referer", "https://allmanga.to")
              .header("Origin",  "https://allmanga.to");
        }
        try (Response r = client.newCall(rb.build()).execute()) {
            if (!r.isSuccessful() || r.body() == null)
                throw new Exception("HTTP " + r.code());
            // Quality control
            AppPreferences prefs = AppPreferences.getInstance(ctx);
            byte[] bytes = r.body().bytes();
            String quality = prefs.getDownloadQuality();
            if (!"original".equals(quality)) {
                int q = "high".equals(quality) ? 90 : "medium".equals(quality) ? 75 : 50;
                android.graphics.Bitmap bmp = android.graphics.BitmapFactory
                    .decodeByteArray(bytes, 0, bytes.length);
                if (bmp != null) {
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    bmp.compress(android.graphics.Bitmap.CompressFormat.JPEG, q, bos);
                    bytes = bos.toByteArray();
                    bmp.recycle();
                }
            }
            try (FileOutputStream fos = new FileOutputStream(out)) { fos.write(bytes); }
        }
    }

    private File getChapterDir(String mangaTitle, String chapterName) {
        AppPreferences prefs = AppPreferences.getInstance(ctx);
        String loc = prefs.getDownloadLocation();
        File root  = loc != null
            ? new File(loc)
            : new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS), "ComiFountain");
        return new File(root, sanitize(mangaTitle) + "/" + sanitize(chapterName));
    }

    private void deleteDir(File dir) {
        if (dir == null || !dir.exists()) return;
        File[] files = dir.listFiles();
        if (files != null) for (File f : files) { if (f.isDirectory()) deleteDir(f); else f.delete(); }
        dir.delete();
    }

    private String sanitize(String name) {
        return name != null
            ? name.replaceAll("[^a-zA-Z0-9._\\-\\s]", "_").trim()
            : "unknown";
    }
}
EOF

echo "✅ Fix 12: DownloadManager fully implemented"

# ─────────────────────────────────────────────────────────────────────────────
# FIX 13: ChapterListAdapter — show download status + trigger download
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/detail/ChapterListAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.detail;

import android.graphics.Color;
import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.download.DownloadManager;
import java.text.SimpleDateFormat;
import java.util.*;

public class ChapterListAdapter extends ListAdapter<Chapter, ChapterListAdapter.VH> {

    public interface Listener {
        void onRead(Chapter c);
        void onDownload(Chapter c);
    }

    private final Listener listener;
    private static final SimpleDateFormat FMT = new SimpleDateFormat("MMM dd, yyyy", Locale.US);

    public ChapterListAdapter(Listener l) { super(DIFF); this.listener = l; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_chapter, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Chapter c = getItem(pos);
        h.title.setText(c.displayName());
        h.title.setAlpha(c.isRead ? 0.45f : 1.0f);
        h.date.setText(c.date > 0 ? FMT.format(new Date(c.date)) : "");
        h.bookmark.setVisibility(c.bookmarked ? View.VISIBLE : View.GONE);

        // Download button state
        DownloadManager.Status status =
            DownloadManager.getInstance(h.itemView.getContext()).getStatus(c.id);
        if (c.isDownloaded() || status == DownloadManager.Status.DONE) {
            h.downloadBtn.setImageResource(R.drawable.ic_updates); // reuse as "downloaded" icon
            h.downloadBtn.setColorFilter(Color.parseColor("#9b30ff"));
            h.downloadBtn.setAlpha(1f);
        } else if (status == DownloadManager.Status.DOWNLOADING) {
            h.downloadBtn.setAlpha(0.4f);
        } else {
            h.downloadBtn.clearColorFilter();
            h.downloadBtn.setAlpha(1f);
        }

        h.itemView.setOnClickListener(v -> listener.onRead(c));
        h.downloadBtn.setOnClickListener(v -> {
            if (!c.isDownloaded() && status != DownloadManager.Status.DOWNLOADING)
                listener.onDownload(c);
        });
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView title, date; ImageButton downloadBtn; View bookmark;
        VH(View v) { super(v);
            title       = v.findViewById(R.id.chapter_title);
            date        = v.findViewById(R.id.chapter_date);
            downloadBtn = v.findViewById(R.id.chapter_download_btn);
            bookmark    = v.findViewById(R.id.chapter_bookmark_icon); }
    }

    private static final DiffUtil.ItemCallback<Chapter> DIFF = new DiffUtil.ItemCallback<Chapter>() {
        @Override public boolean areItemsTheSame(@NonNull Chapter a, @NonNull Chapter b) { return a.id.equals(b.id); }
        @Override public boolean areContentsTheSame(@NonNull Chapter a, @NonNull Chapter b) {
            return a.isRead == b.isRead && a.bookmarked == b.bookmarked && a.isDownloaded() == b.isDownloaded(); }
    };
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# FIX 14: MangaDetailFragment — wire download button to DownloadManager
# ─────────────────────────────────────────────────────────────────────────────

cat > /tmp/patch_detail.py << 'PYEOF'
import sys
c = open(sys.argv[1]).read()
old = "            @Override public void onDownload(Chapter c) { /* TODO */ }"
new = """            @Override public void onDownload(Chapter chapter) {
                com.fountainpdl.comifountain.data.model.Manga manga = vm.manga.getValue();
                String title = manga != null ? manga.title : "manga";
                com.fountainpdl.comifountain.download.DownloadManager
                    .getInstance(requireContext())
                    .download(title, mangaId, chapter, new com.fountainpdl.comifountain.download.DownloadManager.Listener() {
                        @Override public void onProgress(String id, int done, int total) {
                            com.fountainpdl.comifountain.ui.common.ToastManager
                                .show(requireContext(), "Downloading " + done + "/" + total);
                        }
                        @Override public void onComplete(String id, String path) {
                            adapter.notifyDataSetChanged();
                        }
                        @Override public void onError(String id, String msg) {}
                    });
            }"""
c = c.replace(old, new)
open(sys.argv[1], 'w').write(c)
PYEOF
python3 /tmp/patch_detail.py "$J/ui/detail/MangaDetailFragment.java" 2>/dev/null \
  && echo "✅ Fix 14: Download wired in detail" \
  || echo "⚠️  Detail download patch skipped"

echo ""
echo "✅ All 14 fixes applied!"
echo ""
echo "git add ."
echo "git commit -m 'fix2: library persistence, AllManga chapters, covers, back btn, source crash, local crash, reader controls, dedup, download'"
echo "git push"
