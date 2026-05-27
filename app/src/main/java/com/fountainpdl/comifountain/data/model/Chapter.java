package com.fountainpdl.comifountain.data.model;
import androidx.annotation.NonNull;
import androidx.annotation.NonNull;

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
    @PrimaryKey
    @NonNull
    @ColumnInfo(name = "id")             public String id = "";

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
