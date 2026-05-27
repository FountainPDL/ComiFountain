import androidx.annotation.NonNull;
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
    @NonNull
    @ColumnInfo(name = "id")
    public String id = "";

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
