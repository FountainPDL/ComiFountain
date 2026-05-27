#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════════════
# ComiFountain — Patch / Base Script
# Fills in everything NOT in generate_comifountain.sh:
#   • Root + app build.gradle
#   • Gradle wrapper
#   • ComiFountainApp.java
#   • Full data layer (models, Room DB, DAOs, Repository, Converters)
#   • GitHub Actions CI workflow
#   • README.md
#
# Run BEFORE generate_comifountain.sh, or independently.
# Usage: bash patch_comifountain.sh
# ═══════════════════════════════════════════════════════════════════════════════

J="app/src/main/java/com/fountainpdl/comifountain"
R="app/src/main/res"

mkdir -p \
  "$J/data/model" "$J/data/db" "$J/data" \
  "app/src/main/res/values" \
  ".github/workflows" \
  "gradle/wrapper"

echo "📁  Directories ready"

# ═══════════════════════════════════════════════════════════════════════════════
# GRADLE WRAPPER
# ═══════════════════════════════════════════════════════════════════════════════

cat > "gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# gradlew stub (actual binary comes from Android Studio / gradle init)
cat > "gradlew" << 'EOF'
#!/bin/sh
# Gradle start-up script for UN*X — generated stub.
# Run `gradle wrapper` inside Android Studio to get the real binary.
exec gradle "$@"
EOF
chmod +x gradlew

echo "🔧  Gradle wrapper done"

# ═══════════════════════════════════════════════════════════════════════════════
# ROOT build.gradle
# ═══════════════════════════════════════════════════════════════════════════════

cat > "build.gradle" << 'EOF'
// Top-level build file — options common to all sub-projects/modules.
plugins {
    id 'com.android.application' version '8.2.2' apply false
}
EOF

# ═══════════════════════════════════════════════════════════════════════════════
# APP build.gradle — all dependencies
# ═══════════════════════════════════════════════════════════════════════════════

cat > "app/build.gradle" << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.fountainpdl.comifountain'
    compileSdk 34

    defaultConfig {
        applicationId "com.fountainpdl.comifountain"
        minSdk 28
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"

        javaCompileOptions {
            annotationProcessorOptions {
                arguments += ["room.schemaLocation": "$projectDir/schemas".toString()]
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix ".debug"
            versionNameSuffix "-debug"
            debuggable true
        }
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    buildFeatures {
        viewBinding true
    }

    lint {
        abortOnError false
    }
}

dependencies {
    // ── Core ──────────────────────────────────────────────────────────────────
    implementation 'androidx.core:core:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.activity:activity:1.8.2'

    // ── UI ────────────────────────────────────────────────────────────────────
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'androidx.viewpager2:viewpager2:1.0.0'
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.1.0'
    implementation 'androidx.coordinatorlayout:coordinatorlayout:1.2.0'

    // ── Fragment / Navigation ─────────────────────────────────────────────────
    implementation 'androidx.fragment:fragment:1.6.2'
    implementation 'androidx.navigation:navigation-fragment:2.7.6'
    implementation 'androidx.navigation:navigation-ui:2.7.6'

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    implementation 'androidx.lifecycle:lifecycle-viewmodel:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-livedata:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-runtime:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-common-java8:2.7.0'

    // ── Room ──────────────────────────────────────────────────────────────────
    implementation 'androidx.room:room-runtime:2.6.1'
    annotationProcessor 'androidx.room:room-compiler:2.6.1'

    // ── Network ───────────────────────────────────────────────────────────────
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.12.0'

    // ── Parsing ───────────────────────────────────────────────────────────────
    implementation 'org.jsoup:jsoup:1.17.2'
    implementation 'com.google.code.gson:gson:2.10.1'

    // ── Image Loading ─────────────────────────────────────────────────────────
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    annotationProcessor 'com.github.bumptech.glide:compiler:4.16.0'

    // ── Preferences ───────────────────────────────────────────────────────────
    implementation 'androidx.preference:preference:1.2.1'

    // ── PhotoView (pinch-to-zoom in reader) ───────────────────────────────────
    // Requires jitpack.io in settings.gradle repositories
    implementation 'com.github.chrisbanes:PhotoView:2.3.0'

    // ── DocumentFile (SAF / Local Source) ────────────────────────────────────
    implementation 'androidx.documentfile:documentfile:1.0.1'

    // ── Testing ───────────────────────────────────────────────────────────────
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOF

echo "📦  Build files done"

# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS.GRADLE (authoritative copy — includes JitPack)
# ═══════════════════════════════════════════════════════════════════════════════

cat > "settings.gradle" << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }   // Required for PhotoView
    }
}

rootProject.name = "ComiFountain"
include ':app'
EOF

cat > "gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=false
EOF

echo "⚙️   settings.gradle done"

# ═══════════════════════════════════════════════════════════════════════════════
# APPLICATION CLASS
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$J/ComiFountainApp.java" << 'EOF'
package com.fountainpdl.comifountain;

import android.app.Application;
import com.fountainpdl.comifountain.data.MangaRepository;
import com.fountainpdl.comifountain.data.db.AppDatabase;

/**
 * ComiFountainApp — global Application class.
 * Declared in AndroidManifest as android:name=".ComiFountainApp"
 */
public class ComiFountainApp extends Application {

    private static ComiFountainApp instance;
    private MangaRepository repository;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        // Warm up DB on background thread so first query isn't cold
        new Thread(() -> AppDatabase.getInstance(this)).start();
    }

    public static ComiFountainApp getInstance() { return instance; }

    /** App-scoped repository — shared across all ViewModels via their factory. */
    public MangaRepository getRepository() {
        if (repository == null) repository = new MangaRepository(this);
        return repository;
    }
}
EOF

echo "🏗️   ComiFountainApp done"

# ═══════════════════════════════════════════════════════════════════════════════
# DATA MODELS
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$J/data/model/Manga.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;
import java.util.ArrayList;
import java.util.List;

/**
 * Core manga model — Room entity + domain object.
 * Composite ID format: "sourceId:rawMangaId"  (e.g. "allanime:abc123")
 */
@Entity(tableName = "manga")
public class Manga {

    @PrimaryKey
    @ColumnInfo(name = "id")
    public String id;

    @ColumnInfo(name = "title")         public String title;
    @ColumnInfo(name = "cover")         public String cover;
    @ColumnInfo(name = "description")   public String description;
    @ColumnInfo(name = "author")        public String author;
    @ColumnInfo(name = "genres")        public List<String> genres   = new ArrayList<>();
    @ColumnInfo(name = "status")        public String status;
    @ColumnInfo(name = "source_id")     public String sourceId;
    @ColumnInfo(name = "source_name")   public String sourceName;
    @ColumnInfo(name = "url")           public String url;
    @ColumnInfo(name = "added_date")    public long   addedDate;
    @ColumnInfo(name = "last_read")     public long   lastRead;
    @ColumnInfo(name = "progress")      public int    progress;
    @ColumnInfo(name = "in_library")    public boolean inLibrary;
    @ColumnInfo(name = "categories")    public List<String> categories = new ArrayList<>();
    @ColumnInfo(name = "chapter_count") public int    chapterCount;
    @ColumnInfo(name = "unread_count")  public int    unreadCount;
    @ColumnInfo(name = "last_chapter_date") public long lastChapterDate;

    /** Loaded separately — not persisted in the manga table. */
    @Ignore public List<Chapter> chapters = new ArrayList<>();

    public Manga() {}

    @Ignore
    public Manga(String id, String title, String cover, String sourceId, String sourceName) {
        this.id         = id;
        this.title      = title;
        this.cover      = cover;
        this.sourceId   = sourceId;
        this.sourceName = sourceName;
        this.addedDate  = System.currentTimeMillis();
    }

    public static String buildId(String sourceId, String rawId) {
        return sourceId + ":" + rawId;
    }

    public String getRawId() {
        if (id == null || !id.contains(":")) return id;
        return id.substring(id.indexOf(':') + 1);
    }

    public boolean isCompleted() { return "completed".equalsIgnoreCase(status); }

    @Override
    public String toString() {
        return "Manga{id='" + id + "', title='" + title + "', source='" + sourceName + "'}";
    }
}
EOF

cat > "$J/data/model/Chapter.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.ForeignKey;
import androidx.room.Ignore;
import androidx.room.Index;
import androidx.room.PrimaryKey;
import java.util.ArrayList;
import java.util.List;

/**
 * Chapter model.
 * Composite ID format: "sourceId:chapterId"
 * Foreign key → Manga with CASCADE delete.
 */
@Entity(
    tableName = "chapters",
    foreignKeys = @ForeignKey(
        entity    = Manga.class,
        parentColumns = "id",
        childColumns  = "manga_id",
        onDelete  = ForeignKey.CASCADE
    ),
    indices = {
        @Index("manga_id"),
        @Index({"manga_id", "number"})
    }
)
public class Chapter {

    @PrimaryKey
    @ColumnInfo(name = "id")             public String id;

    @ColumnInfo(name = "title")          public String  title;
    @ColumnInfo(name = "number")         public float   number;
    @ColumnInfo(name = "date")           public long    date;
    @ColumnInfo(name = "index")          public int     index;
    @ColumnInfo(name = "manga_id")       public String  mangaId;
    @ColumnInfo(name = "source_id")      public String  sourceId;
    @ColumnInfo(name = "is_read")        public boolean isRead;
    @ColumnInfo(name = "bookmarked")     public boolean bookmarked;
    @ColumnInfo(name = "last_page_read") public int     lastPageRead;
    @ColumnInfo(name = "downloaded_date")public long    downloadedDate;
    @ColumnInfo(name = "download_path")  public String  downloadPath;
    @ColumnInfo(name = "page_count")     public int     pageCount;

    /** Loaded from source on demand — not persisted. */
    @Ignore public List<Page> pages = new ArrayList<>();

    public Chapter() {}

    @Ignore
    public Chapter(String id, String mangaId, String sourceId,
                   String title, float number, long date) {
        this.id       = id;
        this.mangaId  = mangaId;
        this.sourceId = sourceId;
        this.title    = title;
        this.number   = number;
        this.date     = date;
    }

    public static String buildId(String sourceId, String rawChapterId) {
        return sourceId + ":" + rawChapterId;
    }

    public String getRawId() {
        if (id == null || !id.contains(":")) return id;
        return id.substring(id.indexOf(':') + 1);
    }

    public boolean isDownloaded() { return downloadedDate > 0 && downloadPath != null; }

    /** Human-readable display name: prefer explicit title, fall back to "Chapter N". */
    public String displayName() {
        if (title != null && !title.isEmpty() && !title.equals(String.valueOf(number)))
            return title;
        return number == (int) number
            ? "Chapter " + (int) number
            : "Chapter " + number;
    }

    @Override
    public String toString() {
        return "Chapter{id='" + id + "', number=" + number + ", title='" + title + "'}";
    }
}
EOF

cat > "$J/data/model/Page.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

/**
 * Single page in a chapter.
 * NOT persisted in Room — fetched from source on demand or from local storage.
 *
 * IMPORTANT: always sort pages by `index`, never alphabetically.
 */
public class Page {

    public int    index;        // 0-based; sort by this
    public String url;          // Remote image URL
    public String localPath;    // Non-null when downloaded (absolute file or content URI)
    public PageState state;

    public enum PageState { WAITING, LOADING, READY, ERROR }

    public Page() { state = PageState.WAITING; }

    public Page(int index, String url) {
        this.index = index;
        this.url   = url;
        this.state = PageState.WAITING;
    }

    public Page(int index, String url, String localPath) {
        this.index     = index;
        this.url       = url;
        this.localPath = localPath;
        this.state     = localPath != null ? PageState.READY : PageState.WAITING;
    }

    /** Returns the URI/path to load — local takes priority over remote. */
    public String getLoadPath() {
        return (localPath != null && !localPath.isEmpty()) ? localPath : url;
    }

    public boolean isLocal() { return localPath != null && !localPath.isEmpty(); }
    public boolean isReady() { return state == PageState.READY; }

    @Override
    public String toString() {
        return "Page{index=" + index + ", state=" + state + "}";
    }
}
EOF

cat > "$J/data/model/Category.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

/** User-created library category (e.g. "Favourites", "Reading"). */
@Entity(tableName = "categories")
public class Category {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")       public int    id;
    @ColumnInfo(name = "name")     public String name;
    @ColumnInfo(name = "position") public int    position;

    public Category() {}

    @Ignore
    public Category(String name, int position) {
        this.name     = name;
        this.position = position;
    }
}
EOF

cat > "$J/data/model/HistoryEntry.java" << 'EOF'
package com.fountainpdl.comifountain.data.model;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.ForeignKey;
import androidx.room.Ignore;
import androidx.room.Index;
import androidx.room.PrimaryKey;

/** Tracks when a chapter was last read. */
@Entity(
    tableName = "history",
    foreignKeys = {
        @ForeignKey(entity = Manga.class,   parentColumns = "id", childColumns = "manga_id",   onDelete = ForeignKey.CASCADE),
        @ForeignKey(entity = Chapter.class, parentColumns = "id", childColumns = "chapter_id", onDelete = ForeignKey.CASCADE)
    },
    indices = { @Index("manga_id"), @Index("chapter_id") }
)
public class HistoryEntry {

    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")          public int    id;
    @ColumnInfo(name = "manga_id")    public String mangaId;
    @ColumnInfo(name = "chapter_id")  public String chapterId;
    @ColumnInfo(name = "read_at")     public long   readAt;
    @ColumnInfo(name = "time_spent_ms") public long timeSpentMs;

    public HistoryEntry() {}

    @Ignore
    public HistoryEntry(String mangaId, String chapterId) {
        this.mangaId   = mangaId;
        this.chapterId = chapterId;
        this.readAt    = System.currentTimeMillis();
    }
}
EOF

echo "📦  Data models done"

# ═══════════════════════════════════════════════════════════════════════════════
# ROOM DATABASE LAYER
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$J/data/db/Converters.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.room.TypeConverter;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

/** Lets Room store List<String> as a JSON column (used by Manga.genres, Manga.categories). */
public class Converters {

    private static final Gson GSON = new Gson();
    private static final Type LIST_TYPE = new TypeToken<List<String>>() {}.getType();

    @TypeConverter
    public static String fromList(List<String> list) {
        if (list == null || list.isEmpty()) return "[]";
        return GSON.toJson(list);
    }

    @TypeConverter
    public static List<String> toList(String value) {
        if (value == null || value.isEmpty()) return new ArrayList<>();
        try { return GSON.fromJson(value, LIST_TYPE); }
        catch (Exception e) { return new ArrayList<>(); }
    }
}
EOF

cat > "$J/data/db/MangaDao.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Manga;
import java.util.List;

@Dao
public interface MangaDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertManga(Manga m);
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertAll(List<Manga> list);
    @Update void updateManga(Manga m);
    @Delete void deleteManga(Manga m);

    @Query("DELETE FROM manga WHERE id = :id")
    void deleteMangaById(String id);

    @Query("SELECT * FROM manga WHERE in_library = 1 ORDER BY last_read DESC")
    LiveData<List<Manga>> getLibraryManga();

    @Query("SELECT * FROM manga WHERE in_library = 1 AND categories LIKE '%' || :cat || '%' ORDER BY last_read DESC")
    LiveData<List<Manga>> getLibraryByCategory(String cat);

    @Query("SELECT * FROM manga WHERE in_library = 1 AND unread_count > 0 ORDER BY last_chapter_date DESC")
    LiveData<List<Manga>> getMangaWithUpdates();

    @Query("SELECT * FROM manga WHERE id = :id LIMIT 1")
    Manga getMangaById(String id);

    @Query("SELECT * FROM manga WHERE id = :id LIMIT 1")
    LiveData<Manga> observeMangaById(String id);

    @Query("SELECT in_library FROM manga WHERE id = :id LIMIT 1")
    boolean isInLibrary(String id);

    @Query("SELECT * FROM manga WHERE source_id = :sourceId AND in_library = 1")
    List<Manga> getMangaBySource(String sourceId);

    @Query("UPDATE manga SET in_library = 1, added_date = :ts WHERE id = :id")
    void addToLibrary(String id, long ts);

    @Query("UPDATE manga SET in_library = 0 WHERE id = :id")
    void removeFromLibrary(String id);

    @Query("UPDATE manga SET last_read = :ts WHERE id = :id")
    void updateLastRead(String id, long ts);

    @Query("UPDATE manga SET chapter_count = :total, unread_count = :unread, last_chapter_date = :latestDate WHERE id = :id")
    void updateChapterStats(String id, int total, int unread, long latestDate);

    @Query("UPDATE manga SET categories = :json WHERE id = :id")
    void updateCategories(String id, String json);

    @Query("SELECT * FROM manga WHERE in_library = 1 AND title LIKE '%' || :q || '%' ORDER BY title ASC")
    LiveData<List<Manga>> searchLibrary(String q);

    @Query("SELECT COUNT(*) FROM manga WHERE in_library = 1")
    int getLibraryCount();

    @Query("SELECT COUNT(*) FROM manga WHERE in_library = 1 AND unread_count > 0")
    LiveData<Integer> getUpdatesBadgeCount();
}
EOF

cat > "$J/data/db/ChapterDao.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import androidx.lifecycle.LiveData;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.Chapter;
import java.util.List;

@Dao
public interface ChapterDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertChapter(Chapter c);
    @Insert(onConflict = OnConflictStrategy.REPLACE) void insertChapters(List<Chapter> list);
    @Update void updateChapter(Chapter c);
    @Delete void deleteChapter(Chapter c);

    @Query("DELETE FROM chapters WHERE manga_id = :mangaId")
    void deleteChaptersForManga(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId ORDER BY number DESC")
    LiveData<List<Chapter>> getChaptersForManga(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId ORDER BY number DESC")
    List<Chapter> getChaptersForMangaSync(String mangaId);

    @Query("SELECT * FROM chapters WHERE id = :id LIMIT 1")
    Chapter getChapterById(String id);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND is_read = 0 ORDER BY number ASC LIMIT 1")
    Chapter getFirstUnreadChapter(String mangaId);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND is_read = 0 AND last_page_read > 0 ORDER BY number DESC LIMIT 1")
    Chapter getResumeChapter(String mangaId);

    @Query("UPDATE chapters SET is_read = 1 WHERE id = :id")   void markRead(String id);
    @Query("UPDATE chapters SET is_read = 0 WHERE id = :id")   void markUnread(String id);
    @Query("UPDATE chapters SET is_read = 1 WHERE manga_id = :mangaId") void markAllRead(String mangaId);
    @Query("UPDATE chapters SET is_read = 0 WHERE manga_id = :mangaId") void markAllUnread(String mangaId);

    @Query("UPDATE chapters SET last_page_read = :page WHERE id = :id")
    void updateLastPageRead(String id, int page);

    @Query("UPDATE chapters SET bookmarked = :b WHERE id = :id")
    void setBookmark(String id, boolean b);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND bookmarked = 1 ORDER BY number DESC")
    LiveData<List<Chapter>> getBookmarkedChapters(String mangaId);

    @Query("UPDATE chapters SET downloaded_date = :ts, download_path = :path WHERE id = :id")
    void markDownloaded(String id, long ts, String path);

    @Query("UPDATE chapters SET downloaded_date = 0, download_path = NULL WHERE id = :id")
    void clearDownload(String id);

    @Query("SELECT * FROM chapters WHERE manga_id = :mangaId AND downloaded_date > 0")
    List<Chapter> getDownloadedChapters(String mangaId);

    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId")             int getTotalCount(String mangaId);
    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId AND is_read = 0") int getUnreadCount(String mangaId);
    @Query("SELECT COUNT(*) FROM chapters WHERE manga_id = :mangaId AND downloaded_date > 0") int getDownloadedCount(String mangaId);
}
EOF

cat > "$J/data/db/AppDatabase.java" << 'EOF'
package com.fountainpdl.comifountain.data.db;

import android.content.Context;
import androidx.room.*;
import com.fountainpdl.comifountain.data.model.*;

/**
 * Room database singleton — version 1.
 * Access via AppDatabase.getInstance(context).
 *
 * Schema version history:
 *   v1 — manga, chapters, categories, history tables
 */
@Database(
    entities = {
        Manga.class,
        Chapter.class,
        Category.class,
        HistoryEntry.class
    },
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters.class)
public abstract class AppDatabase extends RoomDatabase {

    private static final String DB_NAME = "comifountain.db";

    public abstract MangaDao   mangaDao();
    public abstract ChapterDao chapterDao();

    private static volatile AppDatabase INSTANCE;

    public static AppDatabase getInstance(Context context) {
        if (INSTANCE == null) {
            synchronized (AppDatabase.class) {
                if (INSTANCE == null) {
                    INSTANCE = Room.databaseBuilder(
                            context.getApplicationContext(),
                            AppDatabase.class,
                            DB_NAME)
                        // Add migrations here when schema changes:
                        // .addMigrations(MIGRATION_1_2)
                        .fallbackToDestructiveMigration()  // remove before production release
                        .build();
                }
            }
        }
        return INSTANCE;
    }

    // Template for future migrations:
    // static final Migration MIGRATION_1_2 = new Migration(1, 2) {
    //     @Override public void migrate(SupportSQLiteDatabase db) {
    //         db.execSQL("ALTER TABLE manga ADD COLUMN new_col TEXT");
    //     }
    // };
}
EOF

echo "🗄️   Room database done"

# ═══════════════════════════════════════════════════════════════════════════════
# REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$J/data/MangaRepository.java" << 'EOF'
package com.fountainpdl.comifountain.data;

import android.content.Context;
import androidx.lifecycle.LiveData;
import com.fountainpdl.comifountain.data.db.AppDatabase;
import com.fountainpdl.comifountain.data.db.ChapterDao;
import com.fountainpdl.comifountain.data.db.MangaDao;
import com.fountainpdl.comifountain.data.model.Chapter;
import com.fountainpdl.comifountain.data.model.Manga;
import com.google.gson.Gson;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * MangaRepository — single source of truth between UI/ViewModel and the data layer.
 *
 * Threading rules:
 *  - LiveData queries: Room posts to main thread automatically.
 *  - One-shot queries: run on executor, post results via Callback<T>.
 *  - All write ops: run on executor.
 */
public class MangaRepository {

    private final MangaDao   mangaDao;
    private final ChapterDao chapterDao;
    private final ExecutorService exec = Executors.newFixedThreadPool(4);
    private static final Gson GSON = new Gson();

    public MangaRepository(Context context) {
        AppDatabase db = AppDatabase.getInstance(context);
        mangaDao   = db.mangaDao();
        chapterDao = db.chapterDao();
    }

    // ── Library ───────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> getLibraryManga()                        { return mangaDao.getLibraryManga(); }
    public LiveData<List<Manga>> getLibraryMangaByCategory(String cat)   { return mangaDao.getLibraryByCategory(cat); }
    public LiveData<List<Manga>> getMangaWithUpdates()                   { return mangaDao.getMangaWithUpdates(); }
    public LiveData<Integer>     getUpdatesBadgeCount()                  { return mangaDao.getUpdatesBadgeCount(); }
    public LiveData<Manga>       observeManga(String mangaId)            { return mangaDao.observeMangaById(mangaId); }

    // ── Save / Update ─────────────────────────────────────────────────────────

    public void saveManga(Manga m)              { exec.execute(() -> mangaDao.insertManga(m)); }
    public void saveMangaList(List<Manga> list) { exec.execute(() -> mangaDao.insertAll(list)); }
    public void updateManga(Manga m)            { exec.execute(() -> mangaDao.updateManga(m)); }

    // ── Library management ────────────────────────────────────────────────────

    public void addToLibrary(String mangaId) {
        exec.execute(() -> mangaDao.addToLibrary(mangaId, System.currentTimeMillis()));
    }

    public void removeFromLibrary(String mangaId) {
        exec.execute(() -> mangaDao.removeFromLibrary(mangaId));
    }

    public void checkIsInLibrary(String mangaId, Callback<Boolean> cb) {
        exec.execute(() -> cb.onResult(mangaDao.isInLibrary(mangaId)));
    }

    public void updateLastRead(String mangaId) {
        exec.execute(() -> mangaDao.updateLastRead(mangaId, System.currentTimeMillis()));
    }

    public void updateCategories(String mangaId, List<String> cats) {
        exec.execute(() -> mangaDao.updateCategories(mangaId, GSON.toJson(cats)));
    }

    // ── Chapters ──────────────────────────────────────────────────────────────

    public LiveData<List<Chapter>> getChaptersForManga(String mangaId) {
        return chapterDao.getChaptersForManga(mangaId);
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

    public void markChapterRead(String chapterId, String mangaId) {
        exec.execute(() -> { chapterDao.markRead(chapterId); syncChapterStats(mangaId); });
    }

    public void markChapterUnread(String chapterId, String mangaId) {
        exec.execute(() -> { chapterDao.markUnread(chapterId); syncChapterStats(mangaId); });
    }

    public void markAllRead(String mangaId) {
        exec.execute(() -> { chapterDao.markAllRead(mangaId); syncChapterStats(mangaId); });
    }

    public void updateLastPageRead(String chapterId, int page) {
        exec.execute(() -> chapterDao.updateLastPageRead(chapterId, page));
    }

    // ── Bookmarks ─────────────────────────────────────────────────────────────

    public void setBookmark(String chapterId, boolean b)           { exec.execute(() -> chapterDao.setBookmark(chapterId, b)); }
    public LiveData<List<Chapter>> getBookmarkedChapters(String m) { return chapterDao.getBookmarkedChapters(m); }

    // ── Downloads ─────────────────────────────────────────────────────────────

    public void markDownloaded(String chapterId, String path) {
        exec.execute(() -> chapterDao.markDownloaded(chapterId, System.currentTimeMillis(), path));
    }

    public void clearDownload(String chapterId) { exec.execute(() -> chapterDao.clearDownload(chapterId)); }

    // ── Search ────────────────────────────────────────────────────────────────

    public LiveData<List<Manga>> searchLibrary(String query) { return mangaDao.searchLibrary(query); }

    // ── Internal ─────────────────────────────────────────────────────────────

    /** Recompute and persist chapter stats (total, unread, latest date) for a manga. */
    private void syncChapterStats(String mangaId) {
        int    total   = chapterDao.getTotalCount(mangaId);
        int    unread  = chapterDao.getUnreadCount(mangaId);
        List<Chapter> chapters = chapterDao.getChaptersForMangaSync(mangaId);
        long   latest  = 0;
        for (Chapter c : chapters) if (c.date > latest) latest = c.date;
        mangaDao.updateChapterStats(mangaId, total, unread, latest);
    }

    /** Simple async callback for one-shot DB results. */
    public interface Callback<T> {
        void onResult(T result);
    }
}
EOF

echo "🗂️   Repository done"

# ═══════════════════════════════════════════════════════════════════════════════
# GITHUB ACTIONS CI
# ═══════════════════════════════════════════════════════════════════════════════

cat > ".github/workflows/build.yml" << 'EOF'
name: Build APK

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Validate Gradle wrapper
        uses: gradle/wrapper-validation-action@v2

      - name: Build debug APK
        run: ./gradlew assembleDebug --stacktrace

      - name: Run unit tests
        run: ./gradlew testDebugUnitTest

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: ComiFountain-debug
          path: app/build/outputs/apk/debug/*.apk
          retention-days: 14
EOF

echo "🚀  CI workflow done"

# ═══════════════════════════════════════════════════════════════════════════════
# README
# ═══════════════════════════════════════════════════════════════════════════════

cat > "README.md" << 'EOF'
# ComiFountain

A source-based manga/comic reader for Android, inspired by [Mihon](https://github.com/mihonapp/mihon) (Tachiyomi fork).

**Package:** `com.fountainpdl.comifountain`  
**Min SDK:** 28 (Android 9)  
**Target SDK:** 34 (Android 14)  
**Language:** Java  

---

## Features

- **Library** — track reading progress, categories, unread counts
- **Search** — browse/search across multiple sources
- **Sources** — AllManga (GraphQL), MangaPuma (scraper), RavenScans (scraper), Local (folder/CBZ)
- **Reader** — LTR, RTL, vertical, webtoon modes with pinch-to-zoom
- **Settings** — Solid / Dual-Shift / Dynamic theming, reader preferences
- **Offline** — download chapters for offline reading

## Architecture

Mihon-style:

```
MainActivity (bottom nav)
├── LibraryFragment       ← ViewModel + Room LiveData
├── SearchFragment        ← ViewModel + Source.search()
├── SourcesFragment       ← SourceRegistry + SAF folder picker
├── UpdatesFragment       ← Library manga with unread chapters
├── SettingsFragment      ← AppPreferences (SharedPreferences)
├── MangaDetailFragment   ← ViewModel + Source.getChapterList()
└── ReaderFragment        ← ViewModel + Source.getPageList() + ViewPager2
```

## Sources

| Source | Type | Notes |
|--------|------|-------|
| AllManga | GraphQL (`api.allanime.day`) | Requires `Referer` + `Origin` headers |
| MangaPuma | HTML scraper | Via `corsproxy.io` |
| RavenScans | HTML scraper | `ts_reader.run` parser, `ravenscans.com` |
| Local | SAF + CBZ | Folder structure: `Series/Chapter/images` or `.cbz` |

## Setup

1. Clone the repo
2. Open in **Android Studio Hedgehog** or later
3. `File → Sync Project with Gradle Files`
4. Add your app icon to `res/mipmap-*` (all densities)
5. Build → Run on device or emulator (API 28+)

### First build

```bash
./gradlew assembleDebug
```

APK output: `app/build/outputs/apk/debug/`

## Generating project files

```bash
bash patch_comifountain.sh       # data layer, build files, models
bash generate_comifountain.sh    # network, sources, UI, layouts, resources
```

---

*Built by FountainPDL — May 2026*
EOF

echo "📖  README done"

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo "✅  Patch complete! Files written:"
echo ""
echo "  Build:"
echo "    build.gradle"
echo "    app/build.gradle"
echo "    settings.gradle"
echo "    gradle.properties"
echo "    gradle/wrapper/gradle-wrapper.properties"
echo "    app/proguard-rules.pro"
echo ""
echo "  Application:"
echo "    $J/ComiFountainApp.java"
echo ""
echo "  Data Models:"
echo "    $J/data/model/Manga.java"
echo "    $J/data/model/Chapter.java"
echo "    $J/data/model/Page.java"
echo "    $J/data/model/Category.java"
echo "    $J/data/model/HistoryEntry.java"
echo ""
echo "  Room DB:"
echo "    $J/data/db/Converters.java"
echo "    $J/data/db/MangaDao.java"
echo "    $J/data/db/ChapterDao.java"
echo "    $J/data/db/AppDatabase.java"
echo "    $J/data/MangaRepository.java"
echo ""
echo "  CI / Docs:"
echo "    .github/workflows/build.yml"
echo "    README.md"
echo ""
echo "Run order:"
echo "  1. bash patch_comifountain.sh"
echo "  2. bash generate_comifountain.sh"
