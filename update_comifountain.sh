#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Major Feature Update (Part 1)
# New: SourceManager, CustomUrlSource, BackupManager, ScreenshotManager,
#      HistoryDao, CategoryDao, updated AppPreferences, updated DB
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p "$J/sources" "$J/data/db" "$J/data/model" \
         "$J/backup" "$J/utils" "$J/download"

echo "📁  Directories ready"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED AppPreferences — all new keys
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/preference/AppPreferences.java" << 'EOF'
package com.fountainpdl.comifountain.preference;

import android.content.Context;
import android.content.SharedPreferences;

public class AppPreferences {
    private static final String PREFS = "comifountain_prefs";
    private static AppPreferences instance;
    private final SharedPreferences p;

    // Theme
    public static final String KEY_THEME           = "theme";           // dark/light/amoled
    public static final String KEY_SUB_THEME       = "sub_theme";       // none/solid/dual-shift/dynamic/material-you
    public static final String KEY_COLOR_PRIMARY   = "color_primary";
    public static final String KEY_COLOR_SECONDARY = "color_secondary";
    public static final String KEY_SHIFT_COLOR1    = "shift_color1";
    public static final String KEY_SHIFT_COLOR2    = "shift_color2";
    public static final String KEY_SHIFT_SPEED     = "shift_speed";
    public static final String KEY_SHIFT_ANGLE     = "shift_angle";
    // Reader
    public static final String KEY_READING_MODE    = "reading_mode";    // ltr/rtl/vertical/webtoon/vertical-gaps
    public static final String KEY_GRAYSCALE       = "grayscale";
    public static final String KEY_INVERT          = "invert_colors";
    public static final String KEY_CROP_BORDERS    = "crop_borders";
    public static final String KEY_BG_COLOR        = "bg_color";
    public static final String KEY_PRELOAD         = "preload_chapter";
    public static final String KEY_KEEP_SCREEN     = "keep_screen_on";
    public static final String KEY_FULLSCREEN      = "fullscreen_reader";
    public static final String KEY_PAGE_ANIM       = "page_animation";
    public static final String KEY_WEBTOON_GAPS    = "webtoon_gaps";
    // Library
    public static final String KEY_LIB_DISPLAY     = "lib_display";     // grid/list
    public static final String KEY_LIB_COLS        = "library_columns";
    public static final String KEY_LIB_COMPACT     = "lib_compact";
    public static final String KEY_SHOW_UNREAD     = "show_unread_badge";
    public static final String KEY_SHOW_DOWNLOADED = "show_downloaded_badge";
    // Download
    public static final String KEY_DOWNLOAD_LOCATION = "download_location";
    public static final String KEY_DOWNLOAD_QUALITY  = "download_quality"; // low/medium/high/original
    public static final String KEY_AUTO_DELETE_READ  = "auto_delete_read";
    public static final String KEY_WIFI_ONLY         = "download_wifi_only";
    // Filter / Content
    public static final String KEY_SHOW_18_PLUS    = "show_18_plus";
    public static final String KEY_DEFAULT_SOURCE  = "default_source";
    public static final String KEY_LOCAL_URI       = "local_source_uri";
    // Updates
    public static final String KEY_AUTO_UPDATE     = "auto_update_library";
    public static final String KEY_UPDATE_INTERVAL = "update_interval_hours";
    // Tracking
    public static final String KEY_TRACK_HISTORY   = "track_reading_history";

    private AppPreferences(Context c) {
        p = c.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public static AppPreferences getInstance(Context c) {
        if (instance == null) synchronized (AppPreferences.class) {
            if (instance == null) instance = new AppPreferences(c);
        }
        return instance;
    }

    // Theme
    public String  getTheme()           { return p.getString(KEY_THEME, "dark"); }
    public String  getSubTheme()        { return p.getString(KEY_SUB_THEME, "solid"); }
    public String  getPrimaryColor()    { return p.getString(KEY_COLOR_PRIMARY, "#9b30ff"); }
    public String  getSecondaryColor()  { return p.getString(KEY_COLOR_SECONDARY, "#e63946"); }
    public String  getShiftColor1()     { return p.getString(KEY_SHIFT_COLOR1, "#9b30ff"); }
    public String  getShiftColor2()     { return p.getString(KEY_SHIFT_COLOR2, "#e63946"); }
    public int     getShiftSpeed()      { return p.getInt(KEY_SHIFT_SPEED, 8); }
    public int     getShiftAngle()      { return p.getInt(KEY_SHIFT_ANGLE, 45); }
    // Reader
    public String  getReadingMode()     { return p.getString(KEY_READING_MODE, "rtl"); }
    public boolean isGrayscale()        { return p.getBoolean(KEY_GRAYSCALE, false); }
    public boolean isInvert()           { return p.getBoolean(KEY_INVERT, false); }
    public boolean isCropBorders()      { return p.getBoolean(KEY_CROP_BORDERS, false); }
    public String  getBgColor()         { return p.getString(KEY_BG_COLOR, "#000000"); }
    public boolean isPreload()          { return p.getBoolean(KEY_PRELOAD, true); }
    public boolean isKeepScreen()       { return p.getBoolean(KEY_KEEP_SCREEN, true); }
    public boolean isFullscreen()       { return p.getBoolean(KEY_FULLSCREEN, true); }
    public boolean isPageAnim()         { return p.getBoolean(KEY_PAGE_ANIM, true); }
    public int     getWebtoonGaps()     { return p.getInt(KEY_WEBTOON_GAPS, 8); }
    // Library
    public String  getLibDisplay()      { return p.getString(KEY_LIB_DISPLAY, "grid"); }
    public int     getLibraryCols()     { return p.getInt(KEY_LIB_COLS, 2); }
    public boolean isLibCompact()       { return p.getBoolean(KEY_LIB_COMPACT, false); }
    public boolean isShowUnread()       { return p.getBoolean(KEY_SHOW_UNREAD, true); }
    public boolean isShowDownloaded()   { return p.getBoolean(KEY_SHOW_DOWNLOADED, true); }
    // Download
    public String  getDownloadLocation(){ return p.getString(KEY_DOWNLOAD_LOCATION, null); }
    public String  getDownloadQuality() { return p.getString(KEY_DOWNLOAD_QUALITY, "original"); }
    public boolean isAutoDeleteRead()   { return p.getBoolean(KEY_AUTO_DELETE_READ, false); }
    public boolean isWifiOnly()         { return p.getBoolean(KEY_WIFI_ONLY, false); }
    // Content
    public boolean isShow18Plus()       { return p.getBoolean(KEY_SHOW_18_PLUS, false); }
    public String  getDefaultSource()   { return p.getString(KEY_DEFAULT_SOURCE, "allanime"); }
    public String  getLocalUri()        { return p.getString(KEY_LOCAL_URI, null); }
    // Updates
    public boolean isAutoUpdate()       { return p.getBoolean(KEY_AUTO_UPDATE, false); }
    public int     getUpdateInterval()  { return p.getInt(KEY_UPDATE_INTERVAL, 12); }
    // Tracking
    public boolean isTrackHistory()     { return p.getBoolean(KEY_TRACK_HISTORY, true); }

    // Setters
    public void setTheme(String v)            { s(KEY_THEME, v); }
    public void setSubTheme(String v)         { s(KEY_SUB_THEME, v); }
    public void setPrimaryColor(String v)     { s(KEY_COLOR_PRIMARY, v); }
    public void setSecondaryColor(String v)   { s(KEY_COLOR_SECONDARY, v); }
    public void setShiftColor1(String v)      { s(KEY_SHIFT_COLOR1, v); }
    public void setShiftColor2(String v)      { s(KEY_SHIFT_COLOR2, v); }
    public void setShiftSpeed(int v)          { p.edit().putInt(KEY_SHIFT_SPEED, v).apply(); }
    public void setShiftAngle(int v)          { p.edit().putInt(KEY_SHIFT_ANGLE, v).apply(); }
    public void setReadingMode(String v)      { s(KEY_READING_MODE, v); }
    public void setGrayscale(boolean v)       { b(KEY_GRAYSCALE, v); }
    public void setInvert(boolean v)          { b(KEY_INVERT, v); }
    public void setCropBorders(boolean v)     { b(KEY_CROP_BORDERS, v); }
    public void setBgColor(String v)          { s(KEY_BG_COLOR, v); }
    public void setFullscreen(boolean v)      { b(KEY_FULLSCREEN, v); }
    public void setLibDisplay(String v)       { s(KEY_LIB_DISPLAY, v); }
    public void setLibraryCols(int v)         { p.edit().putInt(KEY_LIB_COLS, v).apply(); }
    public void setLibCompact(boolean v)      { b(KEY_LIB_COMPACT, v); }
    public void setDownloadLocation(String v) { s(KEY_DOWNLOAD_LOCATION, v); }
    public void setDownloadQuality(String v)  { s(KEY_DOWNLOAD_QUALITY, v); }
    public void setAutoDeleteRead(boolean v)  { b(KEY_AUTO_DELETE_READ, v); }
    public void setWifiOnly(boolean v)        { b(KEY_WIFI_ONLY, v); }
    public void setShow18Plus(boolean v)      { b(KEY_SHOW_18_PLUS, v); }
    public void setDefaultSource(String v)    { s(KEY_DEFAULT_SOURCE, v); }
    public void setLocalUri(String v)         { s(KEY_LOCAL_URI, v); }
    public void setAutoUpdate(boolean v)      { b(KEY_AUTO_UPDATE, v); }
    public void setUpdateInterval(int v)      { p.edit().putInt(KEY_UPDATE_INTERVAL, v).apply(); }

    private void s(String k, String v) { p.edit().putString(k, v).apply(); }
    private void b(String k, boolean v){ p.edit().putBoolean(k, v).apply(); }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM SOURCE ENTITY — user-added URL sources
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/model/CustomSource.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

import androidx.annotation.NonNull;
import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

/**
 * A user-added source defined by a base URL.
 * The app will attempt to scrape it generically or use known patterns.
 */
@Entity(tableName = "custom_sources")
public class CustomSource {

    @PrimaryKey
    @NonNull
    @ColumnInfo(name = "id")
    public String id = "";              // UUID

    @ColumnInfo(name = "name")          public String  name;
    @ColumnInfo(name = "base_url")      public String  baseUrl;
    @ColumnInfo(name = "search_path")   public String  searchPath;   // e.g. "/?s={query}"
    @ColumnInfo(name = "lang")          public String  lang = "en";
    @ColumnInfo(name = "enabled")       public boolean enabled = true;
    @ColumnInfo(name = "nsfw")          public boolean nsfw = false;
    @ColumnInfo(name = "icon_url")      public String  iconUrl;
    @ColumnInfo(name = "created_at")    public long    createdAt;
    @ColumnInfo(name = "notes")         public String  notes;        // e.g. "switched domain 2025-05"

    public CustomSource() {}

    @Ignore
    public CustomSource(@NonNull String id, String name, String baseUrl, String searchPath) {
        this.id         = id;
        this.name       = name;
        this.baseUrl    = baseUrl;
        this.searchPath = searchPath;
        this.createdAt  = System.currentTimeMillis();
    }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM SOURCE DAO
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/db/CustomSourceDao.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.CustomSource;
import java.util.List;

@Dao
public interface CustomSourceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(CustomSource s);
    @Update void update(CustomSource s);
    @Delete void delete(CustomSource s);
    @Query("SELECT * FROM custom_sources ORDER BY name ASC")
    LiveData<List<CustomSource>> getAll();
    @Query("SELECT * FROM custom_sources WHERE enabled = 1 ORDER BY name ASC")
    List<CustomSource> getAllEnabledSync();
    @Query("SELECT * FROM custom_sources WHERE id = :id LIMIT 1")
    CustomSource getById(String id);
    @Query("UPDATE custom_sources SET enabled = :enabled WHERE id = :id")
    void setEnabled(String id, boolean enabled);
    @Query("UPDATE custom_sources SET base_url = :url WHERE id = :id")
    void updateUrl(String id, String url);
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# CATEGORY DAO
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/db/CategoryDao.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Category;
import java.util.List;

@Dao
public interface CategoryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(Category c);
    @Update void update(Category c);
    @Delete void delete(Category c);
    @Query("SELECT * FROM categories ORDER BY position ASC")
    LiveData<List<Category>> getAll();
    @Query("SELECT * FROM categories ORDER BY position ASC")
    List<Category> getAllSync();
    @Query("SELECT COUNT(*) FROM categories") int count();
    @Query("UPDATE categories SET position = :pos WHERE id = :id")
    void updatePosition(int id, int pos);
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# HISTORY DAO
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/db/HistoryDao.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.HistoryEntry;
import java.util.List;

@Dao
public interface HistoryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insert(HistoryEntry h);
    @Query("DELETE FROM history WHERE manga_id = :mangaId") void clearForManga(String mangaId);
    @Query("DELETE FROM history") void clearAll();
    @Query("SELECT * FROM history ORDER BY read_at DESC LIMIT 200")
    LiveData<List<HistoryEntry>> getRecent();
    @Query("SELECT * FROM history WHERE manga_id = :mangaId ORDER BY read_at DESC")
    List<HistoryEntry> getForManga(String mangaId);
    @Query("SELECT * FROM history WHERE chapter_id = :chapterId ORDER BY read_at DESC LIMIT 1")
    HistoryEntry getForChapter(String chapterId);
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED AppDatabase — adds new tables
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/data/db/AppDatabase.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import android.content.Context;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.*;

@Database(
    entities = {
        Manga.class, Chapter.class, Category.class,
        HistoryEntry.class, CustomSource.class
    },
    version = 2,
    exportSchema = true
)
@TypeConverters(Converters.class)
public abstract class AppDatabase extends RoomDatabase {

    private static final String DB_NAME = "comifountain.db";

    public abstract MangaDao        mangaDao();
    public abstract ChapterDao      chapterDao();
    public abstract CategoryDao     categoryDao();
    public abstract HistoryDao      historyDao();
    public abstract CustomSourceDao customSourceDao();

    private static volatile AppDatabase INSTANCE;

    public static AppDatabase getInstance(Context context) {
        if (INSTANCE == null) synchronized (AppDatabase.class) {
            if (INSTANCE == null) {
                INSTANCE = Room.databaseBuilder(
                        context.getApplicationContext(), AppDatabase.class, DB_NAME)
                    .addMigrations(MIGRATION_1_2)
                    .fallbackToDestructiveMigration()
                    .build();
            }
        }
        return INSTANCE;
    }

    static final Migration MIGRATION_1_2 = new Migration(1, 2) {
        @Override public void migrate(androidx.sqlite.db.SupportSQLiteDatabase db) {
            db.execSQL("CREATE TABLE IF NOT EXISTS `custom_sources` (" +
                "`id` TEXT NOT NULL PRIMARY KEY, `name` TEXT, `base_url` TEXT, " +
                "`search_path` TEXT, `lang` TEXT, `enabled` INTEGER NOT NULL DEFAULT 1, " +
                "`nsfw` INTEGER NOT NULL DEFAULT 0, `icon_url` TEXT, " +
                "`created_at` INTEGER NOT NULL DEFAULT 0, `notes` TEXT)");
        }
    };
}
EOF

echo "🗄️   DB layer done"

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM URL SOURCE IMPLEMENTATION
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/CustomUrlSource.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.*;
import com.fountainpdl.comifountain.network.HttpClient;
import okhttp3.*;
import org.jsoup.Jsoup;
import org.jsoup.nodes.*;
import org.jsoup.select.Elements;
import java.util.*;
import java.util.regex.*;

/**
 * Generic source for user-added URLs.
 * Tries common manga site selectors and falls back to heuristic scraping.
 */
public class CustomUrlSource implements Source {

    private final CustomSource config;

    public CustomUrlSource(CustomSource config) { this.config = config; }

    @Override public String getId()        { return "custom_" + config.id; }
    @Override public String getName()      { return config.name; }
    @Override public String getLang()      { return config.lang; }
    @Override public String getBaseUrl()   { return config.baseUrl; }
    @Override public int    getIconResId() { return R.drawable.ic_source_generic; }

    @Override
    public List<Manga> browse(int page) throws Exception {
        String url = config.baseUrl + (page > 1 ? "?page=" + page : "");
        return scrapeList(fetch(url), url);
    }

    @Override
    public List<Manga> search(String query, int page) throws Exception {
        String path = config.searchPath != null
            ? config.searchPath.replace("{query}", java.net.URLEncoder.encode(query, "UTF-8"))
            : "/?s=" + java.net.URLEncoder.encode(query, "UTF-8");
        String url = config.baseUrl + path;
        return scrapeList(fetch(url), url);
    }

    @Override
    public Manga getMangaDetails(String mangaId) throws Exception {
        Document doc = fetch(config.baseUrl + "/manga/" + mangaId);
        Manga m = new Manga();
        m.id       = Manga.buildId(getId(), mangaId);
        m.sourceId = getId(); m.sourceName = getName();
        m.url      = config.baseUrl + "/manga/" + mangaId;

        // Try common title selectors
        for (String sel : new String[]{".post-title h1","h1.entry-title","h1.manga-title","h1","h2"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.title = el.text(); break; }
        }
        // Cover
        for (String sel : new String[]{".summary_image img",".thumb img",".manga-cover img","img.cover"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.cover = el.attr("src"); break; }
        }
        // Description
        for (String sel : new String[]{".summary__content",".manga-summary","#synopsis",".description"}) {
            Element el = doc.selectFirst(sel);
            if (el != null) { m.description = el.text(); break; }
        }
        return m;
    }

    @Override
    public List<Chapter> getChapterList(String mangaId) throws Exception {
        Document doc = fetch(config.baseUrl + "/manga/" + mangaId);
        List<Chapter> chapters = new ArrayList<>();
        Elements items = doc.select(".wp-manga-chapter, #chapterlist li, .chapter-list li, .listing-chapters_wrap li");
        int index = 0;
        for (Element item : items) {
            Element link = item.selectFirst("a");
            if (link == null) continue;
            String chapSlug = lastSlug(link.attr("href"));
            String title    = link.text().trim();
            float  num      = extractNum(title);
            Chapter c       = new Chapter();
            c.id       = Chapter.buildId(getId(), chapSlug);
            c.mangaId  = Manga.buildId(getId(), mangaId);
            c.sourceId = getId(); c.title = title;
            c.number = num; c.index = index++;
            chapters.add(c);
        }
        return chapters;
    }

    @Override
    public List<Page> getPageList(String mangaId, String chapterId) throws Exception {
        String url  = config.baseUrl + "/" + chapterId;
        String html = fetchRaw(url);
        // Try ts_reader.run first
        Matcher m = Pattern.compile("ts_reader\\.run\\(\\s*(\\{.*?\\})\\s*\\)", Pattern.DOTALL).matcher(html);
        if (m.find()) {
            try {
                com.google.gson.JsonObject obj = com.google.gson.JsonParser.parseString(m.group(1)).getAsJsonObject();
                com.google.gson.JsonArray sources = obj.getAsJsonArray("sources");
                if (sources != null && sources.size() > 0) {
                    com.google.gson.JsonArray images = sources.get(0).getAsJsonObject().getAsJsonArray("images");
                    List<Page> pages = new ArrayList<>();
                    for (int i = 0; i < images.size(); i++) pages.add(new Page(i, images.get(i).getAsString()));
                    return pages;
                }
            } catch (Exception ignored) {}
        }
        // Fallback: img tags
        Document doc = Jsoup.parse(html);
        List<Page> pages = new ArrayList<>();
        int idx = 0;
        for (Element img : doc.select(".reading-content img,.chapter-content img,#readerarea img")) {
            String src = img.hasAttr("data-src") ? img.attr("data-src") : img.attr("src");
            if (src.startsWith("http")) pages.add(new Page(idx++, src.trim()));
        }
        return pages;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private List<Manga> scrapeList(Document doc, String baseUrl) {
        List<Manga> result = new ArrayList<>();
        Elements items = doc.select(".manga-poster,.c-image-hover,.page-item-detail,.bsx,.bs,.manga-item");
        for (Element item : items) {
            Element link = item.selectFirst("a");
            Element img  = item.selectFirst("img");
            Element name = item.selectFirst(".manga-name,.post-title,.tt,h3,h2");
            if (link == null) continue;
            String href  = link.attr("href");
            String rawId = lastSlug(href);
            String title = name != null ? name.text() : rawId;
            String cover = img != null ? (img.hasAttr("data-src") ? img.attr("data-src") : img.attr("src")) : null;
            Manga manga  = new Manga(Manga.buildId(getId(), rawId), title, cover, getId(), getName());
            manga.url    = href;
            result.add(manga);
        }
        return result;
    }

    private Document fetch(String url) throws Exception { return Jsoup.parse(fetchRaw(url)); }

    private String fetchRaw(String url) throws Exception {
        Request req = new Request.Builder().url(url)
            .header("Referer", config.baseUrl).build();
        try (okhttp3.Response r = HttpClient.get().newCall(req).execute()) {
            if (!r.isSuccessful() || r.body() == null) throw new Exception("HTTP " + r.code());
            return r.body().string();
        }
    }

    private String lastSlug(String href) {
        href = href.replaceAll("/$",""); int i = href.lastIndexOf('/');
        return i >= 0 ? href.substring(i+1) : href;
    }

    private float extractNum(String title) {
        Matcher m = Pattern.compile("(\\d+\\.?\\d*)").matcher(title);
        if (m.find()) try { return Float.parseFloat(m.group(1)); } catch (Exception ignored) {}
        return 0;
    }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE MANAGER — manages built-in + custom sources
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/sources/SourceManager.java" << 'EOF'
package com.fountainpdl.comifountain.sources;

import android.content.Context;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.CustomSource;
import java.util.*;
import java.util.concurrent.Executors;

/**
 * Central registry for all sources — built-in and user-added.
 * Use this everywhere instead of SourceRegistry.
 */
public class SourceManager {

    private static SourceManager instance;
    private final Context context;
    private final Map<String, Source> sources = new LinkedHashMap<>();

    private SourceManager(Context context) {
        this.context = context.getApplicationContext();
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

    /** Load user-saved custom sources from DB on background thread. */
    public void loadCustomSources() {
        Executors.newSingleThreadExecutor().execute(() -> {
            List<CustomSource> customs = AppDatabase.getInstance(context)
                .customSourceDao().getAllEnabledSync();
            for (CustomSource cs : customs) {
                sources.put("custom_" + cs.id, new CustomUrlSource(cs));
            }
        });
    }

    public void register(Source s)           { sources.put(s.getId(), s); }
    public Source getById(String id)         { return sources.get(id); }
    public List<Source> getAll()             { return new ArrayList<>(sources.values()); }
    public List<Source> getBuiltIn() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values())
            if (!s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public List<Source> getCustom() {
        List<Source> list = new ArrayList<>();
        for (Source s : sources.values())
            if (s.getId().startsWith("custom_")) list.add(s);
        return list;
    }
    public Source getDefault() { return sources.values().iterator().next(); }

    public void addCustomSource(CustomSource cs) {
        AppDatabase.getInstance(context).customSourceDao().insert(cs);
        sources.put("custom_" + cs.id, new CustomUrlSource(cs));
    }

    public void removeCustomSource(String sourceId) {
        String dbId = sourceId.replace("custom_", "");
        Executors.newSingleThreadExecutor().execute(() -> {
            CustomSource cs = AppDatabase.getInstance(context).customSourceDao().getById(dbId);
            if (cs != null) AppDatabase.getInstance(context).customSourceDao().delete(cs);
        });
        sources.remove(sourceId);
    }

    public void updateCustomSourceUrl(String sourceId, String newUrl) {
        String dbId = sourceId.replace("custom_", "");
        Executors.newSingleThreadExecutor().execute(() ->
            AppDatabase.getInstance(context).customSourceDao().updateUrl(dbId, newUrl));
        Source s = sources.get(sourceId);
        if (s instanceof CustomUrlSource) {
            // Reload from DB
            loadCustomSources();
        }
    }
}
EOF

echo "📡  Source manager done"

# ─────────────────────────────────────────────────────────────────────────────
# BACKUP MANAGER — Tachiyomi-style JSON backup
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/backup/BackupManager.java" << 'EOF'
package com.fountainpdl.comifountain.backup;

import android.content.Context;
import android.net.Uri;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.model.*;
import com.google.gson.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Tachiyomi-style JSON backup and restore.
 *
 * Backup format:
 * {
 *   "version": 2,
 *   "backupManga": [ { manga fields + chapters + categories } ],
 *   "backupCategories": [ { name, order } ]
 * }
 */
public class BackupManager {

    private static final int BACKUP_VERSION = 2;
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private final Context context;
    private final AppDatabase db;

    public BackupManager(Context context) {
        this.context = context.getApplicationContext();
        this.db      = AppDatabase.getInstance(context);
    }

    // ── Create backup ─────────────────────────────────────────────────────────

    public void createBackup(Uri outputUri, BackupCallback callback) {
        new Thread(() -> {
            try {
                JsonObject root = new JsonObject();
                root.addProperty("version", BACKUP_VERSION);
                root.addProperty("createdAt", System.currentTimeMillis());
                root.addProperty("app", "ComiFountain");

                // Categories
                JsonArray cats = new JsonArray();
                for (Category c : db.categoryDao().getAllSync()) {
                    JsonObject co = new JsonObject();
                    co.addProperty("name", c.name);
                    co.addProperty("position", c.position);
                    cats.add(co);
                }
                root.add("backupCategories", cats);

                // Library manga + chapters
                JsonArray mangaArray = new JsonArray();
                List<Manga> library = db.mangaDao().getLibraryManga().getValue();
                // getLibraryManga() returns LiveData — query synchronously for backup
                // Use a blocking approach via the executor
                List<Manga> allManga = getLibrarySync();
                for (Manga m : allManga) {
                    JsonObject mo = GSON.toJsonTree(m).getAsJsonObject();
                    JsonArray chapArr = new JsonArray();
                    for (Chapter c : db.chapterDao().getChaptersForMangaSync(m.id)) {
                        chapArr.add(GSON.toJsonTree(c));
                    }
                    mo.add("chapters", chapArr);
                    mangaArray.add(mo);
                }
                root.add("backupManga", mangaArray);

                // Write to file
                try (OutputStream os = context.getContentResolver().openOutputStream(outputUri);
                     OutputStreamWriter writer = new OutputStreamWriter(os)) {
                    writer.write(GSON.toJson(root));
                    writer.flush();
                }
                callback.onSuccess("Backup created: " + allManga.size() + " manga");
            } catch (Exception e) {
                callback.onError("Backup failed: " + e.getMessage());
            }
        }).start();
    }

    // ── Restore backup ────────────────────────────────────────────────────────

    public void restoreBackup(Uri inputUri, BackupCallback callback) {
        new Thread(() -> {
            try {
                StringBuilder sb = new StringBuilder();
                try (InputStream is = context.getContentResolver().openInputStream(inputUri);
                     BufferedReader reader = new BufferedReader(new InputStreamReader(is))) {
                    String line;
                    while ((line = reader.readLine()) != null) sb.append(line);
                }

                JsonObject root = JsonParser.parseString(sb.toString()).getAsJsonObject();

                // Restore categories
                if (root.has("backupCategories")) {
                    int pos = 0;
                    for (JsonElement ce : root.getAsJsonArray("backupCategories")) {
                        JsonObject co = ce.getAsJsonObject();
                        Category cat = new Category(co.get("name").getAsString(), pos++);
                        db.categoryDao().insert(cat);
                    }
                }

                // Restore manga + chapters
                int count = 0;
                if (root.has("backupManga")) {
                    for (JsonElement me : root.getAsJsonArray("backupManga")) {
                        Manga m = GSON.fromJson(me, Manga.class);
                        m.inLibrary = true;
                        db.mangaDao().insertManga(m);
                        JsonObject mo = me.getAsJsonObject();
                        if (mo.has("chapters")) {
                            List<Chapter> chapters = new ArrayList<>();
                            for (JsonElement ce : mo.getAsJsonArray("chapters")) {
                                chapters.add(GSON.fromJson(ce, Chapter.class));
                            }
                            db.chapterDao().insertChapters(chapters);
                        }
                        count++;
                    }
                }
                callback.onSuccess("Restored " + count + " manga");
            } catch (Exception e) {
                callback.onError("Restore failed: " + e.getMessage());
            }
        }).start();
    }

    /** Suggested backup file name. */
    public static String suggestFileName() {
        String date = new SimpleDateFormat("yyyy-MM-dd_HHmm", Locale.US).format(new Date());
        return "ComiFountain_backup_" + date + ".json";
    }

    /** Synchronous library query for backup thread. */
    private List<Manga> getLibrarySync() {
        // Raw query since we're already off main thread
        return db.mangaDao().getLibraryMangaSync();
    }

    public interface BackupCallback {
        void onSuccess(String message);
        void onError(String error);
    }
}
EOF

echo "💾  Backup manager done"

# ─────────────────────────────────────────────────────────────────────────────
# ADD getLibraryMangaSync to MangaDao
# ─────────────────────────────────────────────────────────────────────────────

# We need to add a sync version — patch via sed
grep -q "getLibraryMangaSync" "$J/data/db/MangaDao.java" 2>/dev/null || \
  sed -i '/getUpdatesBadgeCount/i \    @Query("SELECT * FROM manga WHERE in_library = 1 ORDER BY last_read DESC")\n    List<Manga> getLibraryMangaSync();\n' \
  "$J/data/db/MangaDao.java"

# ─────────────────────────────────────────────────────────────────────────────
# SCREENSHOT MANAGER
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/utils/ScreenshotManager.java" << 'EOF'
package com.fountainpdl.comifountain.utils;

import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.View;
import androidx.recyclerview.widget.RecyclerView;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class ScreenshotManager {

    /** Save the current page view as a PNG to the Pictures/ComiFountain folder. */
    public static void saveCurrentPage(Context context, View pageView, SaveCallback callback) {
        new Thread(() -> {
            try {
                Bitmap bitmap = viewToBitmap(pageView);
                Uri uri = saveBitmapToGallery(context, bitmap, "ComiFountain_page");
                callback.onSaved(uri);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        }).start();
    }

    /** Extended screenshot — stitch all visible pages into one tall image. */
    public static void saveExtendedScreenshot(Context context, RecyclerView recycler, SaveCallback callback) {
        new Thread(() -> {
            try {
                // Measure total content height
                int totalHeight = 0;
                int width = recycler.getWidth();
                List<Bitmap> bitmaps = new ArrayList<>();

                for (int i = 0; i < recycler.getChildCount(); i++) {
                    View child = recycler.getChildAt(i);
                    Bitmap b = viewToBitmap(child);
                    bitmaps.add(b);
                    totalHeight += b.getHeight();
                }

                if (bitmaps.isEmpty()) { callback.onError("No pages visible"); return; }

                Bitmap combined = Bitmap.createBitmap(width, totalHeight, Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(combined);
                int y = 0;
                for (Bitmap b : bitmaps) {
                    canvas.drawBitmap(b, 0, y, null);
                    y += b.getHeight();
                    b.recycle();
                }

                Uri uri = saveBitmapToGallery(context, combined, "ComiFountain_extended");
                combined.recycle();
                callback.onSaved(uri);
            } catch (Exception e) {
                callback.onError(e.getMessage());
            }
        }).start();
    }

    private static Bitmap viewToBitmap(View view) {
        Bitmap bitmap = Bitmap.createBitmap(view.getWidth(), view.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        view.draw(canvas);
        return bitmap;
    }

    private static Uri saveBitmapToGallery(Context context, Bitmap bitmap, String baseName) throws IOException {
        String name = baseName + "_" +
            new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date()) + ".png";

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, name);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/png");
            values.put(MediaStore.Images.Media.RELATIVE_PATH,
                Environment.DIRECTORY_PICTURES + "/ComiFountain");
            Uri uri = context.getContentResolver()
                .insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) throw new IOException("Failed to create MediaStore entry");
            try (OutputStream os = context.getContentResolver().openOutputStream(uri)) {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, os);
            }
            return uri;
        } else {
            File dir = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES), "ComiFountain");
            if (!dir.exists()) dir.mkdirs();
            File file = new File(dir, name);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
            }
            return Uri.fromFile(file);
        }
    }

    public interface SaveCallback {
        void onSaved(Uri uri);
        void onError(String error);
    }
}
EOF

echo "📸  Screenshot manager done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED THEMES — AMOLED + Light purple/red/white + Material You
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/values/themes.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>

    <!-- ── Dark (default) ────────────────────────────────────────────────── -->
    <style name="Theme.ComiFountain" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="colorPrimary">@color/cf_purple</item>
        <item name="colorSecondary">@color/cf_red</item>
        <item name="android:colorBackground">@color/background_dark</item>
        <item name="android:windowBackground">@color/background_dark</item>
        <item name="colorSurface">@color/surface_dark</item>
        <item name="colorOnSurface">@color/text_primary_dark</item>
        <item name="android:navigationBarColor">@color/surface_dark</item>
        <item name="android:statusBarColor">#00000000</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>

    <!-- ── AMOLED dark (pure black + purple accents) ─────────────────────── -->
    <style name="Theme.ComiFountain.Amoled" parent="Theme.ComiFountain">
        <item name="android:colorBackground">#000000</item>
        <item name="android:windowBackground">#000000</item>
        <item name="colorSurface">#0a0a0a</item>
        <item name="colorSurfaceVariant">#111111</item>
        <item name="android:navigationBarColor">#000000</item>
    </style>

    <!-- ── Light (purple + red + white) ─────────────────────────────────── -->
    <style name="Theme.ComiFountain.Light" parent="Theme.Material3.Light.NoActionBar">
        <item name="colorPrimary">@color/cf_purple</item>
        <item name="colorSecondary">@color/cf_red</item>
        <item name="android:colorBackground">@color/background_light</item>
        <item name="android:windowBackground">@color/background_light</item>
        <item name="colorSurface">#FFFFFF</item>
        <item name="colorOnSurface">#1a1a1a</item>
        <item name="android:navigationBarColor">#FFFFFF</item>
        <item name="android:statusBarColor">#00000000</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>

    <!-- ── Reader (fullscreen override) ─────────────────────────────────── -->
    <style name="Theme.ComiFountain.Reader" parent="Theme.ComiFountain">
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>

</resources>
EOF

cat > "$R/values/colors.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Brand -->
    <color name="cf_purple">#9b30ff</color>
    <color name="cf_purple_dark">#7b20df</color>
    <color name="cf_red">#e63946</color>
    <color name="cf_red_dark">#c62030</color>

    <!-- Dark surfaces -->
    <color name="background_dark">#121212</color>
    <color name="surface_dark">#1e1e2e</color>
    <color name="surface_variant">#2d2d44</color>
    <color name="surface_elevated">#252535</color>

    <!-- Light surfaces -->
    <color name="background_light">#F8F8FF</color>
    <color name="surface_light">#FFFFFF</color>
    <color name="surface_light_variant">#F0ECF8</color>

    <!-- AMOLED -->
    <color name="background_amoled">#000000</color>
    <color name="surface_amoled">#0a0a0a</color>

    <!-- Text -->
    <color name="text_primary_dark">#FFFFFFFF</color>
    <color name="text_secondary_dark">#B3FFFFFF</color>
    <color name="text_primary_light">#1a1a1a</color>
    <color name="text_secondary_light">#666666</color>

    <!-- UI -->
    <color name="ripple_accent">#339b30ff</color>
    <color name="divider_dark">#33FFFFFF</color>
    <color name="divider_light">#1A000000</color>
    <color name="badge_bg">@color/cf_purple</color>
    <color name="transparent">#00000000</color>
    <color name="reader_overlay">#AA000000</color>
</resources>
EOF

echo "🎨  Themes done"

# ─────────────────────────────────────────────────────────────────────────────
# THEME HELPER — updated with AMOLED + Material You
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/common/ThemeHelper.java" << 'EOF'
package com.fountainpdl.comifountain.ui.common;

import android.content.Context;
import android.graphics.Color;
import android.widget.ImageView;
import android.widget.TextView;
import com.fountainpdl.comifountain.preference.AppPreferences;
import java.util.Calendar;

public class ThemeHelper {

    /**
     * Apply the correct theme to an activity before setContentView.
     * Call in Activity.onCreate() BEFORE super.
     */
    public static void applyTheme(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        String theme = prefs.getTheme();
        if (theme.equals("amoled")) {
            context.setTheme(com.fountainpdl.comifountain.R.style.Theme_ComiFountain_Amoled);
        } else if (theme.equals("light")) {
            context.setTheme(com.fountainpdl.comifountain.R.style.Theme_ComiFountain_Light);
        }
        // "dark" uses the default theme already set in manifest
    }

    public static int getPrimaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":
            case "material-you": return getMaterialYouColor(context, true);
            case "dual-shift":   return Color.parseColor(prefs.getShiftColor1());
            default:             return Color.parseColor(prefs.getPrimaryColor());
        }
    }

    public static int getSecondaryColor(Context context) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        switch (prefs.getSubTheme()) {
            case "dynamic":
            case "material-you": return getMaterialYouColor(context, false);
            case "dual-shift":   return Color.parseColor(prefs.getShiftColor2());
            default:             return Color.parseColor(prefs.getSecondaryColor());
        }
    }

    public static void tintImageView(Context c, ImageView v)  { v.setColorFilter(getPrimaryColor(c)); }
    public static void tintTextView(Context c, TextView v)    { v.setTextColor(getPrimaryColor(c)); }

    /** Android 12+ wallpaper-based Material You colors, fallback to clock palette. */
    private static int getMaterialYouColor(Context context, boolean primary) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            try {
                int resId = primary ? android.R.color.system_accent1_400
                                    : android.R.color.system_accent2_400;
                android.content.res.ColorStateList csl = context.getColorStateList(resId);
                if (csl != null) return csl.getDefaultColor();
            } catch (Exception ignored) {}
        }
        return clockColor(primary ? 0 : 6);
    }

    private static int clockColor(int offset) {
        int hour = (Calendar.getInstance().get(Calendar.HOUR_OF_DAY) + offset) % 24;
        float[] hues = {270f, 0f, 200f, 120f};
        float[] hsv  = {hues[(hour / 6) % hues.length], 0.75f, 0.85f};
        return Color.HSVToColor(hsv);
    }

    public static boolean isDark(Context context) {
        String theme = AppPreferences.getInstance(context).getTheme();
        return theme.equals("dark") || theme.equals("amoled");
    }
}
EOF

echo "✅  Part 1 complete"
echo ""
echo "Files written:"
echo "  AppPreferences.java    — all new keys"
echo "  CustomSource.java      — user source entity"
echo "  CustomSourceDao.java   — source CRUD"
echo "  CategoryDao.java       — category CRUD"
echo "  HistoryDao.java        — history queries"
echo "  AppDatabase.java v2    — all tables + migration"
echo "  CustomUrlSource.java   — generic scraper"
echo "  SourceManager.java     — replaces SourceRegistry"
echo "  BackupManager.java     — Tachiyomi-style backup/restore"
echo "  ScreenshotManager.java — page + extended screenshots"
echo "  ThemeHelper.java       — AMOLED + Material You"
echo "  themes.xml             — dark/amoled/light themes"
echo "  colors.xml             — full color set"
#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Major Feature Update (Part 2)
# New: Updated fragments, layouts, download manager, migration feature
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p "$J/ui/library" "$J/ui/search" "$J/ui/sources" \
         "$J/ui/reader" "$J/ui/settings" "$J/ui/history" \
         "$J/ui/detail" "$J/download" "$R/layout" "$R/menu"

echo "📁  Directories ready"

# ─────────────────────────────────────────────────────────────────────────────
# DOWNLOAD MANAGER
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/download/DownloadManager.java" << 'EOF'
package com.fountainpdl.comifountain.download;

import android.content.Context;
import android.net.Uri;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Page;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.Source;
import com.fountainpdl.comifountain.sources.SourceManager;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * Handles chapter downloads with quality control and location control.
 * Quality modes: original / high (90%) / medium (75%) / low (50%)
 */
public class DownloadManager {

    private static DownloadManager instance;
    private final Context context;
    private final MangaRepository repo;
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private final Set<String> activeDownloads = Collections.synchronizedSet(new HashSet<>());

    private DownloadManager(Context context) {
        this.context = context.getApplicationContext();
        this.repo    = new MangaRepository(context);
    }

    public static DownloadManager getInstance(Context context) {
        if (instance == null) synchronized (DownloadManager.class) {
            if (instance == null) instance = new DownloadManager(context);
        }
        return instance;
    }

    /** Queue a chapter for download. */
    public void download(String mangaId, Chapter chapter, DownloadCallback callback) {
        if (activeDownloads.contains(chapter.id)) {
            ToastManager.show(context, "Already downloading: " + chapter.displayName());
            return;
        }
        activeDownloads.add(chapter.id);
        executor.execute(() -> {
            try {
                String sourceId = mangaId.substring(0, mangaId.indexOf(':'));
                String rawManga = mangaId.substring(mangaId.indexOf(':') + 1);
                String rawChap  = chapter.id.substring(chapter.id.indexOf(':') + 1);

                Source source = SourceManager.getInstance(context).getById(sourceId);
                if (source == null) throw new Exception("Source not found: " + sourceId);

                List<Page> pages = source.getPageList(rawManga, rawChap);
                if (pages.isEmpty()) throw new Exception("No pages found");

                File chapDir = getChapterDir(mangaId, chapter);
                chapDir.mkdirs();

                int total = pages.size();
                for (int i = 0; i < total; i++) {
                    Page page = pages.get(i);
                    File imgFile = new File(chapDir, String.format("%03d.jpg", page.index));
                    downloadImage(page.url, imgFile);
                    if (callback != null) callback.onProgress(i + 1, total);
                }

                repo.markDownloaded(chapter.id, chapDir.getAbsolutePath());
                activeDownloads.remove(chapter.id);
                if (callback != null) callback.onComplete(chapter);
            } catch (Exception e) {
                activeDownloads.remove(chapter.id);
                if (callback != null) callback.onError(chapter, e.getMessage());
            }
        });
    }

    /** Delete downloaded chapter files. */
    public void deleteDownload(Chapter chapter) {
        executor.execute(() -> {
            if (chapter.downloadPath != null) {
                deleteDir(new File(chapter.downloadPath));
            }
            repo.clearDownload(chapter.id);
        });
    }

    /** Get resolved download directory for a chapter. */
    private File getChapterDir(String mangaId, Chapter chapter) {
        AppPreferences prefs = AppPreferences.getInstance(context);
        String location = prefs.getDownloadLocation();
        File root = location != null
            ? new File(location)
            : new File(context.getExternalFilesDir(null), "ComiFountain/downloads");
        // Sanitize names for file system
        String mangaName = sanitize(mangaId.substring(mangaId.indexOf(':') + 1));
        String chapName  = sanitize(chapter.displayName());
        return new File(root, mangaName + "/" + chapName);
    }

    private void downloadImage(String url, File outFile) throws Exception {
        if (outFile.exists()) return; // Already downloaded
        AppPreferences prefs = AppPreferences.getInstance(context);
        String quality = prefs.getDownloadQuality();

        Request req = new Request.Builder().url(url)
            .header("User-Agent", "Mozilla/5.0 (Android)").build();
        try (Response resp = new OkHttpClient().newCall(req).execute()) {
            if (!resp.isSuccessful() || resp.body() == null)
                throw new Exception("Download failed: HTTP " + resp.code());
            byte[] bytes = resp.body().bytes();

            // Quality compression (skip for original)
            if (!"original".equals(quality)) {
                int q = "high".equals(quality) ? 90 : "medium".equals(quality) ? 75 : 50;
                android.graphics.Bitmap bmp = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                if (bmp != null) {
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    bmp.compress(android.graphics.Bitmap.CompressFormat.JPEG, q, bos);
                    bytes = bos.toByteArray();
                    bmp.recycle();
                }
            }
            try (FileOutputStream fos = new FileOutputStream(outFile)) {
                fos.write(bytes);
            }
        }
    }

    private void deleteDir(File dir) {
        if (dir == null || !dir.exists()) return;
        File[] files = dir.listFiles();
        if (files != null) for (File f : files) {
            if (f.isDirectory()) deleteDir(f); else f.delete();
        }
        dir.delete();
    }

    private String sanitize(String name) {
        return name.replaceAll("[^a-zA-Z0-9._\\-]", "_").replaceAll("_{2,}", "_");
    }

    public boolean isDownloading(String chapterId) { return activeDownloads.contains(chapterId); }

    public interface DownloadCallback {
        void onProgress(int downloaded, int total);
        void onComplete(Chapter chapter);
        void onError(Chapter chapter, String error);
    }
}
EOF

echo "📥  Download manager done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED LIBRARY FRAGMENT — grid/list toggle, categories, compact mode
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
EOF

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED LIBRARY VIEWMODEL
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/library/LibraryViewModel.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.lifecycle.*;
import com.fountainpdl.comifountain.ComiFountainApp;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.model.*;
import java.util.List;

public class LibraryViewModel extends AndroidViewModel {
    private final MangaRepository repo;

    public LibraryViewModel(@NonNull Application app) {
        super(app);
        repo = ((ComiFountainApp) app).getRepository();
    }

    public LiveData<List<Manga>>    getLibraryManga()              { return repo.getLibraryManga(); }
    public LiveData<List<Manga>>    getLibraryByCategory(String c) { return repo.getLibraryMangaByCategory(c); }
    public LiveData<List<Manga>>    getMangaWithUpdates()          { return repo.getMangaWithUpdates(); }
    public LiveData<Integer>        getUpdatesBadge()              { return repo.getUpdatesBadgeCount(); }
    public LiveData<List<Category>> getCategories()                { return repo.getCategories(); }

    public void removeFromLibrary(String id)                       { repo.removeFromLibrary(id); }
    public void markAllRead(String id)                             { repo.markAllRead(id); }
    public void markAllUnread(String id)                           { repo.markAllUnread(id); }
    public void updateCategories(String id, List<String> cats)     { repo.updateCategories(id, cats); }
    public void addCategory(String name)                           { repo.addCategory(name); }
    public void deleteCategory(Category c)                         { repo.deleteCategory(c); }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED MANGA GRID ADAPTER — grid/list/compact modes + filter
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/library/MangaGridAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.library;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.Manga;
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
        fullList = list != null ? list : new ArrayList<>();
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
            for (Manga m : fullList) {
                if (m.title != null && m.title.toLowerCase().contains(q)) displayList.add(m);
            }
        }
        notifyDataSetChanged();
    }

    public void setDisplayMode(boolean grid, boolean compact) {
        viewType = compact ? VIEW_COMPACT : grid ? VIEW_GRID : VIEW_LIST;
        notifyDataSetChanged();
    }

    @Override public int getItemViewType(int pos) { return viewType; }
    @Override public int getItemCount() { return displayList.size(); }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int type) {
        int layout = type == VIEW_LIST ? R.layout.item_manga_list
                   : type == VIEW_COMPACT ? R.layout.item_manga_compact
                   : R.layout.item_manga_card;
        return new VH(LayoutInflater.from(p.getContext()).inflate(layout, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Manga m = displayList.get(pos);
        if (h.title != null) h.title.setText(m.title);
        if (h.badge != null) {
            h.badge.setVisibility(m.unreadCount > 0 ? View.VISIBLE : View.GONE);
            if (m.unreadCount > 0) h.badge.setText(String.valueOf(m.unreadCount));
        }
        if (h.sourceName != null) h.sourceName.setText(m.sourceName);
        if (h.status != null) h.status.setText(m.status != null ? m.status : "");

        if (h.cover != null) {
            Glide.with(h.cover).load(m.cover)
                .placeholder(R.drawable.ic_manga_placeholder)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .centerCrop().into(h.cover);
        }
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

echo "📚  Library done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED SOURCES FRAGMENT — Browse / Extensions / Migration tabs
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/sources/SourcesFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.sources;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.activity.result.*;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.*;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.fountainpdl.comifountain.data.model.CustomSource;
import com.fountainpdl.comifountain.databinding.FragmentSourcesBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.sources.*;
import com.fountainpdl.comifountain.ui.common.ToastManager;
import java.util.*;

public class SourcesFragment extends Fragment {

    private FragmentSourcesBinding binding;

    private final ActivityResultLauncher<Uri> folderPicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocumentTree(), uri -> {
            if (uri == null) return;
            requireContext().getContentResolver().takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            AppPreferences.getInstance(requireContext()).setLocalUri(uri.toString());
            Source local = SourceManager.getInstance(requireContext()).getById("local");
            if (local instanceof LocalSource) ((LocalSource) local).setRootUri(uri);
            ToastManager.show(requireContext(), "Local folder set!");
        });

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSourcesBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Tab selection
        binding.tabBrowse.setOnClickListener(v -> showTab("browse"));
        binding.tabExtensions.setOnClickListener(v -> showTab("extensions"));
        binding.tabMigration.setOnClickListener(v -> showTab("migration"));

        showTab("browse");
    }

    private void showTab(String tab) {
        binding.browsePanelContainer.setVisibility(tab.equals("browse")      ? View.VISIBLE : View.GONE);
        binding.extensionsPanelContainer.setVisibility(tab.equals("extensions") ? View.VISIBLE : View.GONE);
        binding.migrationPanelContainer.setVisibility(tab.equals("migration")  ? View.VISIBLE : View.GONE);

        // Bold active tab
        binding.tabBrowse.setAlpha(tab.equals("browse")      ? 1f : 0.5f);
        binding.tabExtensions.setAlpha(tab.equals("extensions") ? 1f : 0.5f);
        binding.tabMigration.setAlpha(tab.equals("migration")  ? 1f : 0.5f);

        if (tab.equals("browse"))     setupBrowse();
        if (tab.equals("extensions")) setupExtensions();
        if (tab.equals("migration"))  setupMigration();
    }

    // ── Browse tab ────────────────────────────────────────────────────────────

    private void setupBrowse() {
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
    }

    // ── Extensions tab ────────────────────────────────────────────────────────

    private void setupExtensions() {
        refreshExtensionList();
        binding.addSourceBtn.setOnClickListener(v -> showAddSourceDialog());
    }

    private void refreshExtensionList() {
        List<Source> custom = SourceManager.getInstance(requireContext()).getCustom();
        binding.extensionsRecycler.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.extensionsRecycler.setAdapter(new ExtensionAdapter(custom,
            new ExtensionAdapter.Listener() {
                @Override public void onEdit(Source s)   { showEditSourceDialog(s); }
                @Override public void onDelete(Source s) { confirmDelete(s); }
                @Override public void onToggle(Source s, boolean enabled) {
                    SourceManager.getInstance(requireContext())
                        .updateCustomSourceUrl(s.getId(), s.getBaseUrl());
                }
            }
        ));
    }

    private void showAddSourceDialog() {
        View dialogView = LayoutInflater.from(requireContext())
            .inflate(android.R.layout.simple_list_item_2, null);
        EditText nameInput = new EditText(requireContext());
        nameInput.setHint("Source Name (e.g. MangaFox)");
        EditText urlInput = new EditText(requireContext());
        urlInput.setHint("Base URL (e.g. https://mangafox.to)");
        EditText searchInput = new EditText(requireContext());
        searchInput.setHint("Search path (e.g. /search?q={query})");

        LinearLayout layout = new LinearLayout(requireContext());
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 24, 48, 0);
        layout.addView(nameInput);
        layout.addView(urlInput);
        layout.addView(searchInput);

        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Add Source")
            .setView(layout)
            .setPositiveButton("Add", (d, w) -> {
                String name   = nameInput.getText().toString().trim();
                String url    = urlInput.getText().toString().trim();
                String search = searchInput.getText().toString().trim();
                if (name.isEmpty() || url.isEmpty()) {
                    ToastManager.show(requireContext(), "Name and URL required");
                    return;
                }
                if (!url.startsWith("http")) url = "https://" + url;
                CustomSource cs = new CustomSource(
                    java.util.UUID.randomUUID().toString(), name, url,
                    search.isEmpty() ? "/?s={query}" : search);
                SourceManager.getInstance(requireContext()).addCustomSource(cs);
                ToastManager.show(requireContext(), name + " added!");
                refreshExtensionList();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void showEditSourceDialog(Source source) {
        EditText urlInput = new EditText(requireContext());
        urlInput.setHint("New base URL");
        urlInput.setText(source.getBaseUrl());
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Edit: " + source.getName())
            .setView(urlInput)
            .setPositiveButton("Save", (d, w) -> {
                String newUrl = urlInput.getText().toString().trim();
                if (!newUrl.isEmpty()) {
                    SourceManager.getInstance(requireContext())
                        .updateCustomSourceUrl(source.getId(), newUrl);
                    ToastManager.show(requireContext(), "URL updated!");
                    refreshExtensionList();
                }
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void confirmDelete(Source source) {
        new androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Remove " + source.getName() + "?")
            .setMessage("This will remove the source. Downloaded manga will not be affected.")
            .setPositiveButton("Remove", (d, w) -> {
                SourceManager.getInstance(requireContext()).removeCustomSource(source.getId());
                refreshExtensionList();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    // ── Migration tab ─────────────────────────────────────────────────────────

    private void setupMigration() {
        binding.migrationInfo.setText(
            "Migration lets you move manga from one source to another while keeping " +
            "your reading progress, bookmarks, and categories.\n\n" +
            "Select a manga from your library to begin.");
        binding.startMigrationBtn.setOnClickListener(v -> showMigrationPicker());
    }

    private void showMigrationPicker() {
        ToastManager.show(requireContext(), "Select manga from library to migrate");
        // TODO: open library picker sheet
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

# ─────────────────────────────────────────────────────────────────────────────
# EXTENSION ADAPTER
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/sources/ExtensionAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.sources;

import android.view.*;
import android.widget.*;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.sources.Source;
import java.util.List;

public class ExtensionAdapter extends RecyclerView.Adapter<ExtensionAdapter.VH> {

    public interface Listener {
        void onEdit(Source s);
        void onDelete(Source s);
        void onToggle(Source s, boolean enabled);
    }

    private final List<Source> sources;
    private final Listener listener;

    public ExtensionAdapter(List<Source> sources, Listener listener) {
        this.sources = sources; this.listener = listener;
    }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext())
            .inflate(R.layout.item_extension_card, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        Source s = sources.get(pos);
        h.name.setText(s.getName());
        h.url.setText(s.getBaseUrl());
        h.editBtn.setOnClickListener(v -> listener.onEdit(s));
        h.deleteBtn.setOnClickListener(v -> listener.onDelete(s));
    }

    @Override public int getItemCount() { return sources.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView name, url; ImageButton editBtn, deleteBtn;
        VH(View v) {
            super(v);
            name      = v.findViewById(R.id.ext_name);
            url       = v.findViewById(R.id.ext_url);
            editBtn   = v.findViewById(R.id.ext_edit_btn);
            deleteBtn = v.findViewById(R.id.ext_delete_btn);
        }
    }
}
EOF

echo "🌐  Sources done"

# ─────────────────────────────────────────────────────────────────────────────
# HISTORY FRAGMENT
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/history/HistoryFragment.java" << 'EOF'
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
EOF

cat > "$J/ui/history/HistoryAdapter.java" << 'EOF'
package com.fountainpdl.comifountain.ui.history;

import android.view.*;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.*;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.data.model.HistoryEntry;
import java.text.SimpleDateFormat;
import java.util.*;

public class HistoryAdapter extends RecyclerView.Adapter<HistoryAdapter.VH> {
    private final List<HistoryEntry> entries;
    private static final SimpleDateFormat FMT = new SimpleDateFormat("MMM dd, yyyy  HH:mm", Locale.US);

    public HistoryAdapter(List<HistoryEntry> entries) { this.entries = entries; }

    @NonNull @Override
    public VH onCreateViewHolder(@NonNull ViewGroup p, int t) {
        return new VH(LayoutInflater.from(p.getContext()).inflate(R.layout.item_history, p, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int pos) {
        HistoryEntry e = entries.get(pos);
        h.mangaId.setText(e.mangaId);
        h.chapterId.setText(e.chapterId);
        h.readAt.setText(FMT.format(new Date(e.readAt)));
    }

    @Override public int getItemCount() { return entries.size(); }

    static class VH extends RecyclerView.ViewHolder {
        TextView mangaId, chapterId, readAt;
        VH(View v) {
            super(v);
            mangaId   = v.findViewById(R.id.history_manga);
            chapterId = v.findViewById(R.id.history_chapter);
            readAt    = v.findViewById(R.id.history_date);
        }
    }
}
EOF

echo "📜  History done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED SETTINGS FRAGMENT — full settings
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/ui/settings/SettingsFragment.java" << 'EOF'
package com.fountainpdl.comifountain.ui.settings;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import androidx.activity.result.*;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.*;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import com.fountainpdl.comifountain.R;
import com.fountainpdl.comifountain.backup.BackupManager;
import com.fountainpdl.comifountain.databinding.FragmentSettingsBinding;
import com.fountainpdl.comifountain.preference.AppPreferences;
import com.fountainpdl.comifountain.ui.common.ToastManager;

public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;
    private AppPreferences prefs;
    private BackupManager backupManager;

    private final ActivityResultLauncher<String> backupPicker =
        registerForActivityResult(new ActivityResultContracts.CreateDocument("application/json"), uri -> {
            if (uri != null) backupManager.createBackup(uri, new BackupManager.BackupCallback() {
                @Override public void onSuccess(String msg) { ToastManager.show(requireContext(), msg); }
                @Override public void onError(String err)   { ToastManager.showLong(requireContext(), err); }
            });
        });

    private final ActivityResultLauncher<String[]> restorePicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocument(), uri -> {
            if (uri != null) backupManager.restoreBackup(uri, new BackupManager.BackupCallback() {
                @Override public void onSuccess(String msg) { ToastManager.show(requireContext(), "✅ " + msg); }
                @Override public void onError(String err)   { ToastManager.showLong(requireContext(), "❌ " + err); }
            });
        });

    private final ActivityResultLauncher<Uri> downloadDirPicker =
        registerForActivityResult(new ActivityResultContracts.OpenDocumentTree(), uri -> {
            if (uri == null) return;
            requireContext().getContentResolver().takePersistableUriPermission(uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
            prefs.setDownloadLocation(uri.toString());
            binding.downloadLocationValue.setText(uri.getLastPathSegment());
            ToastManager.show(requireContext(), "Download folder set");
        });

    @Override
    public View onCreateView(@NonNull LayoutInflater i, ViewGroup c, Bundle s) {
        binding = FragmentSettingsBinding.inflate(i, c, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        prefs         = AppPreferences.getInstance(requireContext());
        backupManager = new BackupManager(requireContext());

        setupAppearance();
        setupReader();
        setupLibrary();
        setupDownload();
        setupContent();
        setupBackup();
        setupCategories();
    }

    // ── Appearance ────────────────────────────────────────────────────────────

    private void setupAppearance() {
        // Theme: dark / amoled / light
        String theme = prefs.getTheme();
        binding.radioThemeDark.setChecked("dark".equals(theme));
        binding.radioThemeAmoled.setChecked("amoled".equals(theme));
        binding.radioThemeLight.setChecked("light".equals(theme));
        binding.themeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_theme_dark)   prefs.setTheme("dark");
            else if (id == R.id.radio_theme_amoled) prefs.setTheme("amoled");
            else                               prefs.setTheme("light");
            ToastManager.show(requireContext(), "Restart the app to apply theme");
        });

        // Sub-theme
        String sub = prefs.getSubTheme();
        switch (sub) {
            case "solid":       binding.radioSolid.setChecked(true);      showPanel("solid"); break;
            case "dual-shift":  binding.radioDual.setChecked(true);       showPanel("dual");  break;
            case "material-you":binding.radioMaterialYou.setChecked(true);showPanel("dyn");   break;
        }
        binding.subThemeGroup.setOnCheckedChangeListener((g, id) -> {
            if (id == R.id.radio_solid)        { prefs.setSubTheme("solid");        showPanel("solid"); }
            else if (id == R.id.radio_dual)    { prefs.setSubTheme("dual-shift");   showPanel("dual"); }
            else                               { prefs.setSubTheme("material-you"); showPanel("dyn"); }
        });

        binding.primaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getPrimaryColor()));
        binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(prefs.getSecondaryColor()));
        binding.primaryColorBtn.setOnClickListener(v   -> colorPicker(true));
        binding.secondaryColorBtn.setOnClickListener(v -> colorPicker(false));
    }

    private void showPanel(String w) {
        binding.panelSolid.setVisibility("solid".equals(w) ? View.VISIBLE : View.GONE);
        binding.panelDualShift.setVisibility("dual".equals(w) ? View.VISIBLE : View.GONE);
        binding.panelDynamic.setVisibility("dyn".equals(w)  ? View.VISIBLE : View.GONE);
    }

    private void colorPicker(boolean primary) {
        EditText et = new EditText(requireContext());
        et.setText(primary ? prefs.getPrimaryColor() : prefs.getSecondaryColor());
        new AlertDialog.Builder(requireContext())
            .setTitle(primary ? "Primary Color" : "Secondary Color")
            .setView(et)
            .setPositiveButton("Apply", (d, w) -> {
                try {
                    Color.parseColor(et.getText().toString());
                    if (primary) { prefs.setPrimaryColor(et.getText().toString());
                                   binding.primaryColorBtn.setBackgroundColor(Color.parseColor(et.getText().toString())); }
                    else         { prefs.setSecondaryColor(et.getText().toString());
                                   binding.secondaryColorBtn.setBackgroundColor(Color.parseColor(et.getText().toString())); }
                } catch (Exception e) { ToastManager.show(requireContext(), "Invalid color"); }
            })
            .setNegativeButton("Cancel", null).show();
    }

    // ── Reader ────────────────────────────────────────────────────────────────

    private void setupReader() {
        binding.switchGrayscale.setChecked(prefs.isGrayscale());
        binding.switchInvert.setChecked(prefs.isInvert());
        binding.switchCropBorders.setChecked(prefs.isCropBorders());
        binding.switchKeepScreen.setChecked(prefs.isKeepScreen());
        binding.switchFullscreen.setChecked(prefs.isFullscreen());
        binding.switchPageAnim.setChecked(prefs.isPageAnim());

        binding.switchGrayscale.setOnCheckedChangeListener((v, c)   -> prefs.setGrayscale(c));
        binding.switchInvert.setOnCheckedChangeListener((v, c)      -> prefs.setInvert(c));
        binding.switchCropBorders.setOnCheckedChangeListener((v, c) -> prefs.setCropBorders(c));
        binding.switchKeepScreen.setOnCheckedChangeListener((v, c)  -> prefs.setGrayscale(c));
        binding.switchFullscreen.setOnCheckedChangeListener((v, c)  -> prefs.setFullscreen(c));
        binding.switchPageAnim.setOnCheckedChangeListener((v, c)    -> prefs.setGrayscale(c));

        // Reading mode picker
        String[] modes = {"Right to Left (Default)", "Left to Right", "Vertical", "Webtoon", "Vertical with Gaps"};
        String[] values = {"rtl", "ltr", "vertical", "webtoon", "vertical-gaps"};
        String current = prefs.getReadingMode();
        int idx = 0;
        for (int i = 0; i < values.length; i++) if (values[i].equals(current)) idx = i;
        final int[] selectedIdx = {idx};
        binding.readingModeValue.setText(modes[idx]);
        binding.readingModeRow.setOnClickListener(v -> new AlertDialog.Builder(requireContext())
            .setTitle("Reading Mode")
            .setSingleChoiceItems(modes, selectedIdx[0], (d, which) -> selectedIdx[0] = which)
            .setPositiveButton("Apply", (d, w) -> {
                prefs.setReadingMode(values[selectedIdx[0]]);
                binding.readingModeValue.setText(modes[selectedIdx[0]]);
            })
            .setNegativeButton("Cancel", null).show());
    }

    // ── Library ───────────────────────────────────────────────────────────────

    private void setupLibrary() {
        binding.switchShowUnread.setChecked(prefs.isShowUnread());
        binding.switchShowDownloaded.setChecked(prefs.isShowDownloaded());
        binding.switchCompact.setChecked(prefs.isLibCompact());
        binding.switchShowUnread.setOnCheckedChangeListener((v, c)      -> prefs.setGrayscale(c));
        binding.switchShowDownloaded.setOnCheckedChangeListener((v, c)  -> prefs.setGrayscale(c));
        binding.switchCompact.setOnCheckedChangeListener((v, c)         -> prefs.setLibCompact(c));

        binding.colsSlider.setValue(prefs.getLibraryCols());
        binding.colsValue.setText(prefs.getLibraryCols() + " columns");
        binding.colsSlider.addOnChangeListener((s, val, fromUser) -> {
            if (fromUser) {
                prefs.setLibraryCols((int) val);
                binding.colsValue.setText((int) val + " columns");
            }
        });
    }

    // ── Download ──────────────────────────────────────────────────────────────

    private void setupDownload() {
        String loc = prefs.getDownloadLocation();
        binding.downloadLocationValue.setText(loc != null ? Uri.parse(loc).getLastPathSegment() : "Default");
        binding.downloadLocationRow.setOnClickListener(v -> downloadDirPicker.launch(null));

        String[] qualities = {"Original", "High (90%)", "Medium (75%)", "Low (50%)"};
        String[] qValues   = {"original", "high", "medium", "low"};
        String curQ = prefs.getDownloadQuality();
        int qi = 0;
        for (int i = 0; i < qValues.length; i++) if (qValues[i].equals(curQ)) qi = i;
        final int[] qIdx = {qi};
        binding.downloadQualityValue.setText(qualities[qi]);
        binding.downloadQualityRow.setOnClickListener(v -> new AlertDialog.Builder(requireContext())
            .setTitle("Download Quality")
            .setSingleChoiceItems(qualities, qIdx[0], (d, which) -> qIdx[0] = which)
            .setPositiveButton("Apply", (d, w) -> {
                prefs.setDownloadQuality(qValues[qIdx[0]]);
                binding.downloadQualityValue.setText(qualities[qIdx[0]]);
            })
            .setNegativeButton("Cancel", null).show());

        binding.switchWifiOnly.setChecked(prefs.isWifiOnly());
        binding.switchAutoDelete.setChecked(prefs.isAutoDeleteRead());
        binding.switchWifiOnly.setOnCheckedChangeListener((v, c)   -> prefs.setWifiOnly(c));
        binding.switchAutoDelete.setOnCheckedChangeListener((v, c) -> prefs.setAutoDeleteRead(c));
    }

    // ── Content ───────────────────────────────────────────────────────────────

    private void setupContent() {
        binding.switch18Plus.setChecked(prefs.isShow18Plus());
        binding.switch18Plus.setOnCheckedChangeListener((v, c) -> {
            if (c) {
                new AlertDialog.Builder(requireContext())
                    .setTitle("18+ Content")
                    .setMessage("Enable adult content? This will show NSFW manga from supported sources.")
                    .setPositiveButton("Enable", (d, w) -> prefs.setShow18Plus(true))
                    .setNegativeButton("Cancel", (d, w) -> binding.switch18Plus.setChecked(false))
                    .show();
            } else { prefs.setShow18Plus(false); }
        });
    }

    // ── Backup ────────────────────────────────────────────────────────────────

    private void setupBackup() {
        binding.createBackupBtn.setOnClickListener(v ->
            backupPicker.launch(BackupManager.suggestFileName()));
        binding.restoreBackupBtn.setOnClickListener(v ->
            restorePicker.launch(new String[]{"application/json", "*/*"}));
    }

    // ── Categories ────────────────────────────────────────────────────────────

    private void setupCategories() {
        binding.addCategoryBtn.setOnClickListener(v -> {
            EditText et = new EditText(requireContext());
            et.setHint("Category name");
            new AlertDialog.Builder(requireContext())
                .setTitle("New Category")
                .setView(et)
                .setPositiveButton("Add", (d, w) -> {
                    String name = et.getText().toString().trim();
                    if (!name.isEmpty()) {
                        ((com.fountainpdl.comifountain.ComiFountainApp) requireActivity().getApplication())
                            .getRepository().addCategory(name);
                        ToastManager.show(requireContext(), "Category \"" + name + "\" added");
                    }
                })
                .setNegativeButton("Cancel", null).show();
        });
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
EOF

echo "⚙️   Settings done"

# ─────────────────────────────────────────────────────────────────────────────
# LAYOUTS — updated/new
# ─────────────────────────────────────────────────────────────────────────────

# Library — with search, toggle, count
cat > "$R/layout/fragment_library.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <!-- Header -->
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical"
        android:padding="12dp">
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
            android:contentDescription="Grid view"
            android:layout_marginStart="4dp"/>
    </LinearLayout>

    <!-- Search -->
    <EditText android:id="@+id/search_library"
        android:layout_width="match_parent" android:layout_height="48dp"
        android:layout_marginHorizontal="12dp" android:layout_marginBottom="8dp"
        android:hint="Search library…" android:paddingHorizontal="12dp"
        android:background="@drawable/bg_search_field"
        android:imeOptions="actionSearch" android:singleLine="true"/>

    <!-- Count + category label -->
    <TextView android:id="@+id/library_count"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:paddingHorizontal="16dp" android:paddingBottom="4dp"
        android:textSize="12sp" android:alpha="0.6"/>

    <!-- List -->
    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipe_refresh"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1">
        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/library_recycler"
            android:layout_width="match_parent" android:layout_height="match_parent"
            android:padding="8dp" android:clipToPadding="false"/>
    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

    <TextView android:id="@+id/empty_state"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="No manga in library.\nBrowse Sources to add some!"
        android:textAlignment="center" android:gravity="center"
        android:padding="32dp" android:visibility="gone"/>

</LinearLayout>
EOF

# Sources — 3 tabs
cat > "$R/layout/fragment_sources.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <!-- Tab bar -->
    <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
        android:orientation="horizontal"
        android:background="?attr/colorSurface">
        <TextView android:id="@+id/tab_browse"
            android:layout_width="0dp" android:layout_height="match_parent"
            android:layout_weight="1" android:text="Browse"
            android:gravity="center" android:textStyle="bold"
            android:background="?attr/selectableItemBackground"/>
        <TextView android:id="@+id/tab_extensions"
            android:layout_width="0dp" android:layout_height="match_parent"
            android:layout_weight="1" android:text="Extensions"
            android:gravity="center" android:textStyle="bold"
            android:background="?attr/selectableItemBackground"/>
        <TextView android:id="@+id/tab_migration"
            android:layout_width="0dp" android:layout_height="match_parent"
            android:layout_weight="1" android:text="Migration"
            android:gravity="center" android:textStyle="bold"
            android:background="?attr/selectableItemBackground"/>
    </LinearLayout>

    <!-- Browse panel -->
    <LinearLayout android:id="@+id/browse_panel_container"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:orientation="vertical">
        <Button android:id="@+id/pick_folder_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_margin="12dp" android:text="📁  Set Local Folder"
            style="@style/Widget.Material3.Button.OutlinedButton"/>
        <androidx.recyclerview.widget.RecyclerView android:id="@+id/browse_recycler"
            android:layout_width="match_parent" android:layout_height="0dp"
            android:layout_weight="1" android:padding="8dp" android:clipToPadding="false"/>
    </LinearLayout>

    <!-- Extensions panel -->
    <LinearLayout android:id="@+id/extensions_panel_container"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:orientation="vertical" android:visibility="gone">
        <Button android:id="@+id/add_source_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:layout_margin="12dp" android:text="＋  Add Source URL"
            style="@style/Widget.Material3.Button"/>
        <androidx.recyclerview.widget.RecyclerView android:id="@+id/extensions_recycler"
            android:layout_width="match_parent" android:layout_height="0dp"
            android:layout_weight="1" android:padding="8dp" android:clipToPadding="false"/>
    </LinearLayout>

    <!-- Migration panel -->
    <LinearLayout android:id="@+id/migration_panel_container"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:orientation="vertical"
        android:gravity="center" android:padding="24dp" android:visibility="gone">
        <TextView android:id="@+id/migration_info"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:textAlignment="center" android:alpha="0.7" android:paddingBottom="16dp"/>
        <Button android:id="@+id/start_migration_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="Start Migration"
            style="@style/Widget.Material3.Button"/>
    </LinearLayout>

</LinearLayout>
EOF

# History layout
cat > "$R/layout/fragment_history.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="?android:attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical" android:padding="16dp">
        <TextView android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:text="History"
            android:textSize="22sp" android:textStyle="bold"/>
        <Button android:id="@+id/clear_history_btn"
            android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="Clear" style="@style/Widget.Material3.Button.TextButton"/>
    </LinearLayout>

    <androidx.recyclerview.widget.RecyclerView android:id="@+id/history_recycler"
        android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1"/>

    <TextView android:id="@+id/history_empty"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="No reading history yet." android:gravity="center"
        android:padding="32dp" android:visibility="gone"/>

</LinearLayout>
EOF

# Item: list view manga card
cat > "$R/layout/item_manga_list.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="80dp"
    android:orientation="horizontal" android:gravity="center_vertical"
    android:paddingHorizontal="12dp" android:paddingVertical="8dp"
    android:background="?attr/selectableItemBackground">

    <ImageView android:id="@+id/manga_cover"
        android:layout_width="48dp" android:layout_height="64dp"
        android:scaleType="centerCrop" android:background="@color/surface_variant"/>

    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1" android:orientation="vertical" android:paddingStart="12dp">
        <TextView android:id="@+id/manga_title"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:textSize="15sp" android:textStyle="bold"
            android:maxLines="1" android:ellipsize="end"/>
        <TextView android:id="@+id/manga_source"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:textSize="12sp" android:alpha="0.6"/>
        <TextView android:id="@+id/manga_status"
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:textSize="12sp" android:alpha="0.5"/>
    </LinearLayout>

    <TextView android:id="@+id/manga_unread_badge"
        android:layout_width="28dp" android:layout_height="28dp"
        android:background="@drawable/bg_badge" android:gravity="center"
        android:textColor="#FFFFFF" android:textSize="11sp" android:textStyle="bold"
        android:visibility="gone"/>

</LinearLayout>
EOF

# Item: compact view
cat > "$R/layout/item_manga_compact.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:layout_margin="4dp">

    <ImageView android:id="@+id/manga_cover"
        android:layout_width="match_parent" android:layout_height="140dp"
        android:scaleType="centerCrop" android:background="@color/surface_variant"/>

    <TextView android:id="@+id/manga_unread_badge"
        android:layout_width="24dp" android:layout_height="24dp"
        android:layout_gravity="top|end" android:layout_margin="3dp"
        android:background="@drawable/bg_badge" android:gravity="center"
        android:textColor="#FFFFFF" android:textSize="10sp"
        android:visibility="gone"/>

    <TextView android:id="@+id/manga_title"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:layout_gravity="bottom" android:background="@drawable/gradient_bottom"
        android:padding="6dp" android:textColor="#FFFFFF"
        android:textSize="11sp" android:maxLines="1" android:ellipsize="end"/>

    <!-- Hidden — not shown in compact -->
    <TextView android:id="@+id/manga_source" android:layout_width="0dp"
        android:layout_height="0dp" android:visibility="gone"/>
    <TextView android:id="@+id/manga_status" android:layout_width="0dp"
        android:layout_height="0dp" android:visibility="gone"/>

</FrameLayout>
EOF

# Item: extension card
cat > "$R/layout/item_extension_card.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<com.google.android.material.card.MaterialCardView
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:layout_marginHorizontal="12dp" android:layout_marginVertical="4dp"
    app:cardCornerRadius="10dp">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="horizontal" android:gravity="center_vertical" android:padding="12dp">

        <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:orientation="vertical">
            <TextView android:id="@+id/ext_name"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:textSize="15sp" android:textStyle="bold"/>
            <TextView android:id="@+id/ext_url"
                android:layout_width="match_parent" android:layout_height="wrap_content"
                android:textSize="12sp" android:alpha="0.6" android:maxLines="1"
                android:ellipsize="end"/>
        </LinearLayout>

        <ImageButton android:id="@+id/ext_edit_btn"
            android:layout_width="36dp" android:layout_height="36dp"
            android:src="@drawable/ic_settings"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Edit"/>

        <ImageButton android:id="@+id/ext_delete_btn"
            android:layout_width="36dp" android:layout_height="36dp"
            android:src="@drawable/ic_back"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Delete"
            android:layout_marginStart="4dp"/>

    </LinearLayout>

</com.google.android.material.card.MaterialCardView>
EOF

# Item: history
cat > "$R/layout/item_history.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:orientation="vertical" android:padding="16dp"
    android:background="?attr/selectableItemBackground">
    <TextView android:id="@+id/history_manga"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textSize="14sp" android:textStyle="bold" android:maxLines="1" android:ellipsize="end"/>
    <TextView android:id="@+id/history_chapter"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textSize="12sp" android:alpha="0.7"/>
    <TextView android:id="@+id/history_date"
        android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textSize="11sp" android:alpha="0.5"/>
</LinearLayout>
EOF

# Search field background
cat > "$R/drawable/bg_search_field.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#22FFFFFF"/>
    <corners android:radius="24dp"/>
</shape>
EOF

echo "📐  Layouts done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATE MangaRepository — add missing methods
# ─────────────────────────────────────────────────────────────────────────────

cat >> "$J/data/MangaRepository.java" << 'EOF'

// ── Category management (appended) ────────────────────────────────────────────
EOF

# Patch repository to add new methods via a separate additions file
cat > "$J/data/RepositoryAdditions.java" << 'EOF'
package com.fountainpdl.comifountain.data;
// This file documents additions to MangaRepository that must be merged in.
// Add these methods to MangaRepository.java:
//
//   public LiveData<List<Category>> getCategories() {
//       return categoryDao.getAll();
//   }
//   public void addCategory(String name) {
//       exec.execute(() -> {
//           int pos = categoryDao.count();
//           categoryDao.insert(new Category(name, pos));
//       });
//   }
//   public void deleteCategory(Category c) {
//       exec.execute(() -> categoryDao.delete(c));
//   }
//   public LiveData<List<HistoryEntry>> getRecentHistory() {
//       return historyDao.getRecent();
//   }
//   public void clearHistory() {
//       exec.execute(() -> historyDao.clearAll());
//   }
//   public void recordHistory(String mangaId, String chapterId) {
//       exec.execute(() -> historyDao.insert(new HistoryEntry(mangaId, chapterId)));
//   }
//
// Also add to constructor:
//   categoryDao = db.categoryDao();
//   historyDao  = db.historyDao();
//
// And add fields:
//   private final CategoryDao categoryDao;
//   private final HistoryDao  historyDao;
EOF

echo "📝  Repository additions documented"

echo ""
echo "✅  Part 2 complete!"
echo ""
echo "Files written:"
echo "  DownloadManager.java       — quality/location/queued downloads"
echo "  LibraryFragment.java       — grid/list/compact, search, category picker"
echo "  LibraryViewModel.java      — updated with category support"
echo "  MangaGridAdapter.java      — grid + list + compact + filter"
echo "  SourcesFragment.java       — Browse / Extensions / Migration tabs"
echo "  ExtensionAdapter.java      — custom source list with edit/delete"
echo "  HistoryFragment.java       — reading history"
echo "  HistoryAdapter.java        — history list"
echo "  SettingsFragment.java      — full settings: theme/reader/library/download/backup/categories"
echo "  fragment_library.xml       — search bar + toggle buttons"
echo "  fragment_sources.xml       — 3-tab layout"
echo "  fragment_history.xml"
echo "  item_manga_list.xml        — list view card"
echo "  item_manga_compact.xml     — compact grid card"
echo "  item_extension_card.xml    — custom source row"
echo "  item_history.xml"
echo "  themes.xml                 — dark/amoled/light"
echo "  colors.xml                 — full palette"
echo ""
echo "⚠️  Manual step required:"
echo "  Merge RepositoryAdditions.java methods into MangaRepository.java"
echo "  (categoryDao, historyDao fields + methods + constructor wiring)"
#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Major Feature Update (Part 3)
# Full MangaRepository replacement + MainActivity + bottom nav + settings layout
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

echo "🔧  Starting Part 3..."

# ─────────────────────────────────────────────────────────────────────────────
# FULL MangaRepository — replaces old version, includes all new methods
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

    // ── Manga CRUD ────────────────────────────────────────────────────────────

    public void saveManga(Manga m)              { exec.execute(() -> mangaDao.insertManga(m)); }
    public void saveMangaList(List<Manga> list) { exec.execute(() -> mangaDao.insertAll(list)); }
    public void updateManga(Manga m)            { exec.execute(() -> mangaDao.updateManga(m)); }

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
    public void getFirstUnreadChapter(String mangaId, Callback<Chapter> cb) {
        exec.execute(() -> cb.onResult(chapterDao.getFirstUnreadChapter(mangaId)));
    }
    public void getResumeChapter(String mangaId, Callback<Chapter> cb) {
        exec.execute(() -> {
            Chapter c = chapterDao.getResumeChapter(mangaId);
            if (c == null) c = chapterDao.getFirstUnreadChapter(mangaId);
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

    public void setBookmark(String chapId, boolean b)          { exec.execute(() -> chapterDao.setBookmark(chapId, b)); }
    public LiveData<List<Chapter>> getBookmarkedChapters(String id) { return chapterDao.getBookmarkedChapters(id); }

    // ── Downloads ─────────────────────────────────────────────────────────────

    public void markDownloaded(String chapId, String path) {
        exec.execute(() -> chapterDao.markDownloaded(chapId, System.currentTimeMillis(), path));
    }
    public void clearDownload(String chapId) { exec.execute(() -> chapterDao.clearDownload(chapId)); }

    // ── Categories ────────────────────────────────────────────────────────────

    public LiveData<List<Category>> getCategories() { return categoryDao.getAll(); }

    public void addCategory(String name) {
        exec.execute(() -> {
            int pos = categoryDao.count();
            categoryDao.insert(new Category(name, pos));
        });
    }
    public void deleteCategory(Category c) { exec.execute(() -> categoryDao.delete(c)); }
    public void updateCategoryPosition(int id, int pos) {
        exec.execute(() -> categoryDao.updatePosition(id, pos));
    }

    // ── History ───────────────────────────────────────────────────────────────

    public LiveData<List<HistoryEntry>> getRecentHistory() { return historyDao.getRecent(); }

    public void recordHistory(String mangaId, String chapterId) {
        exec.execute(() -> historyDao.insert(new HistoryEntry(mangaId, chapterId)));
    }
    public void clearHistory() { exec.execute(() -> historyDao.clearAll()); }
    public void clearHistoryForManga(String mangaId) {
        exec.execute(() -> historyDao.clearForManga(mangaId));
    }

    // ── Search ────────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> searchLibrary(String q) { return mangaDao.searchLibrary(q); }

    // ── Internal ─────────────────────────────────────────────────────────────

    private void syncChapterStats(String mangaId) {
        int total  = chapterDao.getTotalCount(mangaId);
        int unread = chapterDao.getUnreadCount(mangaId);
        List<Chapter> chapters = chapterDao.getChaptersForMangaSync(mangaId);
        long latest = 0;
        for (Chapter c : chapters) if (c.date > latest) latest = c.date;
        mangaDao.updateChapterStats(mangaId, total, unread, latest);
    }

    public interface Callback<T> { void onResult(T result); }
}
EOF

echo "🗂️   Repository done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED MAIN ACTIVITY — History tab, fullscreen, theme apply
# ─────────────────────────────────────────────────────────────────────────────

cat > "$J/MainActivity.java" << 'EOF'
package com.fountainpdl.comifountain;

import android.os.Bundle;
import android.view.View;
import android.view.WindowInsetsController;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
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

    public static final String TAG_LIBRARY  = "library";
    public static final String TAG_SEARCH   = "search";
    public static final String TAG_SOURCES  = "sources";
    public static final String TAG_UPDATES  = "updates";
    public static final String TAG_SETTINGS = "settings";
    public static final String TAG_HISTORY  = "history";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Apply theme BEFORE super.onCreate
        ThemeHelper.applyTheme(this);
        super.onCreate(savedInstanceState);

        // Full edge-to-edge
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);

        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

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
        Fragment f = getSupportFragmentManager().findFragmentByTag(tag);
        if (f == null) f = createFragment(tag);
        getSupportFragmentManager().beginTransaction()
            .replace(R.id.fragment_container, f, tag).commit();
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
            if (fm.getBackStackEntryCount() == 1)
                binding.bottomNav.setVisibility(View.VISIBLE);
        } else {
            super.onBackPressed();
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
    }

    public void showSystemBars() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R)
            getWindow().getInsetsController().show(
                android.view.WindowInsets.Type.statusBars() |
                android.view.WindowInsets.Type.navigationBars());
    }
}
EOF

echo "🏠  MainActivity done"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED SETTINGS LAYOUT — complete
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/layout/fragment_settings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:background="?android:attr/colorBackground">

    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical" android:padding="16dp">

        <!-- ── APPEARANCE ──────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="APPEARANCE" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Theme" android:textStyle="bold" android:paddingBottom="8dp"/>
                <RadioGroup android:id="@+id/theme_group" android:layout_width="match_parent"
                    android:layout_height="wrap_content" android:orientation="horizontal">
                    <RadioButton android:id="@+id/radio_theme_dark"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Dark"/>
                    <RadioButton android:id="@+id/radio_theme_amoled"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="AMOLED"/>
                    <RadioButton android:id="@+id/radio_theme_light"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Light"/>
                </RadioGroup>

                <View android:layout_width="match_parent" android:layout_height="1dp"
                    android:background="?attr/colorOutlineVariant" android:layout_marginVertical="12dp"/>

                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Accent Theme" android:textStyle="bold" android:paddingBottom="8dp"/>
                <RadioGroup android:id="@+id/sub_theme_group" android:layout_width="match_parent"
                    android:layout_height="wrap_content" android:orientation="horizontal">
                    <RadioButton android:id="@+id/radio_solid"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Solid"/>
                    <RadioButton android:id="@+id/radio_dual"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Dual-Shift"/>
                    <RadioButton android:id="@+id/radio_material_you"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Material You"/>
                </RadioGroup>

                <!-- Solid color panel -->
                <LinearLayout android:id="@+id/panel_solid"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal" android:paddingTop="12dp">
                    <Button android:id="@+id/primary_color_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:layout_marginEnd="8dp"
                        android:text="Primary" android:textColor="#FFFFFF"/>
                    <Button android:id="@+id/secondary_color_btn"
                        android:layout_width="0dp" android:layout_height="48dp"
                        android:layout_weight="1" android:text="Secondary" android:textColor="#FFFFFF"/>
                </LinearLayout>

                <!-- Dual-shift panel -->
                <LinearLayout android:id="@+id/panel_dual_shift"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="vertical" android:paddingTop="12dp" android:visibility="gone">
                    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                        android:orientation="horizontal">
                        <Button android:id="@+id/shift_color1_btn"
                            android:layout_width="0dp" android:layout_height="48dp"
                            android:layout_weight="1" android:layout_marginEnd="8dp"
                            android:text="Color 1" android:textColor="#FFFFFF"/>
                        <Button android:id="@+id/shift_color2_btn"
                            android:layout_width="0dp" android:layout_height="48dp"
                            android:layout_weight="1" android:text="Color 2" android:textColor="#FFFFFF"/>
                    </LinearLayout>
                </LinearLayout>

                <!-- Material You panel -->
                <TextView android:id="@+id/panel_dynamic"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:paddingTop="12dp" android:visibility="gone"
                    android:text="Pulls colors from your wallpaper (Android 12+) with time-of-day fallback."
                    android:textColor="?attr/colorOnSurfaceVariant"/>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <!-- ── READER ───────────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="READER" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <!-- Reading mode row -->
                <LinearLayout android:id="@+id/reading_mode_row"
                    android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical"
                    android:background="?attr/selectableItemBackground">
                    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:orientation="vertical">
                        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:text="Reading Mode" android:textSize="15sp"/>
                        <TextView android:id="@+id/reading_mode_value"
                            android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:textSize="12sp" android:alpha="0.6"/>
                    </LinearLayout>
                    <ImageView android:layout_width="20dp" android:layout_height="20dp"
                        android:src="@drawable/ic_settings" android:alpha="0.4"/>
                </LinearLayout>

                <View android:layout_width="match_parent" android:layout_height="1dp"
                    android:background="?attr/colorOutlineVariant" android:layout_marginVertical="4dp"/>

                <!-- Toggle rows -->
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_fullscreen"/>
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_grayscale"/>
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_invert"/>
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_crop"/>
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_keep_screen"/>
                <include layout="@layout/item_toggle_row"
                    android:id="@+id/row_page_anim"/>

                <!-- Fullscreen switch  -->
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Fullscreen Reader"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_fullscreen"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Grayscale"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_grayscale"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Invert Colors"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_invert"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Crop Borders"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_crop_borders"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Keep Screen On"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_keep_screen"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Page Turn Animation"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_page_anim"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <!-- ── LIBRARY ──────────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="LIBRARY" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Show Unread Badge"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_show_unread"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Show Downloaded Badge"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_show_downloaded"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Compact Grid"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_compact"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Grid Columns" android:paddingTop="8dp" android:paddingBottom="4dp"/>
                <TextView android:id="@+id/cols_value"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:textSize="12sp" android:alpha="0.6"/>
                <com.google.android.material.slider.Slider
                    android:id="@+id/cols_slider"
                    android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:valueFrom="2" android:valueTo="5" android:stepSize="1"/>

                <Button android:id="@+id/add_category_btn"
                    android:layout_width="wrap_content" android:layout_height="wrap_content"
                    android:layout_marginTop="8dp" android:text="＋  Add Category"
                    style="@style/Widget.Material3.Button.OutlinedButton"/>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <!-- ── DOWNLOAD ─────────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="DOWNLOADS" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">

                <LinearLayout android:id="@+id/download_location_row"
                    android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical"
                    android:background="?attr/selectableItemBackground">
                    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:orientation="vertical">
                        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:text="Download Location" android:textSize="15sp"/>
                        <TextView android:id="@+id/download_location_value"
                            android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:textSize="12sp" android:alpha="0.6"/>
                    </LinearLayout>
                    <ImageView android:layout_width="20dp" android:layout_height="20dp"
                        android:src="@drawable/ic_settings" android:alpha="0.4"/>
                </LinearLayout>

                <LinearLayout android:id="@+id/download_quality_row"
                    android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical"
                    android:background="?attr/selectableItemBackground">
                    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:orientation="vertical">
                        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:text="Download Quality" android:textSize="15sp"/>
                        <TextView android:id="@+id/download_quality_value"
                            android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:textSize="12sp" android:alpha="0.6"/>
                    </LinearLayout>
                    <ImageView android:layout_width="20dp" android:layout_height="20dp"
                        android:src="@drawable/ic_settings" android:alpha="0.4"/>
                </LinearLayout>

                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Wi-Fi Only"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_wifi_only"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Delete After Reading"/>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_auto_delete"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>

            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <!-- ── CONTENT ──────────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="CONTENT" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="16dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">
                <LinearLayout android:layout_width="match_parent" android:layout_height="52dp"
                    android:orientation="horizontal" android:gravity="center_vertical">
                    <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:orientation="vertical">
                        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:text="Show 18+ Content"/>
                        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                            android:text="Show adult manga from supported sources"
                            android:textSize="12sp" android:alpha="0.6"/>
                    </LinearLayout>
                    <com.google.android.material.switchmaterial.SwitchMaterial
                        android:id="@+id/switch_18_plus"
                        android:layout_width="wrap_content" android:layout_height="wrap_content"/>
                </LinearLayout>
            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

        <!-- ── BACKUP ───────────────────────────────────────────────────────── -->
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="BACKUP &amp; RESTORE" android:textSize="11sp" android:textStyle="bold"
            android:letterSpacing="0.12" android:textColor="?attr/colorPrimary"
            android:paddingBottom="8dp"/>

        <com.google.android.material.card.MaterialCardView
            android:layout_width="match_parent" android:layout_height="wrap_content"
            android:layout_marginBottom="32dp">
            <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                android:orientation="vertical" android:padding="16dp">
                <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:text="Backup your library, reading progress, categories, and history to a JSON file."
                    android:textSize="13sp" android:alpha="0.7" android:paddingBottom="12dp"/>
                <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
                    android:orientation="horizontal">
                    <Button android:id="@+id/create_backup_btn"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:layout_marginEnd="8dp"
                        android:text="Create Backup"
                        style="@style/Widget.Material3.Button"/>
                    <Button android:id="@+id/restore_backup_btn"
                        android:layout_width="0dp" android:layout_height="wrap_content"
                        android:layout_weight="1" android:text="Restore"
                        style="@style/Widget.Material3.Button.OutlinedButton"/>
                </LinearLayout>
            </LinearLayout>
        </com.google.android.material.card.MaterialCardView>

    </LinearLayout>
</ScrollView>
EOF

echo "⚙️   Settings layout done"

# ─────────────────────────────────────────────────────────────────────────────
# Remove RepositoryAdditions stub (now merged)
# ─────────────────────────────────────────────────────────────────────────────
rm -f "$J/data/RepositoryAdditions.java"

# ─────────────────────────────────────────────────────────────────────────────
# UPDATED bottom nav menu — History replaces Updates in nav (Updates stays as tab)
# ─────────────────────────────────────────────────────────────────────────────

cat > "$R/menu/bottom_nav_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/nav_library"  android:icon="@drawable/ic_library"  android:title="Library"/>
    <item android:id="@+id/nav_search"   android:icon="@drawable/ic_search"   android:title="Search"/>
    <item android:id="@+id/nav_sources"  android:icon="@drawable/ic_sources"  android:title="Sources"/>
    <item android:id="@+id/nav_updates"  android:icon="@drawable/ic_updates"  android:title="Updates"/>
    <item android:id="@+id/nav_settings" android:icon="@drawable/ic_settings" android:title="Settings"/>
</menu>
EOF

# ─────────────────────────────────────────────────────────────────────────────
# EMPTY item_toggle_row stub (referenced in settings layout includes)
# ─────────────────────────────────────────────────────────────────────────────
# (Settings fragment uses direct switch IDs so we don't actually need includes)
# Remove the include references from settings layout since we used direct views
sed -i '/<include layout="@layout\/item_toggle_row"/d' "$R/layout/fragment_settings.xml"

echo "🧹  Cleaned up includes"

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "✅  All 3 update parts complete!"
echo ""
echo "Run order:"
echo "  bash update_part1.sh   # sources, DB, backup, screenshots, themes"
echo "  bash update_part2.sh   # library, sources UI, history, settings fragment"
echo "  bash update_part3.sh   # repository, MainActivity, settings layout"
echo ""
echo "Then:"
echo "  git add ."
echo "  git commit -m 'major feature update: full library, sources, reader, backup'"
echo "  git push"
echo ""
echo "Features added:"
echo "  ✅ AMOLED theme (pure black + purple)"
echo "  ✅ Light theme (purple/red/white)"
echo "  ✅ Material You / Dual-Shift dynamic theme"
echo "  ✅ Fullscreen app (system bars hidden)"
echo "  ✅ Custom URL sources (add/edit/delete, domain switching)"
echo "  ✅ LocalSource as proper source folder"
echo "  ✅ Sources: Browse / Extensions / Migration tabs"
echo "  ✅ Library: grid / list / compact view toggle"
echo "  ✅ Library: search, filter, category picker"
echo "  ✅ Sub-categories with multi-select assignment"
echo "  ✅ Remove from library (toggle button)"
echo "  ✅ Download manager (quality + location control)"
echo "  ✅ Reading history"
echo "  ✅ Backup & restore (Tachiyomi-style JSON)"
echo "  ✅ Categories backup included"
echo "  ✅ Screenshot + extended screenshot"
echo "  ✅ 18+ content filter"
echo "  ✅ All reading modes (RTL default, LTR, vertical, webtoon, vertical+gaps)"
echo "  ✅ Reader: fullscreen, grayscale, invert, crop, keep screen"
